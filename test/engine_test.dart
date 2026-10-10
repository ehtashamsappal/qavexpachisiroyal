import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:qavexpachisiroyal/game/ai.dart';
import 'package:qavexpachisiroyal/game/cowrie_dice.dart';
import 'package:qavexpachisiroyal/game/game_state.dart';
import 'package:qavexpachisiroyal/game/pachisi_rules.dart';

PachisiState stateWith(List<List<int>> steps, {RulesConfig rules = RulesConfig.classic}) =>
    PachisiState(steps: steps, rules: rules);

List<List<int>> fresh() =>
    List.generate(4, (_) => List.filled(4, PachisiRules.base));

void main() {
  group('entry rules', () {
    test('piece enters on a six', () {
      final s = stateWith(fresh());
      final moves = legalMoves(s, 0, 6, 2);
      expect(moves.where((m) => m.isEnter), isNotEmpty);
      expect(moves.first.to, 0);
    });

    test('no entry without a six', () {
      final s = stateWith(fresh());
      expect(legalMoves(s, 0, 3, 4), isEmpty);
    });

    test('entry on doubles of sixes only when a six shows', () {
      final s = stateWith(fresh());
      expect(legalMoves(s, 0, 5, 5), isEmpty);
      expect(legalMoves(s, 0, 6, 6).where((m) => m.isEnter), isNotEmpty);
    });
  });

  group('movement', () {
    test('basic advance along the ring', () {
      final steps = fresh();
      steps[0][0] = 10;
      final s = stateWith(steps);
      final moves = legalMoves(s, 0, 3, 4); // roll 7
      final m = moves.firstWhere((m) => m.piece == 0);
      expect(m.to, 17);
    });

    test('exact roll required to go home', () {
      final steps = fresh();
      steps[0][0] = 55; // needs exactly 2
      final s = stateWith(steps);
      expect(legalMoves(s, 0, 3, 4).where((m) => m.piece == 0), isEmpty); // roll 7
      final ok = legalMoves(s, 0, 1, 1).where((m) => m.piece == 0);
      expect(ok, isNotEmpty);
      expect(ok.first.to, 57);
      expect(ok.first.reachesHome, isTrue);
    });

    test('home stretch is safe and reachable', () {
      final steps = fresh();
      steps[0][0] = 49; // roll 7 -> 56 (home stretch)
      final s = stateWith(steps);
      final moves = legalMoves(s, 0, 3, 4);
      expect(moves.firstWhere((m) => m.piece == 0).to, 56);
    });
  });

  group('captures', () {
    test('landing on lone opponent captures it', () {
      final steps = fresh();
      steps[0][0] = 10; // ring pos 10
      steps[1][0] = 4; // player1 start offset 13 -> ring pos 17
      final s = stateWith(steps);
      final moves = legalMoves(s, 0, 3, 4); // 10 + 7 = 17
      final m = moves.firstWhere((m) => m.piece == 0);
      expect(m.isCapture, isTrue);
      final after = applyMove(s, m);
      expect(after.steps[1][0], PachisiRules.base);
      expect(after.steps[0][0], 17);
    });

    test('safe squares protect from capture', () {
      final steps = fresh();
      // ring 8 is safe. player0 step 8 -> ring 8.
      steps[1][0] = 1; // player1: ring (13+1)%52 = 14
      steps[0][0] = 1; // ring 1; roll 7 -> ring 8 (safe)
      // put opponent on safe square 8: player1 step = (8-13)%52 = 47
      final steps2 = fresh();
      steps2[0][0] = 1;
      steps2[1][0] = 47; // ring 8, safe
      final s2 = stateWith(steps2);
      final moves = legalMoves(s2, 0, 3, 4);
      final m = moves.firstWhere((m) => m.piece == 0);
      expect(m.isCapture, isFalse);
      final after = applyMove(s2, m);
      expect(after.steps[1][0], 47); // untouched
    });

    test('kids mode disables captures', () {
      final steps = fresh();
      steps[0][0] = 10;
      steps[1][0] = 4; // ring 17
      final s = stateWith(steps, rules: RulesConfig.kids);
      final moves = legalMoves(s, 0, 3, 4);
      final m = moves.firstWhere((m) => m.piece == 0);
      expect(m.isCapture, isFalse);
      expect(applyMove(s, m).steps[1][0], 4);
    });
  });

  group('blockades', () {
    test('opponent pair blocks landing', () {
      final steps = fresh();
      steps[0][0] = 10;
      steps[1][0] = 4; // ring 17
      steps[1][1] = 4; // ring 17 -> blockade
      final s = stateWith(steps);
      final moves = legalMoves(s, 0, 3, 4);
      expect(moves.where((m) => m.piece == 0), isEmpty);
    });

    test('opponent pair blocks passing over', () {
      final steps = fresh();
      steps[0][0] = 10;
      steps[1][0] = 9; // ring 22
      steps[1][1] = 9; // blockade at ring 22
      final s = stateWith(steps);
      // roll 12: path 11..22 crosses ring 22 -> illegal
      expect(legalMoves(s, 0, 6, 6).where((m) => m.piece == 0), isEmpty);
      // roll 11: lands exactly on 21, no crossing
      final ok = legalMoves(s, 0, 5, 6).where((m) => m.piece == 0);
      expect(ok, isNotEmpty);
    });

    test('own pair may be passed and landed on', () {
      final steps = fresh();
      steps[0][0] = 10;
      steps[0][1] = 14; // ring 14 pair? single
      steps[0][2] = 14; // pair at ring 14
      final s = stateWith(steps);
      final moves = legalMoves(s, 0, 2, 2); // roll 4: 10 -> 14
      expect(moves.where((m) => m.piece == 0), isNotEmpty);
    });
  });

  group('state helpers', () {
    test('ring position wraps correctly', () {
      final s = stateWith(fresh());
      expect(s.ringPos(0, 50), 50);
      expect(s.ringPos(1, 50), (13 + 50) % 52);
      expect(s.ringPos(3, 50), (39 + 50) % 52);
    });

    test('applyMove is immutable', () {
      final steps = fresh();
      steps[0][0] = 10;
      final s = stateWith(steps);
      final m = legalMoves(s, 0, 3, 4).firstWhere((m) => m.piece == 0);
      final after = applyMove(s, m);
      expect(s.steps[0][0], 10);
      expect(after.steps[0][0], 17);
    });

    test('playerFinished detection', () {
      final steps = fresh();
      steps[0] = [57, 57, 57, 57];
      expect(stateWith(steps).playerFinished(0), isTrue);
      expect(stateWith(steps).playerFinished(1), isFalse);
    });
  });

  group('dice', () {
    test('rolls are within 1..6 and distribution looks sane', () {
      final dice = CowrieDice(random: Random(42));
      final counts = <int, int>{};
      for (var i = 0; i < 3600; i++) {
        final r = dice.roll();
        expect(r.$1, inInclusiveRange(1, 6));
        expect(r.$2, inInclusiveRange(1, 6));
        counts[CowrieDice.sum(r)] = (counts[CowrieDice.sum(r)] ?? 0) + 1;
      }
      // 7 should be the most common sum of 2d6.
      final top = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      expect(top, 7);
    });
  });

  group('AI', () {
    PachisiState midGame() {
      final steps = fresh();
      steps[0][0] = 20;
      steps[0][1] = 5;
      steps[1][0] = 10; // capturable target
      steps[2][0] = 30;
      return stateWith(steps);
    }

    test('all difficulties return a legal move', () {
      final ai = PachisiAi(random: Random(7));
      for (final d in AiDifficulty.values) {
        final s = midGame();
        final moves = legalMoves(s, 0, 6, 2);
        final choice = ai.choose(s, 0, moves, d);
        expect(moves, contains(choice));
      }
    });

    test('medium+ prefer captures over quiet moves', () {
      // Player 0 piece at step 10 (ring 10); opponent lone piece at ring 15.
      // Player1 step for ring 15: (15-13)=2.
      final steps = fresh();
      steps[0][0] = 10;
      steps[0][1] = 40; // alternative quiet move
      steps[1][0] = 2; // ring 15, lone, non-safe
      final s = stateWith(steps);
      final moves = legalMoves(s, 0, 2, 3); // roll 5: 10->15 capture
      expect(moves.any((m) => m.isCapture), isTrue);
      final ai = PachisiAi(random: Random(1));
      for (final d in [AiDifficulty.medium, AiDifficulty.hard, AiDifficulty.expert]) {
        final choice = ai.choose(s, 0, moves, d);
        expect(choice!.isCapture, isTrue, reason: '$d should capture');
      }
    });

    test('expert respects its time budget', () {
      final ai = PachisiAi(random: Random(3));
      final s = midGame();
      final moves = legalMoves(s, 2, 6, 4);
      final sw = Stopwatch()..start();
      ai.choose(s, 2, moves, AiDifficulty.expert, timeBudgetMs: 300);
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });

    test('evaluation rewards finished pieces', () {
      final a = fresh();
      a[0][0] = 57;
      final b = fresh();
      b[0][0] = 56;
      expect(PachisiAi.evaluate(stateWith(a), 0),
          greaterThan(PachisiAi.evaluate(stateWith(b), 0)));
    });
  });
}
