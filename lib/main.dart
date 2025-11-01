import 'dart:io' show Platform;
import 'services/revenuecat_purchase.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
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

final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/gate', builder: (_, __) => const AuthGate()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
    GoRoute(path: '/progress', builder: (_, __) => const ProgressPage()),
    GoRoute(path: '/coach', builder: (_, __) => const CoachPage()),
    GoRoute(path: '/match', builder: (_, __) => const MatchesPage()),
    GoRoute(path: '/chat', builder: (_, __) => const ChatPage()),
    GoRoute(path: '/store', builder: (_, __) => const PointsStorePage()),
    GoRoute(path: '/admin', builder: (_, __) => const AdminPage()),
    GoRoute(path: '/challenge', builder: (context, state) {
      final c = state.extra as Challenge?;
      return ChallengePage(challenge: c);
    }),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Replace this with your actual PUBLIC SDK KEY from RevenueCat (iOS)
  const rcPublicSdkKeyIOS = 'YOUR_IOS_PUBLIC_SDK_KEY_HERE';

  await RevenueCatPurchase.setup(
    Platform.isIOS ? rcPublicSdkKeyIOS : 'unused',
  );

  runApp(const MyApp());
}


class BYMApp extends StatelessWidget {
  const BYMApp({super.key});
  @override Widget build(BuildContext context){
    return MaterialApp.router(
      title: 'Build Your Match',
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), Locale('es'), Locale('fa'), Locale('he'), Locale('ar'), Locale('fr'), Locale('zh'),
      ],
    );
  }
}
