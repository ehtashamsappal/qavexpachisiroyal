import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/storage.dart';
import '../widgets/royal_widgets.dart';

/// 9. Players/Profile — royal identity, avatar, lifetime totals.
class ProfileScreen extends StatefulWidget {
  final AppState app;
  const ProfileScreen({super.key, required this.app});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const avatars = ['👑', '🤴', '👸', '🐯', '🦚', '🐘', '🌙', '⚔️', '🎲', '🏵️'];
  late TextEditingController _name;
  late String _avatar;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.app.playerName);
    _avatar = widget.app.avatar;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return Scaffold(
      appBar: AppBar(title: const Text('Royal Profile')),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 52,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(_avatar, style: const TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader('Choose your crest', emoji: '🎭'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: avatars.map((a) {
                final sel = a == _avatar;
                return GestureDetector(
                  onTap: () {
                    setState(() => _avatar = a);
                    AudioService().click();
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sel
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).cardColor,
                      border: Border.all(
                        color: sel
                            ? const Color(0xFFD4AF37)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                        child: Text(a, style: const TextStyle(fontSize: 28))),
                  ),
                );
              }).toList(),
            ),
            const SectionHeader('Royal name', emoji: '📜'),
            TextField(
              controller: _name,
              maxLength: 20,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. Raja Arjun',
              ),
            ),
            const SizedBox(height: 8),
            RoyalButton(
              label: 'Save Profile',
              emoji: '💾',
              onTap: () {
                app.setProfile(_name.text, _avatar);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile proclaimed! 👑')),
                );
              },
            ),
            const SectionHeader('Lifetime at court', emoji: '📊'),
            _statRow('🪙 Royal Coins', '${app.coins}'),
            _statRow('🎲 Matches played', '${app.gamesPlayed}'),
            _statRow('👑 Matches won', '${app.gamesWon}'),
            _statRow('⚔️ Pieces captured', '${app.totalCaptures}'),
            _statRow('🎯 Dice rolled', '${app.totalRolls}'),
            _statRow('🔥 Best streak', '${app.bestStreak} days'),
            _statRow('🏆 Tournament rung', app.ladderRung > 5 ? 'Complete!' : '${app.ladderRung}/5'),
            if (app.coffeeBought) _statRow('☕ Generous Soul', 'Thank you!'),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label),
        trailing: Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
