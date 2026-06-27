import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/storage_service.dart';

/// 無料プランで登録できる「やりたいこと」の上限。
/// これを超える追加にはプレミアム（買い切り）が必要。
const int kFreeItemLimit = 15;

/// 買い切りプレミアムのプロダクトID。
/// App Store Connect / Google Play Console で、同じIDの
/// 「非消費型（Non-Consumable）」アイテムを登録すること。
const String kPremiumProductId = 'yumetsumi_premium';

/// 商品情報が取れないときに表示する控えめなフォールバック価格。
/// 実際の表示はストアのローカライズ価格（[ProductDetails.price]）を優先する。
const String kPremiumFallbackPrice = '¥600';

/// プレミアム（買い切り）の購入状態と、無料プランの上限管理を担う。
///
/// 真の購入状態はストア側にあるが、オフラインでも素早く判定できるよう
/// ローカルにキャッシュしている（[StorageService.savePremium]）。
class PremiumRepository extends ChangeNotifier {
  PremiumRepository(this._storage, {InAppPurchase? iap}) : _injectedIap = iap;

  final StorageService _storage;
  final InAppPurchase? _injectedIap;
  InAppPurchase? _iapInstance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// ストア用インスタンスを遅延生成する。
  /// 構築時に [InAppPurchase.instance] へ触れるとプラットフォーム未対応の
  /// テスト環境で失敗するため、ストア初期化まで生成を遅らせている。
  InAppPurchase get _iap =>
      _iapInstance ??= (_injectedIap ?? InAppPurchase.instance);

  bool _isPremium = false;
  bool _storeAvailable = false;
  bool _purchasePending = false;
  ProductDetails? _product;

  /// プレミアム解放済みか。
  bool get isPremium => _isPremium;

  /// 端末でストア（課金）が利用可能か。
  bool get storeAvailable => _storeAvailable;

  /// 購入処理が進行中か（ボタンのローディング表示に使う）。
  bool get purchasePending => _purchasePending;

  /// 商品情報を取得できたか（取得できないと購入導線を出せない）。
  bool get productReady => _product != null;

  /// 表示用の価格ラベル。ストア価格があればそれを、なければフォールバック。
  String get priceLabel => _product?.price ?? kPremiumFallbackPrice;

  /// あと何件、無料で追加できるか（プレミアムなら実質無制限なので大きな値）。
  int remainingFreeSlots(int currentCount) {
    if (_isPremium) return 1 << 30;
    final left = kFreeItemLimit - currentCount;
    return left < 0 ? 0 : left;
  }

  /// 新しく1件追加できるか（上限・課金状態を考慮）。
  bool canAdd(int currentCount) =>
      _isPremium || currentCount < kFreeItemLimit;

  Future<void> init() async {
    // まずキャッシュから素早く解放状態を反映（起動をブロックしない）。
    _isPremium = await _storage.loadPremium();
    notifyListeners();
    // ストア接続・商品取得・復元はバックグラウンドで進める。
    unawaited(_initStore());
  }

  Future<void> _initStore() async {
    try {
      _storeAvailable = await _iap.isAvailable();
      if (!_storeAvailable) {
        notifyListeners();
        return;
      }

      _sub = _iap.purchaseStream.listen(
        _onPurchaseUpdated,
        onDone: () => _sub?.cancel(),
        onError: (_) {},
      );

      final response = await _iap.queryProductDetails({kPremiumProductId});
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
      }
      notifyListeners();
    } catch (_) {
      // ストア未設定・ネットワーク不通などは黙って無効化（無料機能は使える）。
      _storeAvailable = false;
      notifyListeners();
    }
  }

  /// プレミアムを購入する。
  Future<void> buy() async {
    if (!_storeAvailable || _product == null || _isPremium) return;
    _purchasePending = true;
    notifyListeners();
    final param = PurchaseParam(productDetails: _product!);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  /// 過去の購入を復元する（機種変更・再インストール時、iOS審査でも必須）。
  Future<void> restore() async {
    if (!_storeAvailable) return;
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.productID == kPremiumProductId) {
            await _unlock();
          }
          _purchasePending = false;
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          _purchasePending = false;
          break;
      }
      // 完了通知を返さないと購入が保留のまま残る（iOS/Android共通）。
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
    notifyListeners();
  }

  Future<void> _unlock() async {
    if (_isPremium) return;
    _isPremium = true;
    await _storage.savePremium(true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
