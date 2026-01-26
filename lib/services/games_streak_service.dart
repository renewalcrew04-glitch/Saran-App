import 'package:shared_preferences/shared_preferences.dart';

class GamesStreakService {
  static const _keyLastPlayedDate = "games_last_played_date";
  static const _keyStreak = "games_streak";
  static const _keyHistory = "games_history";

  static Future<GamesStreakResult> recordPlay({
    required String gameId,
    required String gameTitle,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastStr = prefs.getString(_keyLastPlayedDate);
    DateTime? lastDay;

    if (lastStr != null) {
      final parsed = DateTime.tryParse(lastStr);
      if (parsed != null) {
        lastDay = DateTime(parsed.year, parsed.month, parsed.day);
      }
    }

    int streak = prefs.getInt(_keyStreak) ?? 0;

    if (lastDay == null) {
      streak = 1;
    } else {
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        // same day -> no change
      } else if (diff == 1) {
        streak += 1;
      } else {
        streak = 1;
      }
    }

    await prefs.setInt(_keyStreak, streak);
    await prefs.setString(_keyLastPlayedDate, today.toIso8601String());

    final history = prefs.getStringList(_keyHistory) ?? [];
    final time = DateTime.now().toIso8601String();
    history.insert(0, "$time|$gameId|$gameTitle");
    if (history.length > 50) history.removeRange(50, history.length);
    await prefs.setStringList(_keyHistory, history);

    return GamesStreakResult(
      streak: streak,
      lastPlayedDay: today,
      history: history,
    );
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreak) ?? 0;
  }

  static Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyHistory) ?? [];
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }
}

class GamesStreakResult {
  final int streak;
  final DateTime lastPlayedDay;
  final List<String> history;

  GamesStreakResult({
    required this.streak,
    required this.lastPlayedDay,
    required this.history,
  });
}
