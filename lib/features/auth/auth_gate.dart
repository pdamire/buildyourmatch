import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/home_page.dart';
import 'email_auth_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    // ✅ If there is NO logged-in user → go to email/password auth page
    if (session == null) {
      return EmailAuthPage();
    }

    // ✅ If user is logged in → go straight to HomePage
    return HomePage();
  }
}
