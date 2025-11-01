import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/supabase_client.dart';
import '../../models/challenge.dart';

class ChallengePage extends StatefulWidget {
  final Challenge? challenge; const ChallengePage({super.key, this.challenge});
  @override State<ChallengePage> createState()=>_ChallengePageState();
}
class _ChallengePageState extends State<ChallengePage> {
  final ctrl = TextEditingController(); bool busy=false;
  Future<void> _submit() async {
    setState(()=>busy=true);
    try{
      final user = supa.auth.currentUser!;
      final xp = widget.challenge?.xpValue ?? 10;
      await supa.from('game_sessions').insert({'user_id': user.id, 'game_type': widget.challenge?.gameType ?? 'Reflection', 'score': xp, 'deep_choice': ctrl.text});
      final row = await supa.from('users').select('growth_xp').eq('id', user.id).maybeSingle();
      final cur = (row?['growth_xp'] ?? 0) as int;
      await supa.from('users').update({'growth_xp': cur + xp}).eq('id', user.id);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Completed +$xp XP!'))); context.go('/home'); }
    } finally { if(mounted) setState(()=>busy=false); }
  }
  @override Widget build(BuildContext context){
    final c = widget.challenge;
    return Scaffold(appBar: AppBar(title: Text(c?.title ?? 'Challenge')), body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text(c?.promptText ?? 'Write a truth about yourself.'),
        const SizedBox(height: 12),
        TextField(controller: ctrl, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText:'Your reflection')),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: busy?null:_submit, icon: const Icon(Icons.check), label: Text(busy?'Submitting…':'Complete Challenge')),
      ]),
    ));
  }
}
