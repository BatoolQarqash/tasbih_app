// دالة نقية (pure) لحساب السلسلة (streak) + مساعد تنسيق التاريخ.
// معزولة عن أي I/O عشان تنعمل عليها اختبارات وحدة بسيطة وسريعة.

String dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

// بيحسب عدد الأيام المتتالية اللي فيها نشاط >= threshold، ماشي عكسياً من اليوم.
// إذا اليوم الحالي لسا ما وصل للهدف، هالشي ما بكسر السلسلة (لأن اليوم لسا ما خلص)؛
// بس منكمل نعد الأيام المتتالية قبل اليوم عادي.
int computeStreak(Map<String, int> dailyCounts, int threshold, DateTime today) {
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final todayCount = dailyCounts[dateKey(normalizedToday)] ?? 0;

  var streak = todayCount >= threshold ? 1 : 0;
  var cursor = normalizedToday.subtract(const Duration(days: 1));

  while (true) {
    final count = dailyCounts[dateKey(cursor)] ?? 0;
    if (count < threshold) break;
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return streak;
}
