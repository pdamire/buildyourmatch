import 'package:build_your_match/features/progress/widgets/gm_progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../data/supabase_client.dart';
import '../../data/challenge_service.dart';
import '../../models/challenge.dart';
import 'daily_dice_card.dart';

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState()=>_HomePageState(); }
class _HomePageState extends State<HomePage> {
  late Future<List<Challenge>> fut;
  @override void initState(){ super.initState(); fut = ChallengeService().today(); }
  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Build Your Match'), actions: [
        IconButton(onPressed: ()=> context.push('/store'), icon: const Icon(Icons.bolt)),
        IconButton(onPressed: ()=> context.push('/admin'), icon: const Icon(Icons.admin_panel_settings)),
      ]),
      body: ListView(children:[
        Card(margin: const EdgeInsets.fromLTRB(16,16,16,8), child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children:[
            GmProgressRing(value: .3),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Text(
  'Grow first. Then meet.',
  style: Theme.of(context).textTheme.titleLarge,
),
              const SizedBox(height: 6),
              const Text('Streak: 3 days • XP: 75'),
              const SizedBox(height: 12),
              FilledButton(onPressed: ()=> context.push('/challenge'), child: const Text('Play a Mini-Game')),
            ])),
          ]),
        )),
        const DailyDiceCard(),
        const Padding(padding: EdgeInsets.fromLTRB(16,8,16,8), child: Text('Today’s Challenges', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20))),
        FutureBuilder<List<Challenge>>(future: fut, builder: (context, snap){
          final items = snap.data ?? [];
          return Column(children: items.map((c)=> Card(
            child: ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(c.title), subtitle: Text(c.promptText),
              trailing: const Icon(Icons.chevron_right),
              onTap: ()=> context.push('/challenge', extra: c),
            ),
          )).toList());
        }),
        const SizedBox(height: 24),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.stacked_line_chart_outlined), selectedIcon: Icon(Icons.stacked_line_chart), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.psychology_alt_outlined), selectedIcon: Icon(Icons.psychology_alt), label: 'Coach'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'Match'),
        ],
        onDestinationSelected: (i){ switch(i){ case 0: break; case 1: context.push('/progress'); break; case 2: context.push('/coach'); break; case 3: context.push('/match'); break; } },
      ),
    );
  }
}
