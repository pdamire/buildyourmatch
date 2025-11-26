import 'package:supabase_flutter/supabase_flutter.dart';

class MatchService {
  final SupabaseClient client;

  MatchService(this.client);

  // Minimum number of core psychology questions required
  // before a user can enter the matching pool.
  static const int minCoreQuestionsForMatching = 20;

  // -------------------------------------------------------------
  // INTERNAL: core-question progress
  // -------------------------------------------------------------
  Future<int> _getCoreAnswerCount(String userId) async {
    final res = await client
        .from('user_answers')
        .select('id')
        .eq('user_id', userId)
        .eq('is_core', true);

    final List<dynamic> rows = res as List<dynamic>;
    return rows.length;
  }

  Future<bool> _hasMinimumCoreAnswers(String userId) async {
    final count = await _getCoreAnswerCount(userId);
    return count >= minCoreQuestionsForMatching;
  }

  // -------------------------------------------------------------
  // SUGGESTED MATCHES
  // Only returns matches if *current user* has >= 20 core answers.
  // Also tries to only suggest users who have >= 20 core answers too.
  // -------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getSuggestedMatches(String userId) async {
    // 1) Make sure *this* user is eligible for matching.
    final meReady = await _hasMinimumCoreAnswers(userId);
    if (!meReady) {
      // You can also choose to return [] instead of throwing,
      // but throwing makes it clear the user isn't ready yet.
      throw Exception(
        'You need to answer at least $minCoreQuestionsForMatching questions before we can match you.',
      );
    }

    // 2) Load this user's profile preferences
    final me = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    final myGender = me['gender'] as String?;
    final myLanguages = List<String>.from(me['languages'] ?? []);
    final seeking = List<String>.from(me['seeking_gender'] ?? []);

    // 3) Get candidate profiles who:
    //    - are not me
    //    - are open to my gender
    //    - share at least one language
    //    (optional) whose gender is in my "seeking" list if that is configured
    var query = client
        .from('profiles')
        .select()
        .neq('id', userId)
        .contains('seeking_gender', [myGender]) // they are open to me
        .overlaps('languages', myLanguages);    // share at least one language

    // If I have a non-empty seeking list, only consider those genders
    if (seeking.isNotEmpty) {
      // assumes `gender` is a single value, not an array
      query = query.in_('gender', seeking);
    }

    final res = await query.limit(50); // fetch a bigger pool, we’ll filter

    final List<Map<String, dynamic>> allCandidates =
        List<Map<String, dynamic>>.from(res as List<dynamic>);

    // 4) Filter in Dart: only keep candidates who ALSO have >= 20 core answers
    final List<Map<String, dynamic>> qualified = [];
    for (final candidate in allCandidates) {
      final otherUserId = candidate['id'] as String;

      final otherReady = await _hasMinimumCoreAnswers(otherUserId);
      if (!otherReady) continue;

      qualified.add(candidate);

      if (qualified.length >= 20) {
        break; // cap at 20 suggested matches
      }
    }

    return qualified;
  }

  // -------------------------------------------------------------
  // START / END MATCH
  // Enforce that both users have completed the initial question set.
  // -------------------------------------------------------------
  Future<void> startMatch({
    required String fromUserId,
    required String toUserId,
  }) async {
    // Ensure BOTH users are eligible (>= 20 core answers)
    final fromReady = await _hasMinimumCoreAnswers(fromUserId);
    final toReady = await _hasMinimumCoreAnswers(toUserId);

    if (!fromReady || !toReady) {
      throw Exception(
        'Both users must answer at least $minCoreQuestionsForMatching questions before starting a match.',
      );
    }

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
