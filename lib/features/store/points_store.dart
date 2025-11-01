import 'package:flutter/material.dart';
import 'revenuecat_purchase_bridge.dart';

class PointsStorePage extends StatefulWidget {
  const PointsStorePage({super.key});
  @override
  State<PointsStorePage> createState() => _PointsStorePageState();
}

class _PointsStorePageState extends State<PointsStorePage> {
  bool _inited = false;
  String _status = '';

  Future<void> _setup() async {
    if (_inited) return;
    try {
      const apiKey = String.fromEnvironment('RC_SDK_KEY');
      await RevenueCatPurchase.setup(apiKey);
      _inited = true;
    } catch (e) {
      _status = 'RevenueCat init error: $e';
    }
  }

  Future<void> _buy(String productId, int creditPoints) async {
    await _setup();
    final res = await RevenueCatPurchase.purchaseProduct(productId);
    setState(() {
      _status = res.success
          ? 'Purchase successful. ($creditPoints pts)'
          : 'Purchase failed: ${res.error ?? 'unknown error'}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Get Points')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Choose a pack:'),
          const SizedBox(height: 8),
          _tile('100 pts',  'bym_points_100',  100,  '\$0.99'),
          _tile('300 pts',  'bym_points_300',  300,  '\$2.49'),
          _tile('1000 pts', 'bym_points_1000', 1000, '\$6.99'),
          const SizedBox(height: 12),
          if (_status.isNotEmpty) Text(_status),
          const Divider(),
          const Text(
            'Notes: In production, credit points via a secure webhook '
            '(e.g., Cloud Function/Supabase Edge Function) after 
purchase.',
          ),
        ],
      ),
    );
  }

  Widget _tile(String title, String productId, int pts, String price) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.flash_on),
        title: Text(title),
        subtitle: Text(price),
        trailing: FilledButton(
          onPressed: () => _buy(productId, pts),
          child: const Text('Buy'),
        ),
      ),
    );
  }
}

