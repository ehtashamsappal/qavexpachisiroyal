import 'package:flutter/material.dart';

import '../engine/game_controller.dart';
import '../game/ai.dart';
import '../game/pachisi_rules.dart';
import '../models/meta.dart';
import '../services/audio_service.dart';
import '../services/storage.dart';
import '../widgets/royal_widgets.dart';

/// 4. Level Select — configure players, AI count and difficulty, then battle.
class LevelSelectScreen extends StatefulWidget {
  final AppState app;
  final GameMode mode;
  const LevelSelectScreen({super.key, required this.app, required this.mode});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  int humanCount = 1;
  int aiCount = 1;
  AiDifficulty difficulty = AiDifficulty.medium;
  int rung = 1;

  @override
  void initState() {
    super.initState();
    humanCount = widget.mode.defaultHumans;
    if (widget.mode == GameMode.quickMatch) {
      aiCount = 1;
      difficulty = AiDifficulty.medium;
    }
    if (widget.mode == GameMode.classicRoyal) {
      humanCount = 1;
      aiCount = 3;
    }
    if (widget.mode == GameMode.tournament) {
      rung = widget.app.ladderRung.clamp(1, 5);
      final r = tournamentLadder[rung - 1];
      difficulty = r.difficulty;
      aiCount = r.aiCount;
      humanCount = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    return Scaffold(
      appBar: AppBar(title: Text('${mode.icon} ${mode.title}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(mode.description, style: const TextStyle(fontSize: 15)),
          if (mode == GameMode.tournament) ...[
            const SectionHeader('Tournament Ladder', emoji: '🏆'),
            ...tournamentLadder.map((r) {
              final done = widget.app.ladderRung > r.rung;
              final current = rung == r.rung;
              return Card(
                color: current
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
                    : null,
                child: ListTile(
                  leading: Text(done ? '✅' : '🔒',
                      style: const TextStyle(fontSize: 24)),
                  title: Text(
                      'Rung ${r.rung}: ${r.difficulty.label} × ${r.aiCount}'),
                  subtitle: Text(
                      '${r.aiCount} AI opponent${r.aiCount > 1 ? 's' : ''} at ${r.difficulty.label}'),
                  enabled: widget.app.ladderRung >= r.rung,
                  onTap: widget.app.ladderRung >= r.rung
                      ? () {
                          setState(() {
                            rung = r.rung;
                            difficulty = r.difficulty;
                            aiCount = r.aiCount;
                          });
                          AudioService().click();
                        }
                      : null,
                ),
              );
            }),
          ],
          if (mode == GameMode.passAndPlay) ...[
            const SectionHeader('Human Players', emoji: '👥'),
            _stepper('Humans', humanCount, 2, 4, (v) => setState(() => humanCount = v)),
          ],
          if (mode == GameMode.vsAi || mode == GameMode.classicRoyal) ...[
            const SectionHeader('AI Opponents', emoji: '🤖'),
            _stepper('AI courtiers', aiCount, mode == GameMode.classicRoyal ? 3 : 1, 3,
                (v) => setState(() => aiCount = v)),
          ],
          if (mode == GameMode.vsAi ||
              mode == GameMode.quickMatch ||
              mode == GameMode.classicRoyal) ...[
            const SectionHeader('AI Difficulty', emoji: '🧠'),
            Wrap(
              spacing: 8,
              children: AiDifficulty.values.map((d) {
                final sel = d == difficulty;
                return ChoiceChip(
                  label: Text(d.label),
                  selected: sel,
                  onSelected: (_) {
                    setState(() => difficulty = d);
                    AudioService().click();
                  },
                );
              }).toList(),
            ),
          ],
          if (widget.app.kidsMode)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Card(
                child: ListTile(
                  leading: Text('🧒', style: TextStyle(fontSize: 24)),
                  title: Text('Kids Mode active'),
                  subtitle: Text('No captures, friendlier court.'),
                ),
              ),
            ),
          const SizedBox(height: 24),
          RoyalButton(
            label: 'Begin Battle',
            emoji: '⚔️',
            onTap: _start,
          ),
        ],
      ),
    );
  }

  Widget _stepper(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ),
    );
  }

  void _start() {
    final mode = widget.mode;
    // Seats: for 2-player games use opposite corners (0 and 2).
    List<int> seats;
    final totalAI = mode == GameMode.tournament
        ? tournamentLadder[rung - 1].aiCount
        : aiCount;
    final totalHumans = mode == GameMode.tournament ? 1 : humanCount;
    if (totalHumans + totalAI == 2) {
      seats = [0, 2];
    } else if (totalHumans + totalAI == 3) {
      seats = [0, 1, 2];
    } else {
      seats = [0, 1, 2, 3];
    }
    final controllers = <int, AiDifficulty?>{};
    for (var i = 0; i < seats.length; i++) {
      if (i < totalHumans) {
        controllers[seats[i]] = null;
      } else {
        controllers[seats[i]] = mode == GameMode.tournament
            ? tournamentLadder[rung - 1].difficulty
            : difficulty;
      }
    }
    final config = MatchConfig(
      mode: mode,
      seats: seats,
      controllers: controllers,
      ladderRung: mode == GameMode.tournament ? rung : 0,
      rules: widget.app.kidsMode ? RulesConfig.kids : RulesConfig.classic,
    );
    Navigator.pushNamed(context, '/game', arguments: config);
  }
}
