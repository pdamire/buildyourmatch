import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge.dart';
import 'supabase_client.dart';

class ChallengeService {
  final SupabaseClient _c = supa;

  Future<List<Challenge>> today() async {
    final res = await _c
        .from('challenges')
        .select('*')
        .eq('active', true)
        .lte('level', 2)
        .order('created_at', ascending: false)
        .limit(5);

    // Supabase returns a dynamic List — cast it safely.
    final List data = res as List;
    return data.map((m) => Challenge.fromMap(m as Map<String, 
dynamic>)).toList();
  }
}

