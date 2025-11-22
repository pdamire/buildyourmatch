import 'points_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PointsService {
  final SupabaseClient client;

  PointsService(this.client);

  /// Get the current balance for this user.
  /// If the user doesn't have a row yet in `user_points`,
  /// create one with balance = 0 and return 0.
  Future<int> getBalance(String userId) async {
    final res = await client
        .from('user_points')
        .select('balance')
        .eq('user_id', userId)
        .maybeSingle();

    if (res == null) {
      // First time we see this user, create a row.
      await client.from('user_points').insert({
        'user_id': userId,
        'balance': 0,
      });
      return 0;
    }

    return (res['balance'] as int?) ?? 0;
  }

  /// Internal helper used by awardPoints and spendPoints.
  ///
  /// 1) Insert a row into `points_transactions`
  /// 2) Call the `adjust_user_points` RPC in Supabase
  ///    which updates `user_points.balance` and returns `new_balance`.
  Future<int> _changePoints({
    required String userId,
    required int amount,
    required String reason,
    Map<String, dynamic>? meta,
  }) async {
    // Record the transaction
    await client.from('points_transactions').insert({
      'user_id': userId,
      'amount': amount,
      'reason': reason,
      'meta': meta ?? <String, dynamic>{},
    });

    // Call the RPC to adjust the balance
    final res = await client
        .rpc('adjust_user_points', params: {
          'p_user_id': userId,
          'p_amount': amount,
        })
        .single();

    return res['new_balance'] as int;
  }

  /// Give points to the user (positive amount).
  Future<int> awardPoints({
    required String userId,
    required int amount,
    required String reason,
    Map<String, dynamic>? meta,
  }) {
    return _changePoints(
      userId: userId,
      amount: amount,
      reason: reason,
      meta: meta,
    );
  }

  /// Spend points for the user (amount is subtracted from balance).
  Future<int> spendPoints({
    required String userId,
    required int amount,
    required String reason,
    Map<String, dynamic>? meta,
  }) {
    return _changePoints(
      userId: userId,
      amount: -amount,
      reason: reason,
      meta: meta,
    );
  }
}
