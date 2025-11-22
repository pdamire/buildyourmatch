import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:buildyourmatch_final_starter_2/services/points_service.dart';
import 'package:buildyourmatch_final_starter_2/services/challenge_service.dart';

class CrosswordScreen extends StatefulWidget {
  const CrosswordScreen({super.key});

  @override
  State<CrosswordScreen> createState() => _CrosswordScreenState();
}

class _CrosswordScreenState extends State<CrosswordScreen> {
  late final SupabaseClient _client;
  late final PointsService _pointsService;
  late final ChallengeService _challengeService;

  String? _userId;
  int? _balance;

  Map<String, dynamic>? _puzzle;
  List<Map<String, dynamic>> _clues = [];
  final Map<int, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _pointsService = PointsService(_client);
    _challengeService = ChallengeService(_client, _pointsService);
    _userId = _client.auth.currentUser?.id;
    _loadData();
  }

  Future<void> _loadData() async {
    if (_userId == null) return;
    final b = await _pointsService.getBalance(_userId!);
    final data = await _challengeService.getTodayCrossword();

    if (!mounted) return;
    setState(() {
      _balance = b;
      _puzzle = data?['puzzle'] as Map<String, dynamic>?;
      _clues = (data?['clues'] as List<Map<String, dynamic>>?) ?? [];
      _isLoading = false;
    });

    // create controllers
    for (final clue in _clues) {
      final id = clue['id'] as int;
      _controllers[id] = TextEditingController();
    }
  }

  Future<void> _submit() async {
    if (_userId == null || _puzzle == null) return;
    setState(() => _isSubmitting = true);

    try {
      final crosswordId = _puzzle!['id'] as int;

      final answers = <int, String>{};
      _controllers.forEach((id, controller) {
        answers[id] = controller.text;
      });

      final correctCount = await _challengeService.completeCrossword(
        userId: _userId!,
        crosswordId: crosswordId,
        answers: answers,
      );

      final newBalance = await _pointsService.getBalance(_userId!);

      if (!mounted) return;
      setState(() {
        _balance = newBalance;
      });

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Crossword checked'),
          content: Text(
            correctCount == 0
                ? 'No correct answers this time. Try again tomorrow!'
                : 'You got $correctCount correct. Nice work!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_puzzle?['title'] as String? ?? 'Daily Crossword'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Points: ${_balance ?? '…'}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _puzzle == null
              ? const Center(child: Text('No crossword available for today yet.'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Relationship crossword: type the word for each clue. '
                        'You earn 5 points per correct answer (up to the daily limit).',
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _clues.length,
                          itemBuilder: (context, index) {
                            final clue = _clues[index];
                            final id = clue['id'] as int;
                            final number = clue['clue_number'] as int;
                            final text = clue['clue_text'] as String;
                            final controller = _controllers[id]!;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$number. $text',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Your answer',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Check answers & earn points'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
