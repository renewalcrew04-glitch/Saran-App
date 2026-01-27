import 'package:shared_preferences/shared_preferences.dart';

class WellnessStreakService {
  static const _keyLastDoneDate = "wellness_last_done_date";
  static const _keyStreak = "wellness_streak";
  static const _keyHistory = "wellness_history";

  static String _todayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  static Future<void> markCompleted({
    required String activityId,
    required String activityTitle,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final today = _todayKey();

    final lastDone = prefs.getString(_keyLastDoneDate);
    int streak = prefs.getInt(_keyStreak) ?? 0;

    if (lastDone == null) {
      streak = 1;
    } else {
      final lastParts = lastDone.split("-");
      final todayParts = today.split("-");

      DateTime? lastDate;
      DateTime? todayDate;

      if (lastParts.length == 3 && todayParts.length == 3) {
        lastDate = DateTime(
          int.parse(lastParts[0]),
          int.parse(lastParts[1]),
          int.parse(lastParts[2]),
        );

        todayDate = DateTime(
          int.parse(todayParts[0]),
          int.parse(todayParts[1]),
          int.parse(todayParts[2]),
        );
      }

      if (lastDate != null && todayDate != null) {
        final diff = todayDate.difference(lastDate).inDays;

        if (diff == 0) {
          // already completed today -> no streak change
        } else if (diff == 1) {
          streak += 1;
        } else {
          streak = 1;
        }
      } else {
        streak = 1;
      }
    }

    await prefs.setInt(_keyStreak, streak);
    await prefs.setString(_keyLastDoneDate, today);

    // history
    final history = prefs.getStringList(_keyHistory) ?? [];
    final time = DateTime.now().toIso8601String();
    history.insert(0, "$time|$activityId|$activityTitle");
    if (history.length > 60) history.removeRange(60, history.length);
    await prefs.setStringList(_keyHistory, history);
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
