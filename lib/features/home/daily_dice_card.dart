import 'package:flutter/material.dart';
import '../../data/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class DailyDiceCard extends StatefulWidget {
  const DailyDiceCard({super.key});

  @override
  State<DailyDiceCard> createState() => _DailyDiceCardState();
}

class _DailyDiceCardState extends State<DailyDiceCard> {
  final supa = Supabase.instance.client;

  bool _busy = false;
  int? last;
  int left = 3;

  /// Sync rolls left from database
  Future<void> _syncLeft() async {
    final uid = supa.auth.currentUser?.id;
    if (uid == null) return;

    final today =
        DateTime.now().toIso8601String().split('T').first; // YYYY-MM-DD

    final row = await supa
        .from('daily_checks')
        .select()
        .eq('user_id', uid)
        .eq('date', today)
        .maybeSingle();

    final used = (row?['rolls'] ?? 0) as int;
    setState(() => left = (3 - used).clamp(0, 3));
  }

  @override
  void initState() {
    super.initState();
    _syncLeft();
  }

  /// Roll the dice
  Future<void> _roll() async {
    setState(() => _busy = true);

    try {
      final uid = supa.auth.currentUser!.id;

      final pts = await supa.rpc('roll_daily_dice',
          params: {'uid': uid}) as int?;

      setState(() => last = pts ?? 0);
      await _syncLeft();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Dice – up to 3 rolls'),
            const SizedBox(height: 6),
            Text('Earn 1–6 points per roll. Rolls left: $left'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: (_busy || left == 0) ? null : _roll,
              icon: const Icon(Icons.casino),
              label: Text(_busy ? 'Rolling...' : 'Roll now'),
            ),
            if (last != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  left == 0
                      ? 'No rolls left today.'
                      : 'You gained +$last pts!',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
