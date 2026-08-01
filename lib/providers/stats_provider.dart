import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../utils/streak_calculator.dart';
import '../services/stats_service.dart' as stats_service;
import 'achievements_provider.dart';
import 'counter_provider.dart';

// الحد الأدنى من العدّ اليومي حتى يُحتسب اليوم "نشط" لأغراض السلسلة (streak)
const int kMinDailyCountForStreak = 33;

class StatsState {
  const StatsState({
    required this.dailyCounts,
    required this.currentStreak,
    required this.longestStreak,
  });

  const StatsState.empty()
      : dailyCounts = const {},
        currentStreak = 0,
        longestStreak = 0;

  final Map<String, int> dailyCounts;
  final int currentStreak;
  final int longestStreak;

  StatsState copyWith({
    Map<String, int>? dailyCounts,
    int? currentStreak,
    int? longestStreak,
  }) {
    return StatsState(
      dailyCounts: dailyCounts ?? this.dailyCounts,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }
}

// StateNotifier بيدير العدّ اليومي (للإحصائيات) + السلسلة (streak) + الحفظ
// التلقائي، وبيبلّغ إنجازات المجموع/السلسلة كل ما توصل ضغطة جديدة
class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier(this._ref) : super(const StatsState.empty()) {
    _load();
  }

  final Ref _ref;

  // كتابة خريطة العدّ اليومي (JSON) أثقل من كتابة int عادي، فمنأجّلها شوي
  // بدل ما نكتبها بكل ضغطة؛ الذاكرة هي مصدر الحقيقة بالجلسة، والكتابة
  // بتصير debounced + بتُفلَش لما التطبيق يروح للخلفية (main.dart)
  Timer? _flushTimer;

  Future<void> _load() async {
    final dailyCounts = await stats_service.loadDailyCounts();
    final longestStreak = await stats_service.loadLongestStreak();
    final currentStreak = computeStreak(dailyCounts, kMinDailyCountForStreak, DateTime.now());

    state = StatsState(
      dailyCounts: dailyCounts,
      currentStreak: currentStreak,
      longestStreak: longestStreak > currentStreak ? longestStreak : currentStreak,
    );
  }

  // تُنادى من أي مكان بيسجّل نشاط ذكر (زر التسبيح الحر أو جلسة أذكار)
  void recordTap() {
    final now = DateTime.now();
    final key = dateKey(now);

    final updatedCounts = Map<String, int>.of(state.dailyCounts);
    updatedCounts[key] = (updatedCounts[key] ?? 0) + 1;

    final newStreak = computeStreak(updatedCounts, kMinDailyCountForStreak, now);
    final newLongest = newStreak > state.longestStreak ? newStreak : state.longestStreak;

    state = state.copyWith(
      dailyCounts: updatedCounts,
      currentStreak: newStreak,
      longestStreak: newLongest,
    );

    unawaited(stats_service.saveCurrentStreak(newStreak));
    unawaited(stats_service.saveLongestStreak(newLongest));
    unawaited(stats_service.saveLastActiveDate(now));
    _scheduleDailyCountsFlush();

    _ref.read(achievementsProvider.notifier).evaluate(
          total: _ref.read(counterProvider.notifier).totalCount,
          streak: newStreak,
        );
  }

  void _scheduleDailyCountsFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(milliseconds: 800), flushDailyCounts);
  }

  // بتُنادى مباشرة (بدون انتظار الـ debounce) لما التطبيق يروح للخلفية، حتى
  // ما تضيع آخر ضغطات لو المستخدم سكّر التطبيق قبل ما ينتهي المؤقت
  Future<void> flushDailyCounts() async {
    _flushTimer?.cancel();
    await stats_service.saveDailyCounts(state.dailyCounts);
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    super.dispose();
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(ref);
});

String _todayKey() => dateKey(DateTime.now());

final todayCountProvider = Provider<int>((ref) {
  final stats = ref.watch(statsProvider);
  return stats.dailyCounts[_todayKey()] ?? 0;
});

// آخر 7 أيام (الأقدم أولاً، اليوم أخيراً) - لعمود الرسم البياني الأسبوعي
final last7DaysCountsProvider = Provider<List<int>>((ref) {
  final stats = ref.watch(statsProvider);
  final today = DateTime.now();
  return List.generate(7, (i) {
    final day = today.subtract(Duration(days: 6 - i));
    return stats.dailyCounts[dateKey(day)] ?? 0;
  });
});

final thisWeekTotalProvider = Provider<int>((ref) {
  final counts = ref.watch(last7DaysCountsProvider);
  return counts.fold<int>(0, (sum, c) => sum + c);
});

// خريطة الشهر الحالي {يوم بالشهر: عدد}، لبناء الـ heatmap
final currentMonthCountsProvider = Provider<Map<int, int>>((ref) {
  final stats = ref.watch(statsProvider);
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  return {
    for (var day = 1; day <= daysInMonth; day++)
      day: stats.dailyCounts[dateKey(DateTime(now.year, now.month, day))] ?? 0,
  };
});

final thisMonthTotalProvider = Provider<int>((ref) {
  final counts = ref.watch(currentMonthCountsProvider);
  return counts.values.fold<int>(0, (sum, c) => sum + c);
});
