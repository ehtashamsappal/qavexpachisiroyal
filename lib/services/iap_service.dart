import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// The single in-app purchase: "Buy Me a Coffee" — a $0.99 voluntary tip
/// supporting the solo developer. Product ID: qavexpachisiroyalcoffee
///
/// The game is fully playable offline with no ads; this purchase is purely
/// a thank-you that grants a badge and 500 Royal Coins.
class IapService {
  static const String coffeeProductId = 'qavexpachisiroyalcoffee';

  static final IapService _instance = IapService._internal();
  factory IapService() => _instance;
  IapService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool available = false;
  ProductDetails? coffeeProduct;
  bool pending = false;
  String? error;

  void Function()? onPurchased;

  Future<void> init({void Function()? onPurchased}) async {
    this.onPurchased = onPurchased;
    try {
      available = await _iap.isAvailable();
      if (!available) return;
      final resp = await _iap.queryProductDetails({coffeeProductId});
      if (resp.productDetails.isNotEmpty) {
        coffeeProduct = resp.productDetails.first;
      }
      if (resp.error != null) {
        error = resp.error!.message;
      }
      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (e) {
          debugPrint('iap stream error: $e');
          pending = false;
        },
      );
    } catch (e) {
      debugPrint('iap init error: $e');
      available = false;
    }
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.productID != coffeeProductId) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          pending = false;
          onPurchased?.call();
          _iap.completePurchase(p);
          break;
        case PurchaseStatus.pending:
          pending = true;
          break;
        case PurchaseStatus.error:
          pending = false;
          error = p.error?.message ?? 'Purchase failed';
          break;
        case PurchaseStatus.canceled:
          pending = false;
          break;
      }
    }
  }

  Future<void> buyCoffee() async {
    error = null;
    if (!available || coffeeProduct == null) {
      error = 'Store unavailable right now. The game is fully free offline!';
      return;
    }
    pending = true;
    try {
      await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: coffeeProduct!),
      );
    } catch (e) {
      pending = false;
      error = 'Could not start purchase: $e';
    }
  }

  Future<void> restore() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('restore error: $e');
    }
  }

  void dispose() => _sub?.cancel();
}
