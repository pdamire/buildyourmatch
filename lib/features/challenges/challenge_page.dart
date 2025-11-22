// lib/features/challenges/challenge_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/supabase_client.dart';
import '../../models/challenge.dart';

class ChallengePage extends StatefulWidget {
  final Challenge challenge;

  const ChallengePage({
    super.key,
    required this.challenge,
  });

  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final user = supa.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to complete challenges.'),
          ),
        );
        return;
      }

      final int xp = widget.challenge.xpValue ?? 10;

      // Store this game session
      await supa.from('game_sessions').insert({
        'user_id': user.id,
        'game_type': widget.challenge.gameType ?? 'Reflection',
        'score': xp,
        'deep_choice': _controller.text.trim(),
      });

      // Get current growth_xp
      final row = await supa
          .from('users')
          .select('growth_xp')
          .eq('id', user.id)
          .maybeSingle();

      final int currentXp = (row?['growth_xp'] ?? 0) as int;

      // Update growth_xp
      await supa
          .from('users')
          .update({'growth_xp': currentXp + xp})
          .eq('id', user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completed +$xp XP!')),
      );

      // Go back home
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.title ?? 'Challenge'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.promptText ?? 'Write a truth about yourself.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Your reflection',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_busy ? 'Submitting…' : 'Complete Challenge'),
            ),
          ],
        ),
      ),
    );
  }
}
