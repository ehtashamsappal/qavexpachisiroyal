import 'move.dart';
import 'pachisi_rules.dart';

/// Immutable snapshot of a Pachisi match.
///
/// `steps[player][piece]` holds each piece's journey position:
/// -1 = base, 0..50 = ring, 51..56 = home stretch, 57 = home.
class PachisiState {
  final List<List<int>> steps;
  final int currentPlayer;
  final int consecutiveDoubles;
  final int turnNumber;
  final RulesConfig rules;

  PachisiState({
    required this.steps,
    this.currentPlayer = 0,
    this.consecutiveDoubles = 0,
    this.turnNumber = 1,
    this.rules = RulesConfig.classic,
  });

  factory PachisiState.initial({RulesConfig rules = RulesConfig.classic}) {
    return PachisiState(
      steps: List.generate(
        PachisiRules.playerCount,
        (_) => List.filled(PachisiRules.piecesPerPlayer, PachisiRules.base),
      ),
      rules: rules,
    );
  }

  /// Ring square (0..51) for a piece at [step] on the shared ring.
  int ringPos(int player, int step) =>
      (PachisiRules.startOffset(player) + step) % PachisiRules.ringSize;

  /// Pieces of [owner] currently on [ringSquare] (ring steps only).
  List<int> piecesOnRing(int owner, int ringSquare) {
    final out = <int>[];
    for (var i = 0; i < PachisiRules.piecesPerPlayer; i++) {
      final s = steps[owner][i];
      if (s >= 0 && s <= PachisiRules.lastRingStep && ringPos(owner, s) == ringSquare) {
        out.add(i);
      }
    }
    return out;
  }

  /// Number of [player]'s pieces finished at home.
  int homeCount(int player) =>
      steps[player].where((s) => s == PachisiRules.home).length;

  bool get isFinished => homeCount(currentPlayer) == PachisiRules.piecesPerPlayer;

  /// Has [player] finished all four pieces?
  bool playerFinished(int player) =>
      steps[player].every((s) => s == PachisiRules.home);

  PachisiState copyWith({
    List<List<int>>? steps,
    int? currentPlayer,
    int? consecutiveDoubles,
    int? turnNumber,
  }) {
    return PachisiState(
      steps: steps ?? this.steps.map((r) => List<int>.from(r)).toList(),
      currentPlayer: currentPlayer ?? this.currentPlayer,
      consecutiveDoubles: consecutiveDoubles ?? this.consecutiveDoubles,
      turnNumber: turnNumber ?? this.turnNumber,
      rules: rules,
    );
  }
}

/// Result of probing a landing square.
enum _Landing { ok, capture, blocked }

_Landing _probeLanding(PachisiState s, int player, int ring) {
  var blocked = false;
  var capturable = false;
  for (var o = 0; o < PachisiRules.playerCount; o++) {
    if (o == player) continue;
    final n = s.piecesOnRing(o, ring).length;
    if (n == 0) continue;
    if (n >= 2 && s.rules.blockadesEnabled) {
      blocked = true;
      break;
    }
    if (n == 1 && !PachisiRules.isSafe(ring) && s.rules.capturesEnabled) {
      capturable = true;
    }
    // n == 1 on a safe square: shared peacefully.
    // n >= 2 with blockades disabled: treated as capturable-free stack? No:
    // without blockades, stacks are just uncapturable groups.
    if (n >= 2 && !s.rules.blockadesEnabled) {
      // cannot capture a stack even in kids mode
      blocked = true;
      break;
    }
  }
  if (blocked) return _Landing.blocked;
  return capturable ? _Landing.capture : _Landing.ok;
}

bool _opponentBlockadeOnPath(PachisiState s, int player, int ring) {
  if (!s.rules.blockadesEnabled) return false;
  for (var o = 0; o < PachisiRules.playerCount; o++) {
    if (o == player) continue;
    if (s.piecesOnRing(o, ring).length >= 2) return true;
  }
  return false;
}

/// All legal moves for [player] given a 2d6 roll ([d1], [d2]).
List<PachisiMove> legalMoves(PachisiState s, int player, int d1, int d2) {
  final roll = d1 + d2;
  final moves = <PachisiMove>[];
  for (var piece = 0; piece < PachisiRules.piecesPerPlayer; piece++) {
    final from = s.steps[player][piece];
    if (from == PachisiRules.home) continue;

    if (from == PachisiRules.base) {
      // Entering the board needs the entry roll on at least one die.
      if (d1 != s.rules.entryRoll && d2 != s.rules.entryRoll) continue;
      final ring = PachisiRules.startOffset(player);
      final probe = _probeLanding(s, player, ring);
      if (probe == _Landing.blocked) continue;
      moves.add(PachisiMove(
        player: player,
        piece: piece,
        from: from,
        to: 0,
        isEnter: true,
        isCapture: probe == _Landing.capture,
        captured: probe == _Landing.capture
            ? _capturedOn(s, player, ring)
            : const [],
      ));
      continue;
    }

    final to = from + roll;
    if (to > PachisiRules.home) continue; // exact roll required

    // Path must not cross an opponent blockade.
    var pathBlocked = false;
    if (from <= PachisiRules.lastRingStep) {
      final end = to <= PachisiRules.lastRingStep ? to : PachisiRules.lastRingStep;
      for (var step = from + 1; step <= end; step++) {
        if (_opponentBlockadeOnPath(s, player, s.ringPos(player, step))) {
          pathBlocked = true;
          break;
        }
      }
    }
    if (pathBlocked) continue;

    if (to <= PachisiRules.lastRingStep) {
      final ring = s.ringPos(player, to);
      final probe = _probeLanding(s, player, ring);
      if (probe == _Landing.blocked) continue;
      moves.add(PachisiMove(
        player: player,
        piece: piece,
        from: from,
        to: to,
        isCapture: probe == _Landing.capture,
        captured: probe == _Landing.capture ? _capturedOn(s, player, ring) : const [],
        reachesHome: false,
      ));
    } else {
      // Home stretch or exact home: always safe.
      moves.add(PachisiMove(
        player: player,
        piece: piece,
        from: from,
        to: to,
        reachesHome: to == PachisiRules.home,
      ));
    }
  }
  return moves;
}

List<CapturedPiece> _capturedOn(PachisiState s, int player, int ring) {
  final out = <CapturedPiece>[];
  for (var o = 0; o < PachisiRules.playerCount; o++) {
    if (o == player) continue;
    for (final piece in s.piecesOnRing(o, ring)) {
      out.add(CapturedPiece(o, piece));
    }
  }
  return out;
}

/// Applies [move] and returns the resulting state (original untouched).
PachisiState applyMove(PachisiState s, PachisiMove move) {
  final steps = s.steps.map((r) => List<int>.from(r)).toList();
  steps[move.player][move.piece] = move.to;
  for (final c in move.captured) {
    steps[c.player][c.piece] = PachisiRules.base;
  }
  return s.copyWith(steps: steps);
}

/// Convenience: does [player] have any legal move for this roll?
bool hasAnyMove(PachisiState s, int player, int d1, int d2) =>
    legalMoves(s, player, d1, d2).isNotEmpty;
