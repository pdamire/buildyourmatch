// lib/constants/points_costs.dart

class PointsCosts {
  // 🎯 Unlock Actions
  static const int unlockImage = 100;      // cost to view a locked photo
  static const int unlockChat = 200;       // cost to start chat with a new user
  static const int videoCall = 400;        // cost to start a video call
  static const int bypassCooldown = 50;    // cost to bypass cooldowns or limits

  // 💰 Subscription Rewards (Automatic Monthly Points)
  static const int monthlySubscriptionPoints = 500;   // $9.99/month
  static const int yearlySubscriptionPoints = 1500;   // $89.99/year
  static const double monthlySubscriptionPrice = 9.99; 
  static const double yearlySubscriptionPrice = 89.99;

  // 💵 One-Time Purchase
  static const int oneTimePurchasePoints = 1000;       // 1000 points ($14.99)
  static const double oneTimePurchasePrice = 14.99;

  // 🎲 Game & Challenge Rewards
  static const int dailyDiceReward = 6;       // max pts per dice roll
  static const int challengeCompletion = 25;  // reward per challenge completed

  // 🧾 Conversion Rate (for UI "value display")
  static const double pointsPerDollar =
      oneTimePurchasePoints / oneTimePurchasePrice;   // ≈ 66.7 pts per $1

  // 📈 Helper Methods (Optional)
  static double getDollarValue(int points) {
    return points / pointsPerDollar;
  }

  static double getMonthlyEquivalentOfYearly() {
    return yearlySubscriptionPrice / 12;
  }
}
