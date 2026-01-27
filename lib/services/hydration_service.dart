import 'package:shared_preferences/shared_preferences.dart';

class HydrationService {
  static const _keyGoal = "hydration_goal";
  static const _keyCount = "hydration_count";
  static const _keyDay = "hydration_day";

  static String _todayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  static Future<Map<String, int>> loadToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    final savedDay = prefs.getString(_keyDay);

    // if day changed -> reset count, keep goal
    if (savedDay != today) {
      final goal = prefs.getInt(_keyGoal) ?? 8;
      await prefs.setString(_keyDay, today);
      await prefs.setInt(_keyCount, 0);
      return {"goal": goal, "count": 0};
    }

    final goal = prefs.getInt(_keyGoal) ?? 8;
    final count = prefs.getInt(_keyCount) ?? 0;

    return {"goal": goal, "count": count};
  }

  static Future<void> saveToday({
    required int goal,
    required int count,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    await prefs.setString(_keyDay, today);
    await prefs.setInt(_keyGoal, goal);
    await prefs.setInt(_keyCount, count);
  }
}
