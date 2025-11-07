import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatPurchase {
  static Future<void> setup(String apiKey) async {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  // Optional: stub to avoid later errors if you call purchaseProduct
  static Future<({bool success, String? error})> purchaseProduct(String productId) async {
    try {
      final offerings = await Purchases.getOfferings();
      final pkg = offerings.current?.availablePackages.firstWhere(
        (p) => p.storeProduct.identifier == productId,
      );
      if (pkg == null) return (success: false, error: 'Product not found');
      await Purchases.purchasePackage(pkg);
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }
}
