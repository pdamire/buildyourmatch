import 'package:flutter/material.dart';
import '../../data/supabase_client.dart';

class AdminPage extends StatefulWidget { const AdminPage({super.key}); @override State<AdminPage> createState()=>_AdminPageState(); }
class _AdminPageState extends State<AdminPage> {
  bool rerun=false; String log='';
  int balance=0;

  @override void initState(){ super.initState(); _load(); }
  Future<void> _load() async {
    final uid = supa.auth.currentUser?.id; if (uid==null) return;
   final row = await supa.from('user_points').select().eq('user_id', uid).maybeSingle();
    setState(()=> balance = (row?['available_points'] ?? 0) as int);
  }

  Future<void> _invokeMatchBuilder() async {
    try {
      final r = await supa.functions.invoke('match_builder', body: {'force': rerun});
      setState(()=> log = 'Triggered: ${r.data}');
    } catch (e) {
      setState(()=> log = 'Error: $e');
    }
  }

  @override Widget build(BuildContext context){
    return Scaffold(appBar: AppBar(title: const Text('Admin Tools')), body: ListView(
      padding: const EdgeInsets.all(16),
      children:[
        Text('Your points: $balance'),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Rerun builder aggressively (testing)'), value: rerun,
          onChanged: (v)=> setState(()=> rerun=v),
        ),
        FilledButton.icon(onPressed: _invokeMatchBuilder, icon: const Icon(Icons.refresh), label: const Text('Run Match Builder')),
        const SizedBox(height: 12),
        if (log.isNotEmpty) SelectableText(log),
        const Divider(),
        const Text('Tip: Protect this page with `is_admin` flag in Supabase users table.'),
      ],
    ));
  }
}
