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

          // 🔹 Monthly Subscription
          _buildPlanCard(
            context,
            title: 'Monthly Plan',
            subtitle:
                'Earn ${PointsCosts.monthlySubscriptionPoints} points every month.',
            price:
                '\$${PointsCosts.monthlySubscriptionPrice.toStringAsFixed(2)}/month',
            tag: 'Best for trying premium features.',
          ),

          // 🔹 Yearly Subscription
          _buildPlanCard(
            context,
            title: 'Yearly Plan',
            subtitle:
                'Earn ${PointsCosts.yearlySubscriptionPoints} points monthly.',
            price:
                '\$${PointsCosts.yearlySubscriptionPrice.toStringAsFixed(2)}/year',
            tag: 'Save 25% – 1500 pts monthly',
            highlight: true,
          ),

          // 🔹 One-Time Purchase
          _buildPlanCard(
            context,
            title: 'One-Time Purchase',
            subtitle:
                '${PointsCosts.oneTimePurchasePoints} points instantly.',
            price:
                '\$${PointsCosts.oneTimePurchasePrice.toStringAsFixed(2)} (one-time)',
            tag: 'Perfect for casual users',
          ),

          const SizedBox(height: 24),

          // ℹ️ Information Section
          const Text(
            'Points can be used to unlock photos, start chats, join video calls, '
            'or skip wait times.',
            style: TextStyle(color: Colors.grey, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
