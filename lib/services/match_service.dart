import 'package:supabase_flutter/supabase_flutter.dart';

class MatchService {
  final SupabaseClient client;

  MatchService(this.client);

  Future<List<Map<String, dynamic>>> getSuggestedMatches(String userId) async {
    final me = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    final myGender = me['gender'] as String?;
    final myLanguages = List<String>.from(me['languages'] ?? []);
    final seeking = List<String>.from(me['seeking_gender'] ?? []);

    final res = await client
        .from('profiles')
        .select()
        .neq('id', userId)
        .contains('seeking_gender', [myGender]) // they are open to me
        .overlaps('languages', myLanguages)     // share at least one language
        .limit(20);

    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> startMatch({
    required String fromUserId,
    required String toUserId,
  }) async {
    // You can hook PointsService.spendPoints here later if you want.
    final match = await client
        .from('matches')
        .insert({
          'user_a': fromUserId,
          'user_b': toUserId,
          'status': 'active',
        })
        .select()
        .single();

    await client.from('chat_rooms').insert({
      'match_id': match['id'],
      'user_a': fromUserId,
      'user_b': toUserId,
    });
  }

  Future<void> endMatch(String matchId) async {
    await client
        .from('matches')
        .update({
          'status': 'ended',
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', matchId);
  }
}
