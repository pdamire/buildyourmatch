import 'package:supabase_flutter/supabase_flutter.dart';

class PointsService {
  final SupabaseClient client;

  PointsService(this.client);

  Future<int> getBalance(String userId) async {
    final res = await client
        .from('user_points')
        .select('balance')
        .eq('user_id', userId)
        .maybeSingle();

    if (res == null) {
      await client.from('user_points').insert({
        'user_id': userId,
        'balance': 0,
      });
      return 0;
    }

    return (res['balance'] as int?) ?? 0;
  }

  Future<int> _changePoints({
    required String userId,
    required int amount,
    required String reason,
    Map<String, dynamic>? meta,
  }) async {
    await client.from('points_transactions').insert({
      'user_id': userId,
      'amount': amount,
      'reason': reason,
      'meta': meta ?? <String, dynamic>{},
    });

    final res = await client
        .rpc('adjust_user_points', params: {
          'p_user_id': userId,
          'p_amount': amount,
        })
        .single();

    return res['new_balance'] as int;
  }

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
