import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/storage.dart';
import '../widgets/royal_widgets.dart';

/// 7. Settings — audio, haptics, Kids Mode, accessibility.
class SettingsScreen extends StatelessWidget {
  final AppState app;
  const SettingsScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader('Sound & Feel', emoji: '🔊'),
            _switch('Sound effects', 'Dice, captures and fanfares', app.soundOn,
                () {
              app.toggleSound();
              AudioService().syncSettings(soundOn: app.soundOn, musicOn: app.musicOn);
            }),
            _switch('Royal music', 'Court ambience on menus and boards',
                app.musicOn, () {
              app.toggleMusic();
              AudioService().syncSettings(soundOn: app.soundOn, musicOn: app.musicOn);
              if (app.musicOn) AudioService().menuMusic();
            }),
            _switch('Haptics', 'Gentle vibration on captures', app.hapticsOn,
                app.toggleHaptics),
            const SectionHeader('Family', emoji: '🧒'),
            _switch('Kids Mode', 'No captures, no harsh blockades — pure racing fun',
                app.kidsMode, app.toggleKidsMode),
            const SectionHeader('Accessibility', emoji: '♿'),
            _switch('Larger text', 'Roomier, easier-to-read interface',
                app.largeText, app.toggleLargeText),
            _switch('High contrast', 'Bolder board outlines and pieces',
                app.highContrast, app.toggleHighContrast),
            _switch('Reduce motion', 'Calmer animations, faster turns',
                app.reduceMotion, app.toggleReduceMotion),
            const SectionHeader('Data', emoji: '💾'),
            const Card(
              child: ListTile(
                leading: Text('🔒', style: TextStyle(fontSize: 24)),
                title: Text('Fully offline'),
                subtitle: Text(
                    'All progress stays on this device. No account, no ads, no tracking.'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switch(String title, String subtitle, bool value, VoidCallback onTap) {
    return Card(
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: (_) {
          AudioService().click();
          onTap();
        },
      ),
    );
  }
}
