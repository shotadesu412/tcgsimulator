import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../data/db/hive_provider.dart';

// ─── 商品ID ─────────────────────────────────────────────
const kProductSlots5 = 'tcgsimulator_deck_slots_5';
const kProductSlots20 = 'tcgsimulator_deck_slots_20';
const kProductSlots50 = 'tcgsimulator_deck_slots_50';

const kSlotProductIds = <String>{
  kProductSlots5,
  kProductSlots20,
  kProductSlots50,
};

/// 商品ID → 追加枠数
const kSlotsByProduct = <String, int>{
  kProductSlots5: 5,
  kProductSlots20: 20,
  kProductSlots50: 50,
};

const _kExtraSlotsKey = 'extraSlots';
const kBaseSlots = 3;

// ─── 追加枠数 StateNotifier ──────────────────────────────
class ExtraSlotsNotifier extends StateNotifier<int> {
  ExtraSlotsNotifier(this._box)
      : super((_box.get(_kExtraSlotsKey) as int?) ?? 0);

  final Box<dynamic> _box;

  Future<void> add(int slots) async {
    final next = state + slots;
    await _box.put(_kExtraSlotsKey, next);
    state = next;
  }
}

final extraSlotsProvider =
    StateNotifierProvider<ExtraSlotsNotifier, int>((ref) {
  return ExtraSlotsNotifier(ref.watch(settingsBoxProvider));
});

/// 合計デッキ上限（基本3 + 追加購入分）
final maxDecksProvider = Provider<int>((ref) {
  return kBaseSlots + ref.watch(extraSlotsProvider);
});

// ─── 購入サービス ─────────────────────────────────────────
class PurchaseService {
  PurchaseService(this._ref);

  final Ref _ref;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// App Store から取得した商品情報（価格表示用）
  List<ProductDetails> products = [];

  bool _initialized = false;
  String? lastError;

  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      lastError = 'ストアに接続できませんでした';
      return;
    }

    _sub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => lastError = '$e',
    );

    final response = await InAppPurchase.instance
        .queryProductDetails(kSlotProductIds);
    if (response.error != null) {
      lastError = response.error!.message;
    }
    products = response.productDetails
      ..sort((a, b) =>
          (kSlotsByProduct[a.id] ?? 0)
              .compareTo(kSlotsByProduct[b.id] ?? 0));
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final slots = kSlotsByProduct[p.productID];
          if (slots != null) {
            _ref.read(extraSlotsProvider.notifier).add(slots);
          }
          if (p.pendingCompletePurchase) {
            InAppPurchase.instance.completePurchase(p);
          }
        case PurchaseStatus.error:
          lastError = p.error?.message;
          if (p.pendingCompletePurchase) {
            InAppPurchase.instance.completePurchase(p);
          }
        case PurchaseStatus.pending:
        case PurchaseStatus.canceled:
          break;
      }
    }
  }

  Future<bool> buy(ProductDetails product) async {
    if (kIsWeb) return false;
    final param = PurchaseParam(productDetails: product);
    return InAppPurchase.instance
        .buyConsumable(purchaseParam: param);
  }

  void dispose() => _sub?.cancel();
}

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService(ref);
  service.init();
  ref.onDispose(service.dispose);
  return service;
});
