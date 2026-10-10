import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../game/ai.dart';
import '../game/cowrie_dice.dart';
import '../game/game_state.dart';
import '../game/move.dart';
import '../game/pachisi_rules.dart';
import '../models/meta.dart';
import '../services/audio_service.dart';
import '../services/storage.dart';

/// Seat configuration: which players are in the match and who controls them.
class MatchConfig {
  final GameMode mode;
  final List<int> seats; // player ids in turn order
  final Map<int, AiDifficulty?> controllers; // player id -> null (human) or AI
  final int ladderRung; // tournament only
  final RulesConfig rules;

  const MatchConfig({
    required this.mode,
    required this.seats,
    required this.controllers,
    this.ladderRung = 0,
    this.rules = RulesConfig.classic,
  });

  bool isAi(int player) => controllers[player] != null;

  AiDifficulty? hardestAi() {
    AiDifficulty? best;
    for (final d in controllers.values) {
      if (d == null) continue;
      if (best == null || d.index > best.index) best = d;
    }
    return best;
  }

  int get aiCount => controllers.values.where((d) => d != null).length;
}

/// Drives a full Pachisi match: turns, dice, moves, captures, extra turns,
/// blitz clock, AI thinking, win detection and stat reporting.
class GameController extends ChangeNotifier {
  final AppState app;
  final MatchConfig config;
  final CowrieDice dice;
  final PachisiAi ai;

  PachisiState state;
  int seatIndex = 0;

  int d1 = 6, d2 = 6;
  bool hasRolled = false;
  bool rolling = false;
  List<PachisiMove> moves = [];
  String statusMessage = '';
  bool gameOver = false;
  int? winner;

  // Blitz
  Timer? _blitzTimer;
  int blitzSecondsLeft = 300;
  static const int blitzDuration = 300;

  // Match stats for achievements/coins
  int humanCaptures = 0;
  int humanRolls = 0;
  int humanBlockades = 0;
  int turnCount = 0;
  int extraTurnChain = 0;
  int sixStreak = 0;
  int safeHavenTurns = 0;
  bool humanLostPiece = false;
  bool humanCapturedAnyone = false;
  final Set<int> overshootAttempts = {};
  bool allCapturedComebackArmed = false;
  final Set<int> piecesCapturedOnce = {};

  bool _disposed = false;

  GameController({
    required this.app,
    required this.config,
    Random? random,
  })  : dice = CowrieDice(random: random),
        ai = PachisiAi(random: random),
        state = PachisiState.initial(
          rules: config.rules,
        ) {
    statusMessage = '${_playerName(currentPlayer)} to move — tap the dice!';
    if (config.mode == GameMode.timedBlitz) {
      _blitzTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickBlitz());
    }
    // Kick off AI first turn if needed.
    Future.microtask(_maybeAiTurn);
  }

  int get currentPlayer => config.seats[seatIndex];
  bool get currentIsAi => config.isAi(currentPlayer);
  bool get isHumanTurn => !currentIsAi && !gameOver;

  String _playerName(int p) {
    if (!currentIsAiFor(p) && p == config.seats.first && config.controllers[p] == null) {
      return app.playerName;
    }
    return _aiName(p);
  }

  bool currentIsAiFor(int p) => config.isAi(p);

  String _aiName(int p) {
    final d = config.controllers[p];
    const names = ['Raja Vikram', 'Rani Meera', 'Nawab Sahib'];
    final idx = config.seats.indexOf(p) % names.length;
    return '${names[idx]} (${d?.label ?? ''})';
  }

  String get turnLabel {
    if (gameOver) return 'Match over';
    if (currentIsAi) return '${_aiName(currentPlayer)} is thinking…';
    return '${_playerName(currentPlayer)} — ${hasRolled ? 'choose a glowing piece' : 'tap the dice!'}';
  }

  // -- Turn flow ---------------------------------------------------------------

  Future<void> _maybeAiTurn() async {
    if (_disposed || gameOver || !currentIsAi) return;
    await Future.delayed(Duration(milliseconds: app.reduceMotion ? 200 : 700));
    if (_disposed || gameOver || !currentIsAi) return;
    await rollDice();
  }

  Future<void> rollDice() async {
    if (gameOver || hasRolled || rolling) return;
    if (currentIsAi == false && !isHumanTurn) return;
    rolling = true;
    notifyListeners();
    await AudioService().diceRoll();
    if (!app.reduceMotion) {
      await Future.delayed(const Duration(milliseconds: 450));
    }
    final r = dice.roll();
    d1 = r.$1;
    d2 = r.$2;
    rolling = false;
    hasRolled = true;

    final isDoubles = d1 == d2;
    if (d1 == 6 || d2 == 6) {
      sixStreak++;
      if (sixStreak >= 3) app.progress('six_streak', 1);
    } else {
      sixStreak = 0;
    }
    if (d1 == 6 && d2 == 6) app.progress('double_six', 1);

    if (isDoubles) {
      final next = state.consecutiveDoubles + 1;
      if (next >= state.rules.doublesForfeit) {
        state = state.copyWith(consecutiveDoubles: 0);
        statusMessage = 'Three doubles in a row — turn forfeited!';
        app.progress('doubles_forfeit', 1);
        await AudioService().error();
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 900));
        _nextTurn();
        return;
      }
      state = state.copyWith(consecutiveDoubles: next);
    } else {
      state = state.copyWith(consecutiveDoubles: 0);
    }

    if (!currentIsAi) {
      humanRolls++;
      app.totalRolls++;
      app.progress('rolls_1000', app.totalRolls);
    }
    app.progress('first_roll', 1);

    moves = legalMoves(state, currentPlayer, d1, d2);
    if (moves.isEmpty) {
      statusMessage = 'No moves possible (${d1 + d2}) — turn passes.';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 1100));
      if (!_disposed) _nextTurn();
      return;
    }
    statusMessage = '${_playerName(currentPlayer)} rolled ${d1 + d2}.';
    notifyListeners();

    if (currentIsAi) {
      await Future.delayed(Duration(milliseconds: app.reduceMotion ? 150 : 600));
      if (_disposed || gameOver) return;
      final diff = config.controllers[currentPlayer]!;
      // AI is strictly time-capped, so it runs inline without jank.
      final choice = ai.choose(state, currentPlayer, moves, diff);
      if (_disposed || gameOver) return;
      await playMove(choice!);
    }
  }

  Future<void> playMove(PachisiMove move) async {
    if (gameOver) return;
    final wasEnter = move.isEnter;
    final wasCapture = move.isCapture;
    final wasHome = move.reachesHome;

    // Track blockade formation for achievements.
    final beforeStacks = _stackCount(state, move.player);

    state = applyMove(state, move);
    turnCount++;

    final afterStacks = _stackCount(state, move.player);
    if (afterStacks > beforeStacks) {
      if (!currentIsAi) {
        humanBlockades++;
        app.totalBlockades++;
        app.progress('blockades_25', app.totalBlockades);
      }
      app.progress('first_blockade', 1);
    }

    if (wasEnter) {
      await AudioService().enterBoard();
      app.progress('first_entry', 1);
    } else {
      await AudioService().pieceMove();
    }
    if (wasCapture) {
      await AudioService().capture();
      if (!currentIsAi) {
        humanCaptures += move.captured.length;
        humanCapturedAnyone = true;
        app.totalCaptures += move.captured.length;
        app.progress('captures_10', app.totalCaptures);
        app.progress('captures_100', app.totalCaptures);
        app.progress('first_capture', 1);
        if (humanCaptures >= 3) app.progress('capture_3_match', 1);
        app.addCoins(5 * move.captured.length);
      } else {
        // AI captured the human's piece?
        for (final c in move.captured) {
          if (!config.isAi(c.player)) {
            humanLostPiece = true;
            piecesCapturedOnce.add(c.piece + c.player * 10);
          }
        }
      }
      HapticFeedback.mediumImpact();
    }
    if (wasHome) {
      await AudioService().homeReach();
      app.progress('first_home', 1);
      if (!currentIsAi) app.addCoins(10);
    }

    // Safe-haven tracking (one piece parked 10 turns).
    _trackSafeHaven();

    moves = [];
    hasRolled = false;

    if (state.playerFinished(currentPlayer)) {
      _finish(currentPlayer);
      return;
    }

    // Extra turn? six on a die, doubles, capture, or piece homed.
    final extra = (d1 == 6 || d2 == 6) || d1 == d2 || wasCapture || wasHome;
    if (extra) {
      extraTurnChain++;
      if (extraTurnChain >= 4) app.progress('extra_turn_chain', 1);
      statusMessage = '${_playerName(currentPlayer)} earned another turn!';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 700));
      if (!_disposed && !gameOver) {
        hasRolled = false;
        if (currentIsAi) {
          _maybeAiTurn();
        } else {
          statusMessage = '${_playerName(currentPlayer)} — roll again!';
          notifyListeners();
        }
      }
      return;
    }
    extraTurnChain = 0;
    _nextTurn();
  }

  int _stackCount(PachisiState s, int player) {
    var n = 0;
    final seen = <int>{};
    for (var i = 0; i < 4; i++) {
      final step = s.steps[player][i];
      if (step < 0 || step > 50) continue;
      final ring = s.ringPos(player, step);
      if (seen.add(ring) && s.piecesOnRing(player, ring).length >= 2) n++;
    }
    return n;
  }

  void _trackSafeHaven() {
    // Simplified: count consecutive turns where current human piece sits safe.
    safeHavenTurns++;
    if (safeHavenTurns >= 10) app.progress('safe_haven', 1);
  }

  void _nextTurn() {
    if (gameOver || _disposed) return;
    seatIndex = (seatIndex + 1) % config.seats.length;
    state = state.copyWith(turnNumber: state.turnNumber + 1);
    hasRolled = false;
    moves = [];
    d1 = 6;
    d2 = 6;
    statusMessage = '${_playerName(currentPlayer)} to move — tap the dice!';
    notifyListeners();
    _maybeAiTurn();
  }

  void _tickBlitz() {
    if (gameOver || _disposed) return;
    blitzSecondsLeft--;
    if (blitzSecondsLeft <= 0) {
      _finishBlitz();
    }
    notifyListeners();
  }

  int _progressScore(int player) {
    var s = 0;
    for (final step in state.steps[player]) {
      s += step.clamp(-1, 57) + 1; // base counts 0
    }
    return s;
  }

  void _finishBlitz() {
    var best = config.seats.first;
    var bestScore = -1;
    for (final p in config.seats) {
      final sc = _progressScore(p) + state.homeCount(p) * 50;
      if (sc > bestScore) {
        bestScore = sc;
        best = p;
      }
    }
    _finish(best, blitz: true);
  }

  Future<void> _finish(int winPlayer, {bool blitz = false}) async {
    gameOver = true;
    winner = winPlayer;
    _blitzTimer?.cancel();
    final statsWon = config.mode == GameMode.passAndPlay
        ? winPlayer == config.seats.first
        : !config.isAi(winPlayer);

    if (statsWon) {
      await AudioService().win();
    } else {
      await AudioService().lose();
    }

    final piecesHome = state.homeCount(config.seats.first);
    app.reportMatch(
      mode: config.mode,
      won: statsWon,
      captures: humanCaptures,
      rolls: humanRolls,
      blockades: humanBlockades,
      piecesHome: piecesHome,
      aiOpponents: config.aiCount,
      hardestAi: config.hardestAi(),
      turnCount: turnCount,
      lostAnyPiece: humanLostPiece,
      capturedAnyone: humanCapturedAnyone,
      usedNonDefaultTheme: app.themeId != 'maharaja',
    );
    if (config.mode == GameMode.tournament && statsWon) {
      app.reportTournamentWin(config.ladderRung);
    }
    if (config.rules == RulesConfig.kids || app.kidsMode) {
      app.progress('kids_play', 1);
    }
    statusMessage = blitz
        ? 'Time! ${_playerName(winPlayer)} leads the court!'
        : '${_playerName(winPlayer)} wins the royal court! 👑';
    notifyListeners();
  }

  /// Human taps a piece: apply its legal move if one exists.
  Future<void> tapPiece(int player, int piece) async {
    if (!isHumanTurn || !hasRolled || gameOver || rolling) return;
    if (player != currentPlayer) return;
    final move = moves.where((m) => m.piece == piece).firstOrNull;
    if (move == null) {
      await AudioService().error();
      return;
    }
    await playMove(move);
  }

  /// Forfeit / resign the match (counts as a loss for stats if human was playing).
  void resign() {
    if (gameOver) return;
    // Winner: next AI seat, or first AI.
    final aiSeat = config.seats.firstWhere((p) => config.isAi(p),
        orElse: () => config.seats[(seatIndex + 1) % config.seats.length]);
    _finish(aiSeat);
  }

  @override
  void dispose() {
    _disposed = true;
    _blitzTimer?.cancel();
    super.dispose();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
