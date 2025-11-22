import 'package:supabase_flutter/supabase_flutter.dart';

class AiCoachService {
  final SupabaseClient client;

  AiCoachService(this.client);

  Future<String> askCoach({
    required String userId,
    required String question,
  }) async {
    final res = await client.functions.invoke(
      'ai-coach',
      body: {
        'user_id': userId,
        'question': question,
      },
    );

    return res.data['answer'] as String;
  }
}
