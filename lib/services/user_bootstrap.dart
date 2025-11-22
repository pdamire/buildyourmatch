import 'package:supabase_flutter/supabase_flutter.dart';

class UserBootstrapService {
  final SupabaseClient client;

  UserBootstrapService(this.client);

  Future<void> ensureUserInitialized() async {
    final user = client.auth.currentUser;
    if (user == null) return;

    // 1) Ensure row in public.users
    await client.from('users').upsert({
      'id': user.id,
      'locale': 'en',
      // 'is_admin': false, // optional, default false
    });

    // 2) Ensure row in public.user_points
    await client.from('user_points').upsert({
      'user_id': user.id,
      // balance, total_earned, total_purchased default to 0
    });
  }
}
