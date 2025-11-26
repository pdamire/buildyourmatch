import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;
import 'services/revenuecat_purchase.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
// ignore: unused_import
import 'data/supabase_client.dart';
import 'features/auth/auth_gate.dart';
import 'features/home/home_page.dart';
import 'features/challenges/challenge_page.dart';
import 'features/progress/progress_page.dart';
import 'features/coach/coach_page.dart';
import 'features/match/matches_page.dart';
import 'features/chat/chat_page.dart';
import 'features/store/points_store.dart';
import 'features/admin/admin_page.dart';
import 'models/challenge.dart';
import 'services/points_service.dart';
import 'services/daily_dice_service.dart';
import 'services/challenge_service.dart';
import 'services/match_service.dart';

// These read from Codemagic Environment Variables
const rcPublicSdkKeyIOS = String.fromEnvironment('RC_PUBLIC_SDK_KEY');
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

final _router = GoRouter(
  // ✅ START APP AT AUTH GATE
  initialLocation: '/gate',
  routes: [
    GoRoute(path: '/gate', builder: (_, __) => const AuthGate()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
    GoRoute(path: '/progress', builder: (_, __) => const ProgressPage()),
    GoRoute(path: '/coach', builder: (_, __) => const CoachPage()),
    GoRoute(path: '/match', builder: (_, __) => const MatchesPage()),
    GoRoute(path: '/chat', builder: (_, __) => const ChatPage()),
    GoRoute(path: '/store', builder: (_, __) => const PointsStorePage()),
    GoRoute(path: '/admin', builder: (_, __) => const AdminPage()),
    GoRoute(
      path: '/challenge',
      builder: (context, state) {
        final c = state.extra as Challenge;
        return ChallengePage(challenge: c);
      },
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase using environment variables
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // 2. Initialize your user in the database (optional)
  final client = Supabase.instance.client;
  // await UserBootstrapService(client).ensureUserInitialized();

  // 3. Initialize RevenueCat using the environment key
  await RevenueCatPurchase.setup(rcPublicSdkKeyIOS);

  // 4. Launch the app
  runApp(const BYMApp());
}

class BYMApp extends StatelessWidget {
  const BYMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Build Your Match',
      theme: buildAppTheme(),
      darkTheme: buildAppThemeDark(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('fa'),
        Locale('he'),
        Locale('ar'),
        Locale('fr'),
        Locale('zh'),
      ],
    );
  }
}
