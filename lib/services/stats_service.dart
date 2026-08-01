// دوال مساعدة للتخزين المحلي (SharedPreferences) الخاصة بالإحصائيات
// والسلسلة (streak) والإنجازات وتقدّم جلسات الأذكار.
// دوال بسيطة بدون كلاس/حالة، بنفس أسلوب بقية الـ providers بالمشروع.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/streak_calculator.dart';

// حد أقصى لعدد الأيام المحفوظة بسجل العدّ اليومي، حتى ما يكبر التخزين بلا حدود
const int kMaxDailyHistoryEntries = 400;

const _dailyCountsKey = 'stats_daily_counts_json';
const _currentStreakKey = 'stats_current_streak';
const _longestStreakKey = 'stats_longest_streak';
const _lastActiveDateKey = 'stats_last_active_date';
const _achievementsUnlockedKey = 'achievements_unlocked_json';

Future<Map<String, int>> loadDailyCounts() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_dailyCountsKey);
  if (raw == null) return {};
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return decoded.map((key, value) => MapEntry(key, value as int));
}

// بيقص أقدم الإدخالات إذا زادت عن الحد الأقصى قبل الحفظ
Future<void> saveDailyCounts(Map<String, int> counts) async {
  var toSave = counts;
  if (counts.length > kMaxDailyHistoryEntries) {
    final sortedKeys = counts.keys.toList()..sort();
    final keysToKeep = sortedKeys.sublist(sortedKeys.length - kMaxDailyHistoryEntries);
    toSave = {for (final k in keysToKeep) k: counts[k]!};
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_dailyCountsKey, jsonEncode(toSave));
}

Future<int> loadLongestStreak() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_longestStreakKey) ?? 0;
}

Future<void> saveLongestStreak(int value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_longestStreakKey, value);
}

Future<void> saveCurrentStreak(int value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_currentStreakKey, value);
}

Future<void> saveLastActiveDate(DateTime date) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_lastActiveDateKey, dateKey(date));
}

Future<Set<String>> loadUnlockedAchievementNames() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_achievementsUnlockedKey);
  if (raw == null) return {};
  return (jsonDecode(raw) as List).cast<String>().toSet();
}

Future<void> saveUnlockedAchievementNames(Set<String> names) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_achievementsUnlockedKey, jsonEncode(names.toList()));
}

// تقدّم جلسة الأذكار (صباح/مساء) لليوم الحالي فقط؛ لو التاريخ المحفوظ غير
// تاريخ اليوم منرجع null عشان الشاشة تبلّش جلسة جديدة
Future<Map<String, dynamic>?> loadAdhkarSessionProgress(String typeKey) async {
  final prefs = await SharedPreferences.getInstance();
  final date = prefs.getString('adhkar_session_${typeKey}_date');
  final raw = prefs.getString('adhkar_session_${typeKey}_progress_json');
  if (date == null || raw == null) return null;
  if (date != dateKey(DateTime.now())) return null;
  return jsonDecode(raw) as Map<String, dynamic>;
}

Future<void> saveAdhkarSessionProgress(String typeKey, Map<String, dynamic> progress) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('adhkar_session_${typeKey}_date', dateKey(DateTime.now()));
  await prefs.setString('adhkar_session_${typeKey}_progress_json', jsonEncode(progress));
}
