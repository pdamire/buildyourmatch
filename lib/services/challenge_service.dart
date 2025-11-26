// lib/services/challenge_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/challenge.dart';   // ✅ NEW
import 'package:supabase_flutter/supabase_flutter.dart';
import 'points_service.dart';

class ChallengeService {
  final SupabaseClient client;
  final PointsService pointsService;

  ChallengeService(this.client, this.pointsService);

  // DAILY LIMIT: max 20 "challenges" per day per user
  // A "challenge" can be:
  // - one open question
  // - one multiple choice question
  // - one crossword puzzle (whole puzzle counts as 1)
  static const int dailyQuestionLimit = 20;

  // MINIMUM "CORE" QUESTIONS REQUIRED TO ENTER MATCHING POOL
  static const int minQuestionsForMatching = 20;

  // -------------------------------------------------------------
  // INTERNAL: how many challenges this user has completed today
  // (open + mcq + crossword combined, logged in user_daily_challenges)
  // -------------------------------------------------------------
  Future<int> _getTodayAnswerCount(String userId) async {
    // Use UTC date like 'YYYY-MM-DD'
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);

    final res = await client
        .from('user_daily_challenges')
        .select('id')
        .eq('user_id', userId)
        .eq('challenge_date', today);

    final List<dynamic> rows = res as List<dynamic>;
    return rows.length; // each row = 1 challenge done today
  }

  Future<void> _ensureCanAnswer(String userId) async {
    final count = await _getTodayAnswerCount(userId);
    if (count >= dailyQuestionLimit) {
      throw Exception(
        'Daily limit reached. You can answer up to $dailyQuestionLimit questions per day.',
      );
    }
  }

  Future<void> _logDailyChallenge({
    required String userId,
    required String challengeType, // 'open', 'mcq', 'crossword'
    required int challengeId,
  }) async {
    await client.from('user_daily_challenges').insert({
      'user_id': userId,
      'challenge_type': challengeType,
      'challenge_id': challengeId,
      // challenge_date will default to "today" in UTC via SQL default
    });
  }

  // -------------------------------------------------------------
  // CORE QUESTION PROGRESS FOR MATCHING
  // -------------------------------------------------------------

  // Count how many "core" psychology questions this user has answered.
  // We mark those with is_core = true in user_answers.
  Future<int> _getCoreAnswerCount(String userId) async {
    final res = await client
        .from('user_answers')
        .select('id')
        .eq('user_id', userId)
        .eq('is_core', true);

    final List<dynamic> rows = res as List<dynamic>;
    return rows.length;
  }

  // Public helper: does this user have enough answers
  // to be included in the matching algorithm?
  Future<bool> hasCompletedInitialQuestionSet(String userId) async {
    final coreCount = await _getCoreAnswerCount(userId);
    return coreCount >= minQuestionsForMatching;
  }

  // -------------------------------------------------------------
  // OPEN / WRITTEN QUESTIONS (10 pts)
  // -------------------------------------------------------------
  Future<void> completeOpenQuestion({
    required String userId,
    required int questionId,
    required String answerText,
  }) async {
    // Check daily limit first
    await _ensureCanAnswer(userId);

    // Store the user's answer
    await client.from('user_answers').insert({
      'user_id': userId,
      'question_id': questionId,
      'answer_text': answerText,
      'is_core': true, // counts toward the initial 20 for matching
    });

    // Log this as one daily challenge
    await _logDailyChallenge(
      userId: userId,
      challengeType: 'open',
      challengeId: questionId,
    );

    // Award points (your original values)
    await pointsService.awardPoints(
      userId: userId,
      amount: 10,
      reason: 'open_question_completed',
      meta: {'question_id': questionId},
    );
  }

  // -------------------------------------------------------------
  // MULTIPLE CHOICE (8 pts)
  // -------------------------------------------------------------
  Future<void> completeMultipleChoice({
    required String userId,
    required int questionId,
    required String chosenOption,
  }) async {
    // Check daily limit first
    await _ensureCanAnswer(userId);

    // Store the user's answer
    await client.from('user_answers').insert({
      'user_id': userId,
      'question_id': questionId,
      'answer_text': chosenOption,
      'is_core': true, // counts toward the initial 20 for matching
    });

    // Log this as one daily challenge
    await _logDailyChallenge(
      userId: userId,
      challengeType: 'mcq',
      challengeId: questionId,
    );

    // Award points (your original values)
    await pointsService.awardPoints(
      userId: userId,
      amount: 8,
      reason: 'mcq_completed',
      meta: {'question_id': questionId},
    );
  }

  // -------------------------------------------------------------
  // TODAY'S STANDARD CHALLENGES (non-crossword)
  // -------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getTodayChallenges(
    String userId,
  ) async {
    // IDs this user has already answered (based on user_answers)
    final answered = await client
        .from('user_answers')
        .select('question_id')
        .eq('user_id', userId);

    final answeredIds = (answered as List<dynamic>)
        .map((e) => e['question_id'] as int)
        .toList(growable: false);

    // Fetch a bigger batch, then filter in Dart
    final raw = await client
        .from('questions')
        .select()
        .neq('type', 'crossword')
        .limit(100); // any number >= 20 is fine

    final all =
        List<Map<String, dynamic>>.from(raw as List<dynamic>);

    List<Map<String, dynamic>> filtered;
    if (answeredIds.isEmpty) {
      filtered = all;
    } else {
      filtered = all
          .where((row) => !answeredIds.contains(row['id'] as int))
          .toList();
    }

    // Only keep up to 20 candidates. The true per-day limit is enforced
    // by _ensureCanAnswer when they actually answer.
    filtered = filtered.take(20).toList();
    return filtered;
  }

  // -------------------------------------------------------------
  // CROSSWORD SUPPORT
  // -------------------------------------------------------------
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
      'clues': List<Map<String, dynamic>>.from(clues as List<dynamic>),
    };
  }

  /// Check crossword answers.
  /// `answers` map: clueId -> userAnswer (string)
  /// Returns number of correct answers.
  /// The entire crossword puzzle counts as ONE "challenge" toward the daily limit.
  /// NOTE: crossword answers do NOT count toward the initial 20 "core" questions.
  Future<int> completeCrossword({
    required String userId,
    required int crosswordId,
    required Map<int, String> answers,
  }) async {
    // Check daily limit (crossword counts as 1 challenge)
    await _ensureCanAnswer(userId);

    final res = await client
        .from('relationship_crossword_clues')
        .select('id, answer')
        .eq('crossword_id', crosswordId);

    final clues =
        List<Map<String, dynamic>>.from(res as List<dynamic>);

    int correctCount = 0;

    for (final clue in clues) {
      final id = clue['id'] as int;
      final correct =
          (clue['answer'] as String).trim().toUpperCase();
      final userAnswer =
          (answers[id] ?? '').trim().toUpperCase();

      if (userAnswer.isNotEmpty && userAnswer == correct) {
        correctCount++;
      }
    }

    // Store each answer attempt
    for (final clue in clues) {
      final id = clue['id'] as int;
      final userAnswer = (answers[id] ?? '').trim();

      await client.from('user_answers').insert({
        'user_id': userId,
        'question_id': id, // reuse id as "question" id for crossword clues
        'answer_text': userAnswer,
        // is_core left as default false; crossword does NOT count toward initial 20
      });
    }

    // Log this as one daily challenge (the whole crossword)
    await _logDailyChallenge(
      userId: userId,
      challengeType: 'crossword',
      challengeId: crosswordId,
    );

    if (correctCount > 0) {
      final points = correctCount * 5; // your original value
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
    // -------------------------------------------------------------
  // DAILY CHALLENGES FOR HOME PAGE (returns List<Challenge>)
  // -------------------------------------------------------------
  Future<List<Challenge>> fetchDailyChallenges() async {
    try {
      // For now, this assumes you have a `challenges` table that matches
      // your Challenge.fromMap(...) constructor. You can adjust the
      // table name / fields later if needed.
      final res = await client
          .from('challenges')
          .select()
          .order('id', ascending: true)
          .limit(20);

      if (res is List) {
        return res
            .map((row) => Challenge.fromMap(row as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      // If anything fails, return empty list so UI won't crash.
      // You can show a SnackBar in the UI if you want to surface the error.
      return [];
    }
  }
}
