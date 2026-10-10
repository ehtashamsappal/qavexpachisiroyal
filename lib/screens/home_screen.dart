import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/storage.dart';
import '../widgets/royal_widgets.dart';

/// 2. Home — play, daily reward, streak, quick navigation.
class HomeScreen extends StatefulWidget {
  final AppState app;
  const HomeScreen({super.key, required this.app});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    AudioService().menuMusic();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showAchievementPopups(context, widget.app);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return Scaffold(
      appBar: AppBar(
        title: const Text('♛ Pachisi Royal'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: CoinChip(app)),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _crestCard(context, app),
            const SizedBox(height: 12),
            if (!app.dailyRewardClaimed) _dailyCard(app),
            const SizedBox(height: 8),
            RoyalButton(
              label: 'Play',
              emoji: '🎲',
              onTap: () => Navigator.pushNamed(context, '/modes'),
            ),
            const SizedBox(height: 8),
            RoyalButton(
              label: 'Tournament Ladder',
              emoji: '🏆',
              outlined: true,
              onTap: () => Navigator.pushNamed(context, '/levels',
                  arguments: {'preselect': 'tournament'}),
            ),
            const SizedBox(height: 16),
            _menuGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _crestCard(BuildContext context, AppState app) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: scheme.primary,
              child: Text(app.avatar, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.playerName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '🔥 ${app.streak}-day streak  •  🏆 ${app.gamesWon}/${app.gamesPlayed} wins',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Text('✏️', style: TextStyle(fontSize: 22)),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyCard(AppState app) {
    return Card(
      color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
      child: ListTile(
        leading: const Text('🎁', style: TextStyle(fontSize: 32)),
        title: const Text('Daily Reward ready!'),
        subtitle: Text('Day ${app.streak} streak — tap to claim'),
        trailing: ElevatedButton(
          onPressed: () {
            final n = app.claimDailyReward();
            AudioService().coin();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('+$n 🪙 Royal Coins claimed!')),
            );
          },
          child: const Text('Claim'),
        ),
      ),
    );
  }

  Widget _menuGrid(BuildContext context) {
    final items = [
      ('🛍️', 'Shop', '/shop'),
      ('🎨', 'Themes', '/themes'),
      ('📊', 'Stats', '/stats'),
      ('👤', 'Profile', '/profile'),
      ('📖', 'How to Play', '/howto'),
      ('⚙️', 'Settings', '/settings'),
      ('ℹ️', 'About', '/about'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.15,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final (emoji, label, route) = items[i];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              AudioService().click();
              Navigator.pushNamed(context, route);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 6),
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}
