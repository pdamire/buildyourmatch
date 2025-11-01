import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatPurchase {
  static Future<void> setup(String apiKey) async {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  static Future<PurchaseResult> purchaseProduct(String productId) async {
    try {
      final result = await Purchases.purchaseProduct(productId);
      return PurchaseResult(success: true, productId: productId);
    } catch (e) {
      return PurchaseResult(success: false, productId: productId, error: 
e.toString());
    }
  }
}

class PurchaseResult {
  final bool success;
  final String productId;
  final String? error;

  PurchaseResult({
    required this.success,
    required this.productId,
    this.error,
  });
}

