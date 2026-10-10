import 'package:flutter/material.dart';

import '../models/meta.dart';
import '../services/audio_service.dart';
import '../services/storage.dart';
import '../widgets/royal_widgets.dart';

/// 10. Stats & Achievements — 52 achievements, progress, lifetime stats.
class StatsScreen extends StatelessWidget {
  final AppState app;
  const StatsScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((a) => app.achievementsUnlocked.contains(a.id)).toList();
    final locked = achievements.where((a) => !app.achievementsUnlocked.contains(a.id)).toList();
    final winRate = app.gamesPlayed == 0
        ? 0
        : (app.gamesWon / app.gamesPlayed * 100).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Hall of Fame')),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _bigStat('${unlocked.length}/${achievements.length}', 'Unlocked'),
                    _bigStat('$winRate%', 'Win rate'),
                    _bigStat('${app.bestStreak}d', 'Best streak'),
                  ],
                ),
              ),
            ),
            const SectionHeader('Unlocked', emoji: '🏆'),
            if (unlocked.isEmpty)
              const Card(
                child: ListTile(
                  title: Text('No achievements yet'),
                  subtitle: Text('Play a match to earn your first honour!'),
                ),
              ),
            ...unlocked.map((a) => _achTile(a, true)),
            const SectionHeader('Locked', emoji: '🔒'),
            ...locked.map((a) => _achTile(a, false, progress: app.achievementProgress[a.id] ?? 0)),
          ],
        ),
      ),
    );
  }

  Widget _bigStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _achTile(Achievement a, bool done, {int progress = 0}) {
    final showProgress = a.target > 1 && !done;
    return Card(
      color: done ? null : Colors.black12,
      child: ListTile(
        leading: Text(done ? a.icon : '🔒',
            style: const TextStyle(fontSize: 30)),
        title: Text(a.title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: done ? null : Colors.grey)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.description),
            if (showProgress)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: LinearProgressIndicator(
                  value: (progress / a.target).clamp(0.0, 1.0),
                ),
              ),
            if (showProgress) Text('$progress / ${a.target}'),
          ],
        ),
        trailing: a.coinReward > 0
            ? Text('🪙${a.coinReward}',
                style: const TextStyle(color: Color(0xFFD4AF37)))
            : null,
        onTap: () => AudioService().click(),
      ),
    );
  }
}
