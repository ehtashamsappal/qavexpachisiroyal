import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/storage.dart';
import '../models/meta.dart';
import '../widgets/royal_widgets.dart';

/// 6. Shop — Royal Coins cosmetics + the single "Buy Me a Coffee" IAP.
class ShopScreen extends StatefulWidget {
  final AppState app;
  const ShopScreen({super.key, required this.app});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _iap = IapService();
  bool _iapReady = false;

  @override
  void initState() {
    super.initState();
    _iap.init(onPurchased: () {
      widget.app.onCoffeeBought();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('☕ Thank you! +500 Royal Coins!')),
        );
      }
    }).then((_) {
      if (mounted) setState(() => _iapReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Royal Bazaar'),
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
          padding: const EdgeInsets.all(16),
          children: [
            _coffeeCard(app),
            const SectionHeader('Dice Skins', emoji: '🎲'),
            ...shopItems.where((i) => i.kind == 'dice').map((i) => _itemTile(app, i)),
            const SectionHeader('Court Frames', emoji: '🖼️'),
            ...shopItems.where((i) => i.kind == 'frame').map((i) => _itemTile(app, i)),
            const SizedBox(height: 12),
            const Text(
              'Royal Coins are earned by playing — no purchase necessary. The coffee below is an optional tip for the developer.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _coffeeCard(AppState app) {
    return Card(
      color: const Color(0xFF8E0E2A).withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('☕', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            const Text('Buy Me a Coffee',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Qavex Pachisi Royal is made by one indie developer with no ads. '
              'This optional \$0.99 tip keeps the court running — and grants you 500 Royal Coins plus the Generous Soul badge.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (app.coffeeBought)
              const Chip(
                label: Text('☕ Generous Soul — thank you!'),
                backgroundColor: Color(0xFFD4AF37),
              )
            else if (!_iapReady)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _iap.pending
                    ? null
                    : () async {
                        await _iap.buyCoffee();
                        if (mounted) setState(() {});
                        if (_iap.error != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_iap.error!)),
                          );
                        }
                      },
                child: Text(_iap.pending
                    ? 'Processing…'
                    : 'Buy Coffee — ${_iap.coffeeProduct?.price ?? '\$0.99'}'),
              ),
            TextButton(
              onPressed: () => _iap.restore(),
              child: const Text('Restore purchases'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemTile(AppState app, ShopItem item) {
    final owned = app.ownedItems.contains(item.id);
    final equipped = (item.kind == 'dice' && app.diceSkin == item.id) ||
        (item.kind == 'frame' && app.frame == item.id);
    return Card(
      child: ListTile(
        leading: Text(item.icon, style: const TextStyle(fontSize: 32)),
        title: Text(item.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(item.description),
        trailing: equipped
            ? const Chip(label: Text('Equipped'))
            : owned
                ? TextButton(
                    onPressed: () {
                      app.equipItem(item);
                      AudioService().click();
                    },
                    child: const Text('Equip'),
                  )
                : ElevatedButton(
                    onPressed: () {
                      final ok = app.buyItem(item);
                      AudioService().coin();
                      if (!ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Not enough Royal Coins — keep playing!')),
                        );
                      }
                    },
                    child: Text('🪙 ${item.price}'),
                  ),
      ),
    );
  }
}
