class Challenge {
  final int id; final String title; final String promptText; final String category; final int xpValue; final String gameType;
  Challenge({required this.id, required this.title, required this.promptText, required this.category, required this.xpValue, required this.gameType});
  factory Challenge.fromMap(Map<String,dynamic> m)=> Challenge(
    id:m['id'] as int, title:m['title'] as String, promptText:m['prompt_text'] as String, category:m['category'] as String,
    xpValue:(m['xp_value'] as num).toInt(), gameType:m['game_type'] as String);
}
