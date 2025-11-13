// lib/features/store/points_store.dart
import 'package:flutter/material.dart';
import 'package:build_your_match/constants/points_costs.dart';

class PointsStorePage extends StatelessWidget {
  const PointsStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Points Store'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Get More Points 💎',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 🟢 Monthly Subscription
          _buildPlanCard(
            context,
            title: 'Monthly Plan',
            subtitle: 'Earn ${PointsCosts.monthlySubscriptionPoints} points every month.',
            price: '\$${PointsCosts.monthlySubscriptionPrice.toStringAsFixed(2)}/month',
            tag: 'Best for trying premium features',
          ),

          // 🔵 Yearly Subscription
          _buildPlanCard(
            context,
            title: 'Yearly Plan',
            subtitle: 'Earn ${PointsCosts.yearlySubscriptionPoints} points monthly.',
            price: '\$${PointsCosts.yearlySubscriptionPrice.toStringAsFixed(2)}/year',
            tag: 'Save 25% — 1500 pts monthly',
            highlight: true,
          ),

          // 💵 One-Time Purchase
          _buildPlanCard(
            context,
            title: 'One-Time Purchase',
            subtitle: '${PointsCosts.oneTimePurchasePoints} points instantly.',
            price: '\$${PointsCosts.oneTimePurchasePrice.toStringAsFixed(2)} (one-time)',
            tag: 'Perfect for casual users',
          ),

          const SizedBox(height: 24),

          // ⚙️ Information Section
          Text(
            'Points can be used to unlock photos, start chats, join video calls, or skip wait times.',
            style: TextStyle(color: Colors.grey[600], height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String price,
    required String tag,
    bool highlight = false,
  }) {
    return Card(
      color: highlight ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 6),
            Text(tag, style: TextStyle(color: Colors.blue.shade700, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: integrate RevenueCat purchase call here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: highlight ? Colors.blue.shade700 : Colors.grey.shade900,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(highlight ? 'Subscribe Yearly' : 'Purchase'),
            ),
          ],
        ),
      ),
    );
  }
}
