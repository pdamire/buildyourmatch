import 'package:purchases_flutter/purchases_flutter.dart';
  // Map RevenueCat product IDs to point rewards
  static int pointsForProductId(String productId) {
    switch (productId) {
      case 'bym_onetime_access':        // one-time 1000 points
        return PointsCosts.oneTimePurchasePoints;
      case 'buildyourmatch_monthly':    // $9.99 / month
        return PointsCosts.monthlySubscriptionPoints;
      case 'buildyourmatch_yearly':     // $89.99 / year
        return PointsCosts.yearlySubscriptionPoints;
      default:
        return 0;
    }
  }

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

