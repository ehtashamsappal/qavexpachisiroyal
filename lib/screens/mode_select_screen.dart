import 'package:flutter/material.dart';

import '../models/meta.dart';
import '../services/audio_service.dart';
import '../services/storage.dart';

/// 3. Mode Select — the six royal game modes.
class ModeSelectScreen extends StatelessWidget {
  final AppState app;
  const ModeSelectScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Battle')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: GameMode.values.length,
        itemBuilder: (context, i) {
          final mode = GameMode.values[i];
          final played = app.modesPlayed.contains(mode);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(mode.icon, style: const TextStyle(fontSize: 28)),
                ),
              ),
              title: Row(
                children: [
                  Text(mode.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17)),
                  if (played) ...[
                    const SizedBox(width: 6),
                    const Text('✓', style: TextStyle(color: Colors.green)),
                  ],
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(mode.description),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                AudioService().click();
                Navigator.pushNamed(context, '/levels', arguments: {'mode': mode});
              },
            ),
          );
        },
      ),
    );
  }
}
