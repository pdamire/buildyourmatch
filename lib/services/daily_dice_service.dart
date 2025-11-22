import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'points_service.dart';

class DailyDiceService {
  final SupabaseClient client;
  final PointsService pointsService;
  final Random _rng = Random();

  static const int maxRollsPerDay = 3;

  DailyDiceService(this.client, this.pointsService);

  Future<int> getRemainingRolls(String userId) async {
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);

    final res = await client
        .from('daily_dice')
        .select('rolls_used')
        .eq('user_id', userId)
        .eq('date', today)
        .maybeSingle();

    if (res == null) return maxRollsPerDay;
    final used = res['rolls_used'] as int;
    return maxRollsPerDay - used;
  }

  Future<Map<String, dynamic>> rollDice(String userId) async {
    final remaining = await getRemainingRolls(userId);
    if (remaining <= 0) {
      throw Exception('No rolls left today');
    }

    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final reward = 5 + _rng.nextInt(16); // 5..20

    await client.from('daily_dice').upsert({
      'user_id': userId,
      'date': today,
      'rolls_used': 3 - (remaining - 1),
    });

    final newBalance = await pointsService.awardPoints(
      userId: userId,
      amount: reward,
      reason: 'dice_roll',
      meta: {'date': today},
    );

    return {
      'reward': reward,
      'newBalance': newBalance,
      'remainingRolls': remaining - 1,
    };
  }
}
