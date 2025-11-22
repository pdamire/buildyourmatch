import 'daily_dice_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../../data/supabase_client.dart';
import '../../auth/auth_gate.dart';
import '../../services/points_service.dart';
import '../../services/daily_dice_service.dart';
import '../../services/challenge_service.dart';
import '../../services/match_service.dart';
import '../../models/challenge.dart';
import '../progress/widgets/gm_progress_ring.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SupabaseClient _client;
  late final PointsService _pointsService;
  late final DailyDiceService _dailyDiceService;
  late final ChallengeService _challengeService;
  late final MatchService _matchService;

  String? _userId;
  int? _balance;

  /// Today’s challenges future
  late Future<List<Challenge>> fut;

  @override
  void initState() {
    super.initState();

    // Supabase client
    _client = Supabase.instance.client;

    // Services
    _pointsService = PointsService(_client);
    _dailyDiceService = DailyDiceService(_client, _pointsService);
    _challengeService = ChallengeService(_client, _pointsService);
    _matchService = MatchService(_client);

    // Load today’s challenges
    fut = _challengeService.today();

    // Load balance
    _userId = _client.auth.currentUser?.id;
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    if (_userId == null) return;
    final b = await _pointsService.getBalance(_userId!);
    if (!mounted) return;
    setState(() => _balance = b); // ✅ CORRECT: setState, not setStateO
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Build Your Match'),
        actions: [
          IconButton(
            onPressed: () => context.push('/store'),
            icon: const Icon(Icons.bolt),
          ),
          IconButton(
            onPressed: () => context.push('/admin'),
            icon: const Icon(Icons.admin_panel_settings),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Header card
          Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const GmProgressRing(value: 0.3),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grow first. Then meet.',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Streak: 3 days   XP: 75',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.push('/challenge'),
                          child: const Text('Play a Mini-Game'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Daily dice
          const DailyDiceCard(),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              "Today's Challenges",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),

          // Today's challenges list
          FutureBuilder<List<Challenge>>(
            future: fut,
            builder: (context, snap) {
              final items = snap.data ?? [];

              return Column(
                children: items.map((c) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.favorite),
                      title: Text(c.title),
                      subtitle: Text(c.promptText),
                      trailing: const Icon(Icons.chevron_right, color: Colors.pink),
                      onTap: () => context.push('/challenge', extra: c),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              break;
            case 1:
              context.push('/progress');
              break;
            case 2:
              context.push('/coach');
              break;
            case 3:
              context.push('/match');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.stacked_line_chart_outlined),
            selectedIcon: Icon(Icons.stacked_line_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_alt_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Match',
          ),
        ],
      ),
    );
  }
}
