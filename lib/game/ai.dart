import 'dart:math';

import 'cowrie_dice.dart';
import 'game_state.dart';
import 'move.dart';
import 'pachisi_rules.dart';

/// AI opponent skill levels.
enum AiDifficulty { easy, medium, hard, expert }

extension AiDifficultyX on AiDifficulty {
  String get label => switch (this) {
        AiDifficulty.easy => 'Easy',
        AiDifficulty.medium => 'Medium',
        AiDifficulty.hard => 'Hard',
        AiDifficulty.expert => 'Expert',
      };

  /// Thinking time cap in milliseconds (Expert still answers snappily).
  int get timeBudgetMs => switch (this) {
        AiDifficulty.easy => 50,
        AiDifficulty.medium => 150,
        AiDifficulty.hard => 450,
        AiDifficulty.expert => 900,
      };

  /// Search depth for lookahead difficulties.
  int get depth => switch (this) {
        AiDifficulty.easy => 0,
        AiDifficulty.medium => 1,
        AiDifficulty.hard => 2,
        AiDifficulty.expert => 3,
      };
}

/// Time-capped Pachisi AI.
///
/// Easy plays randomly, Medium is a one-ply greedy tactician, Hard looks one
/// opponent reply ahead, and Expert searches deeper with sampled dice
/// outcomes — all strictly inside their time budget.
class PachisiAi {
  final Random _random;
  PachisiAi({Random? random}) : _random = random ?? Random();

  PachisiMove? choose(
    PachisiState state,
    int player,
    List<PachisiMove> moves,
    AiDifficulty difficulty, {
    int? timeBudgetMs,
  }) {
    if (moves.isEmpty) return null;
    if (moves.length == 1) return moves.first;
    final budget = timeBudgetMs ?? difficulty.timeBudgetMs;
    final stopwatch = Stopwatch()..start();

    switch (difficulty) {
      case AiDifficulty.easy:
        return moves[_random.nextInt(moves.length)];
      case AiDifficulty.medium:
        return _bestOf(state, player, moves);
      case AiDifficulty.hard:
      case AiDifficulty.expert:
        return _timeCappedSearch(
          state,
          player,
          moves,
          difficulty.depth,
          budget,
          stopwatch,
        );
    }
  }

  // -- Heuristic evaluation -------------------------------------------------

  /// Static board evaluation from [player]'s perspective. Higher is better.
  static double evaluate(PachisiState s, int player) {
    var score = 0.0;
    for (var p = 0; p < PachisiRules.piecesPerPlayer; p++) {
      final step = s.steps[player][p];
      if (step == PachisiRules.home) {
        score += 1200;
      } else if (step == PachisiRules.base) {
        score -= 40;
      } else {
        score += step * 4.0;
        if (step <= PachisiRules.lastRingStep) {
          final ring = s.ringPos(player, step);
          if (PachisiRules.isSafe(ring)) {
            score += 60; // castles are havens
          } else {
            score -= _danger(s, player, ring) * 25.0;
          }
          // Stacking own pieces builds blockades.
          final own = s.piecesOnRing(player, ring).length;
          if (own >= 2) score += 90;
        } else {
          score += 80; // home stretch: almost there
        }
      }
    }
    // Reward finished pieces strongly to close out games.
    score += s.homeCount(player) * 200.0;
    return score;
  }

  /// Rough danger estimate: how many active enemy pieces sit behind this
  /// ring square within striking distance (<= 12 steps of ring travel).
  static int _danger(PachisiState s, int player, int ring) {
    var danger = 0;
    for (var o = 0; o < PachisiRules.playerCount; o++) {
      if (o == player) continue;
      for (var p = 0; p < PachisiRules.piecesPerPlayer; p++) {
        final step = s.steps[o][p];
        if (step < 0 || step > PachisiRules.lastRingStep) continue;
        final oRing = s.ringPos(o, step);
        final dist = (ring - oRing) % PachisiRules.ringSize;
        if (dist >= 1 && dist <= 12) danger++;
      }
    }
    return danger;
  }

  /// Immediate tactical score of a move (captures, home, entering, progress).
  static double _moveBonus(PachisiMove m) {
    var b = 0.0;
    if (m.isCapture) b += 320 + m.captured.length * 120.0;
    if (m.reachesHome) b += 500;
    if (m.isEnter) b += 140;
    b += (m.to - m.from).clamp(0, 12) * 3.0;
    return b;
  }

  PachisiMove _bestOf(PachisiState s, int player, List<PachisiMove> moves) {
    PachisiMove? best;
    var bestScore = double.negativeInfinity;
    for (final m in moves) {
      final after = applyMove(s, m);
      final score = evaluate(after, player) + _moveBonus(m) * 0.35;
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best ?? moves.first;
  }

  // -- Time-capped lookahead search ------------------------------------------

  PachisiMove _timeCappedSearch(
    PachisiState s,
    int player,
    List<PachisiMove> moves,
    int depth,
    int budgetMs,
    Stopwatch sw,
  ) {
    // Order moves by the fast greedy score so the best candidates are
    // examined first; if the clock runs out we still return something good.
    final ordered = List<PachisiMove>.from(moves)
      ..sort((a, b) => _quickScore(s, player, b).compareTo(_quickScore(s, player, a)));

    PachisiMove best = ordered.first;
    var bestValue = double.negativeInfinity;

    for (final m in ordered) {
      if (sw.elapsedMilliseconds >= budgetMs) break;
      final after = applyMove(s, m);
      final value = _moveBonus(m) * 0.3 +
          _expectimax(after, player, depth - 1, budgetMs, sw, maximizing: false);
      if (value > bestValue) {
        bestValue = value;
        best = m;
      }
    }
    return best;
  }

  double _quickScore(PachisiState s, int player, PachisiMove m) {
    final after = applyMove(s, m);
    return evaluate(after, player) + _moveBonus(m) * 0.35;
  }

  /// Chance + opponent nodes. Opponents are modelled with their greedy reply
  /// (a strong, fast proxy); dice outcomes are sampled, not enumerated.
  double _expectimax(
    PachisiState s,
    int player,
    int depth,
    int budgetMs,
    Stopwatch sw,
    {required bool maximizing,
    int samples = 6}) {
    if (sw.elapsedMilliseconds >= budgetMs) {
      return evaluate(s, player);
    }
    if (depth <= 0) return evaluate(s, player);

    if (maximizing) {
      // Our turn again (extra turn): pick the best sampled move.
      final dice = CowrieDice(random: _random);
      var total = 0.0;
      for (var i = 0; i < samples; i++) {
        final r = dice.roll();
        final ms = legalMoves(s, player, r.$1, r.$2);
        if (ms.isEmpty) {
          total += evaluate(s, player) - 30;
        } else {
          final m = _bestOf(s, player, ms);
          total += _moveBonus(m) * 0.3 +
              _expectimax(applyMove(s, m), player, depth - 1, budgetMs, sw,
                  maximizing: false, samples: samples);
        }
        if (sw.elapsedMilliseconds >= budgetMs) break;
      }
      return total / samples;
    } else {
      // Opponent reply: average damage over active opponents' greedy replies.
      var worst = evaluate(s, player);
      var counted = 0;
      for (var o = 0; o < PachisiRules.playerCount; o++) {
        if (o == player) continue;
        if (s.playerFinished(o)) continue;
        final dice = CowrieDice(random: _random);
        var oppTotal = 0.0;
        var n = 0;
        for (var i = 0; i < samples; i++) {
          final r = dice.roll();
          final ms = legalMoves(s, o, r.$1, r.$2);
          if (ms.isEmpty) continue;
          // Opponent maximises its own evaluation.
          PachisiMove? reply;
          var rs = double.negativeInfinity;
          for (final m in ms) {
            final v = evaluate(applyMove(s, m), o) + _moveBonus(m) * 0.35;
            if (v > rs) {
              rs = v;
              reply = m;
            }
          }
          oppTotal += evaluate(applyMove(s, reply!), player);
          n++;
          if (sw.elapsedMilliseconds >= budgetMs) break;
        }
        if (n > 0) {
          final avg = oppTotal / n;
          if (avg < worst) worst = avg;
          counted++;
        }
        if (sw.elapsedMilliseconds >= budgetMs) break;
      }
      return counted == 0 ? evaluate(s, player) : (evaluate(s, player) + worst) / 2;
    }
  }
}
