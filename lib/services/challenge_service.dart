import 'package:supabase_flutter/supabase_flutter.dart';
import 'points_service.dart';

class ChallengeService {
  final SupabaseClient client;
  final PointsService pointsService;

  ChallengeService(this.client, this.pointsService);

  // DAILY LIMIT: max 20 answers per day per user
  static const int dailyQuestionLimit = 20;

  Future<int> _getTodayAnswerCount(String userId) async {
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);

    final res = await client
        .from('user_answers')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('user_id', userId)
        .gte('created_at', '$today 00:00:00+00')
        .lte('created_at', '$today 23:59:59+00');

    // Supabase count lives in response.count in Dart client, but here
    // we can just use length as an approximation if count is null.
    final list = res as List;
    return list.length;
  }

  Future<void> _ensureCanAnswer(String userId) async {
    final count = await _getTodayAnswerCount(userId);
    if (count >= dailyQuestionLimit) {
      throw Exception(
        'Daily limit reached. You can answer up to $dailyQuestionLimit questions per day.',
      );
    }
  }

  // OPEN / WRITTEN QUESTIONS (10 pts)
  Future<void> completeOpenQuestion({
    required String userId,
    required int questionId,
    required String answerText,
  }) async {
    await _ensureCanAnswer(userId);

    await client.from('user_answers').insert({
      'user_id': userId,
      'question_id': questionId,
      'answer_text': answerText,
    });

    await pointsService.awardPoints(
      userId: userId,
      amount: 10,
      reason: 'open_question_completed',
      meta: {'question_id': questionId},
    );
  }

  // MULTIPLE CHOICE (8 pts)
  Future<void> completeMultipleChoice({
    required String userId,
    required int questionId,
    required String chosenOption,
  }) async {
    await _ensureCanAnswer(userId);

    await client.from('user_answers').insert({
      'user_id': userId,
      'question_id': questionId,
      'answer_text': chosenOption,
    });

    await pointsService.awardPoints(
      userId: userId,
      amount: 8,
      reason: 'mcq_completed',
      meta: {'question_id': questionId},
    );
  }

  // TODAY'S STANDARD CHALLENGES (non-crossword)
  Future<List<Map<String, dynamic>>> getTodayChallenges(String userId) async {
    final answered = await client
        .from('user_answers')
        .select('question_id')
        .eq('user_id', userId);

    final answeredIds = (answered as List)
        .map((e) => e['question_id'] as int)
        .toList(growable: false);

    var query = client
        .from('questions')
        .select()
        .neq('type', 'crossword') // keep crossword separate
        .limit(20);

    if (answeredIds.isNotEmpty) {
      query = query.not('id', 'in', answeredIds);
    }

    final res = await query;
    return List<Map<String, dynamic>>.from(res as List);
  }

  // ---------- CROSSWORD SUPPORT ----------

  Future<Map<String, dynamic>?> getTodayCrossword() async {
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);

    final puzzle = await client
        .from('relationship_crosswords')
        .select()
        .eq('puzzle_date', today)
        .maybeSingle();

    if (puzzle == null) return null;

    final clues = await client
        .from('relationship_crossword_clues')
        .select()
        .eq('crossword_id', puzzle['id'])
        .order('clue_number', ascending: true);

    return {
      'puzzle': puzzle,
      'clues': List<Map<String, dynamic>>.from(clues as List),
    };
  }

  /// Check crossword answers.
  /// `answers` map: clueId -> userAnswer (string)
  /// Returns number of correct answers.
  Future<int> completeCrossword({
    required String userId,
    required int crosswordId,
    required Map<int, String> answers,
  }) async {
    await _ensureCanAnswer(userId);

    final res = await client
        .from('relationship_crossword_clues')
        .select('id, answer')
        .eq('crossword_id', crosswordId);

    final clues = List<Map<String, dynamic>>.from(res as List);

    int correctCount = 0;

    for (final clue in clues) {
      final id = clue['id'] as int;
      final correct = (clue['answer'] as String).trim().toUpperCase();
      final userAnswer = (answers[id] ?? '').trim().toUpperCase();
      if (userAnswer.isNotEmpty && userAnswer == correct) {
        correctCount++;
      }

      // Store each answer attempt
      await client.from('user_answers').insert({
        'user_id': userId,
        'question_id': id, // reuse id as 'question' id for crossword clues
        'answer_text': userAnswer,
      });
    }

    if (correctCount > 0) {
      final points = correctCount * 5; // 5 pts per correct clue
      await pointsService.awardPoints(
        userId: userId,
        amount: points,
        reason: 'crossword_completed',
        meta: {
          'crossword_id': crosswordId,
          'correct': correctCount,
        },
      );
    }

    return correctCount;
  }
}
