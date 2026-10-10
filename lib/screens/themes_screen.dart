import 'package:flutter/material.dart';

import '../models/game_theme.dart';
import '../models/meta.dart';
import '../services/audio_service.dart';
import '../services/storage.dart';
import '../widgets/royal_widgets.dart';

/// 8. Themes — 8 royal palettes, unlockable with Royal Coins.
class ThemesScreen extends StatelessWidget {
  final AppState app;
  const ThemesScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Court Themes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: CoinChip(app)),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.95,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: gameThemes.length,
          itemBuilder: (context, i) {
            final t = gameThemes[i];
            final unlocked = app.unlockedThemes.contains(t.id);
            final active = app.themeId == t.id;
            final price = themePrices[t.id] ?? 0;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: active ? t.secondary : Colors.transparent,
                  width: 3,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  AudioService().click();
                  if (!app.unlockTheme(t.id, price) && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Not enough Royal Coins — keep playing!')),
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          gradient: LinearGradient(
                            colors: [
                              t.background,
                              t.primary,
                              t.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: t.playerColors
                                .map((c) => Container(
                                      width: 20,
                                      height: 20,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 1.5),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(t.tagline,
                              style: const TextStyle(
                                  fontSize: 11, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 4),
                          Text(
                            active
                                ? '✨ Active'
                                : unlocked
                                    ? 'Tap to apply'
                                    : '🔒 🪙 $price',
                            style: TextStyle(
                              fontSize: 12,
                              color: active
                                  ? const Color(0xFFD4AF37)
                                  : Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
