import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_theme.dart';
import '../services/audio_service.dart';
import '../services/storage.dart';

/// Shared royal UI atoms: buttons, headers, coin chip, achievement popups.

class RoyalButton extends StatelessWidget {
  final String label;
  final String? emoji;
  final VoidCallback? onTap;
  final bool outlined;

  const RoyalButton({
    super.key,
    required this.label,
    this.emoji,
    this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap == null
            ? null
            : () {
                AudioService().click();
                HapticFeedback.lightImpact();
                onTap!();
              },
        style: outlined
            ? ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: theme.colorScheme.secondary,
                side: BorderSide(color: theme.colorScheme.secondary, width: 1.5),
              )
            : null,
        child: Text(
          emoji != null ? '$emoji  $label' : label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? emoji;
  const SectionHeader(this.title, {super.key, this.emoji});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        '${emoji != null ? '$emoji ' : ''}$title',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class CoinChip extends StatelessWidget {
  final AppState app;
  const CoinChip(this.app, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '${app.coins}',
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows queued achievement unlock popups as dialogs.
Future<void> showAchievementPopups(BuildContext context, AppState app) async {
  final ids = app.takePopups();
  for (final id in ids) {
    final a = app.byId(id);
    if (a == null) continue;
    if (!context.mounted) return;
    await AudioService().achievement();
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🏆 Achievement Unlocked!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(a.icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(a.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(a.description, textAlign: TextAlign.center),
            if (a.coinReward > 0) ...[
              const SizedBox(height: 8),
              Text('+${a.coinReward} 🪙 Royal Coins',
                  style: const TextStyle(
                      color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Splendid!'),
          ),
        ],
      ),
    );
  }
}

GameTheme themeOf(AppState app, List<GameTheme> themes) =>
    themes.firstWhere((t) => t.id == app.themeId, orElse: () => themes.first);

/// Accessibility-aware text scale wrapper.
class A11yText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? align;
  const A11yText(this.text, {super.key, this.style, this.align});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style, textAlign: align);
  }
}
