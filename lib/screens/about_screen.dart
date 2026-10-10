import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/storage.dart';
import '../widgets/royal_widgets.dart';

/// 12. About & Privacy — QAVEX credits, contact, privacy summary.
class AboutScreen extends StatelessWidget {
  final AppState app;
  const AboutScreen({super.key, required this.app});

  static const _privacy = '''
QAVEX PACHISI ROYAL — PRIVACY POLICY (summary)

Developer: muhammad ehtasham (QAVEX)
Website: https://www.qavex.company/
Email: games@qavex.company
Phone: +923375621550

1. No accounts. The game never asks for your name, email, or any identifier.
2. Offline first. All progress, coins, and settings are stored only on your device.
3. No ads. No ad SDKs, no trackers, no analytics.
4. No data collection. We do not collect, transmit, or sell any personal data.
5. Purchases. The optional "Buy Me a Coffee" tip is processed entirely by Google Play; we receive no payment details.
6. Children. With no data collection and an optional Kids Mode, the game is safe for all ages.
7. Contact. Questions about privacy: games@qavex.company.

Full policy ships with the store listing and at https://www.qavex.company/.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About & Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37), width: 3),
                color: const Color(0xFF8E0E2A),
              ),
              child: const Center(
                child: Text('♛', style: TextStyle(fontSize: 52, color: Color(0xFFFFF8E7))),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Qavex Pachisi Royal',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Version 1.0.0 • The ancient game of kings, reimagined',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
          ),
          const SectionHeader('Crafted by QAVEX', emoji: '🏛️'),
          _info('Developer', 'muhammad ehtasham'),
          _info('Studio', 'QAVEX'),
          _info('Website', 'https://www.qavex.company/'),
          _info('Support', 'games@qavex.company'),
          _info('Phone', '+923375621550'),
          _info('Category', 'Board'),
          const SectionHeader('Privacy', emoji: '🔒'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(_privacy,
                  style: const TextStyle(fontSize: 13, height: 1.5)),
            ),
          ),
          const SizedBox(height: 12),
          RoyalButton(
            label: 'Copy Privacy Summary',
            emoji: '📋',
            outlined: true,
            onTap: () {
              Clipboard.setData(const ClipboardData(text: _privacy));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy summary copied.')),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Made with ♛ in the royal court. No kings were harmed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontSize: 13)),
        subtitle: Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
