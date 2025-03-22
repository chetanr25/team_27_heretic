import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const String streakKey = 'quiz_streak';
  static const String totalQuestionsKey = 'total_questions';
  static const String correctAnswersKey = 'correct_answers';
  static const String lastQuizDateKey = 'last_quiz_date';

  static Future<void> updateStreak(int score, int totalQuestions) async {
    final prefs = await SharedPreferences.getInstance();
    final lastQuizDate = prefs.getString(lastQuizDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Update total stats
    final totalCorrect = (prefs.getInt(correctAnswersKey) ?? 0) + score;
    final totalQuestions = prefs.getInt(totalQuestionsKey) ?? 0 + 5;
    await prefs.setInt(correctAnswersKey, totalCorrect);
    await prefs.setInt(totalQuestionsKey, totalQuestions);

    // Update streak
    if (lastQuizDate != today) {
      if (score > totalQuestions / 2) {
        final currentStreak = prefs.getInt(streakKey) ?? 0;
        await prefs.setInt(streakKey, currentStreak + 1);
      } else {
        await prefs.setInt(streakKey, 0);
      }
      await prefs.setString(lastQuizDateKey, today);
    }
  }

  static Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final totalQuestions = prefs.getInt(totalQuestionsKey) ?? 0;
    final correctAnswers = prefs.getInt(correctAnswersKey) ?? 0;
    final accuracy =
        totalQuestions > 0
            ? ((correctAnswers / totalQuestions) * 100).toStringAsFixed(1)
            : '0';

    return {
      'streak': prefs.getInt(streakKey) ?? 0,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'accuracy': '$accuracy%',
    };
  }
}
