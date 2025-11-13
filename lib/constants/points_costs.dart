// lib/constants/points_costs.dart

class PointsCosts {
  // 🎯 Unlock Actions
  static const int unlockImage = 100; // cost to view a locked photo
  static const int unlockChat = 200; // cost to start chat with a new user
  static const int videoCall = 800;  // cost to start a video call
  static const int bypassCooldown = 50; // cost to bypass time/message cooldowns

  // 💰 Subscription Rewards
  // Subscribers automatically receive points each month
  static const int monthlySubscriptionPoints = 500;   // $9.99/month
  static const int yearlySubscriptionPoints = 1500;   // $89.99/year (~25% discount)
  static const double yearlySubscriptionPrice = 89.99; // yearly plan cost (USD)
  static const double monthlySubscriptionPrice = 9.99; // monthly plan cost (USD)

  // 💵 One-Time Purchase
  static const int oneTimePurchasePoints = 1000; // $14.99 gives 1000 total points
  static const double oneTimePurchasePrice = 14.99; // one-time purchase cost (USD)

  // 🎲 Game & Challenge Rewards
  static const int dailyDiceReward = 6;    // max points earned per roll
  static const int challengeCompletion = 25; // reward for completing a challenge

  // 🧾 Conversion rate helper (optional)
  // Used for displaying "approximate dollar value" in UI
  static const double pointsPerDollar = oneTimePurchasePoints / oneTimePurchasePrice; // ≈ 66.7 pts per $1

  // 📈 Helper Methods (optional)
  static double getDollarValue(int points) {
    return points / pointsPerDollar;
  }

  static double getMonthlyEquivalentOfYearly() {
    return yearlySubscriptionPrice / 12;
  }
}
