import 'package:flutter/material.dart';

import '../game/pachisi_rules.dart';
import '../services/storage.dart';
import '../widgets/royal_widgets.dart';

/// 11. How to Play — official classic rules, cowrie table, tactics.
class HowToPlayScreen extends StatelessWidget {
  final AppState app;
  const HowToPlayScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to Play')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader('The Royal Game', emoji: '👑'),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/images/cross_board_art.png'),
          ),
          const SizedBox(height: 10),
          _P('Pachisi is the ancient Indian race game of kings — the ancestor of Ludo. '
              'Four armies of four pieces race around the cross-shaped board. '
              'Bring all four of your pieces home before your rivals to claim the crown.'),
          SectionHeader('Cowrie Dice 🎲', emoji: '🐚'),
          _P('Kings once cast six cowrie shells. This royal edition uses two dice as the '
              'digital equivalent — the traditions remain:'),
          _Bullet('Roll a 6 on either die to march a piece out of your yard.'),
          _Bullet('Move the sum of both dice.'),
          _Bullet('Rolling a 6, doubles, capturing, or bringing a piece home earns another turn.'),
          _Bullet('Three consecutive doubles forfeits the turn — fortune punishes greed!'),
          _CowrieTable(),
          SectionHeader('Captures ⚔️', emoji: '⚔️'),
          _P('Land on a square holding a single enemy piece to capture it — it returns to its yard, '
              'and you roll again. The 8 star-marked castle squares (★) are safe: no captures there, '
              'and rivals may share them peacefully.'),
          SectionHeader('Blockades 🧱', emoji: '🧱'),
          _P('Two or more of your pieces on one square form a blockade: rivals cannot pass through '
              'or land on it. Build walls to guard your path — and smash through gaps in theirs.'),
          SectionHeader('Home Stretch 🏠', emoji: '🏠'),
          _P('After a full lap, pieces turn into their coloured home column. '
              'You need the exact roll to enter home — overshooting is not allowed.'),
          SectionHeader('Royal Tactics 🧠', emoji: '🧠'),
          _Bullet('Keep pieces on castle squares when danger lurks behind you.'),
          _Bullet('Travel in pairs to build blockades near enemy paths.'),
          _Bullet('Count 12 squares back — that is your danger zone.'),
          _Bullet('Sometimes the bravest move is bringing a fresh piece out.'),
          SectionHeader('Kids Mode 🧒', emoji: '🧒'),
          _P('Enable Kids Mode in Settings for capture-free, blockade-free racing — perfect for young princes and princesses.'),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _P extends StatelessWidget {
  final String text;
  const _P(this.text);
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: const TextStyle(fontSize: 15, height: 1.5)));
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  ', style: TextStyle(fontSize: 16)),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.45))),
          ],
        ),
      );
}

class _CowrieTable extends StatelessWidget {
  const _CowrieTable();
  @override
  Widget build(BuildContext context) {
    final rows = PachisiRules.cowrieTable.entries.toList();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Traditional cowrie values',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...rows.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(e.key), Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold))],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
