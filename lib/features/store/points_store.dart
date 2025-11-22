// lib/features/store/points_store.dart

import 'package:flutter/material.dart';

// Local constants for point amounts and prices
const int kMonthlySubscriptionPoints = 500;
const double kMonthlySubscriptionPrice = 9.99;

const int kYearlySubscriptionPoints = 1500;
const double kYearlySubscriptionPrice = 89.99;

const int kOneTimePurchasePoints = 1000;
const double kOneTimePurchasePrice = 14.99;

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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Monthly Subscription
          _buildPlanCard(
            context: context,
            title: 'Monthly Plan',
            subtitle:
                'Earn $kMonthlySubscriptionPoints points every month.',
            price:
                '\$${kMonthlySubscriptionPrice.toStringAsFixed(2)}/month',
            tag: 'Best for trying premium features',
            highlight: true,
          ),
          const SizedBox(height: 12),

          // Yearly Subscription
          _buildPlanCard(
            context: context,
            title: 'Yearly Plan',
            subtitle:
                'Earn $kYearlySubscriptionPoints points monthly.',
            price:
                '\$${kYearlySubscriptionPrice.toStringAsFixed(2)}/year',
            tag: 'Save 25% | 1500 pts monthly',
            highlight: true,
          ),
          const SizedBox(height: 12),

          // One-time Purchase
          _buildPlanCard(
            context: context,
            title: 'One-time Purchase',
            subtitle:
                'Get $kOneTimePurchasePoints points instantly.',
            price:
                '\$${kOneTimePurchasePrice.toStringAsFixed(2)} (one-time)',
            tag: 'Perfect for casual users',
            highlight: false,
          ),
          const SizedBox(height: 24),

          // Info section
          const Text(
            'Points can be used to unlock photos, start chats, '
            'join video calls, or skip wait times on matches.',
            style: TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String price,
    required String tag,
    bool highlight = false,
  }) {
    return Card(
      color: highlight ? Colors.blue.shade50 : null,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tag,
              style: TextStyle(
                color: highlight ? Colors.blue.shade700 : Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: integrate RevenueCat purchase call here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    highlight ? Colors.blue.shade700 : Colors.grey.shade900,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(highlight ? 'Subscribe' : 'Purchase'),
            ),
          ],
        ),
      ),
    );
  }
}
