import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: const String.fromEnvironment('https://ynphjnqgjvgjnrxkgtui.supabase.co'),
    anonKey: const String.fromEnvironment('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlucGhqbnFnanZnam5yeGtndHVpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEzOTI4NjQsImV4cCI6MjA3Njk2ODg2NH0._3ibKx47lgbKuskGPQQEZkt_7T1J2M1MuBOdEB_xj5A'),
  );
}
final supa = Supabase.instance.client;
