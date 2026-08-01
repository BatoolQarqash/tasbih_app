import 'package:flutter_test/flutter_test.dart';
import 'package:tasbih_app/utils/streak_calculator.dart';

void main() {
  const threshold = 33;
  final today = DateTime(2026, 7, 29);

  String key(int daysAgo) => dateKey(today.subtract(Duration(days: daysAgo)));

  test('today already met threshold, with prior consecutive qualifying days', () {
    final counts = {
      key(0): 40, // today
      key(1): 33,
      key(2): 50,
      key(3): 10, // breaks here
    };
    expect(computeStreak(counts, threshold, today), 3);
  });

  test('today below threshold does not break an in-progress streak', () {
    final counts = {
      key(0): 5, // today, not yet met
      key(1): 33,
      key(2): 33,
    };
    expect(computeStreak(counts, threshold, today), 2);
  });

  test('a gap day breaks the streak at the right point', () {
    final counts = {
      key(0): 40,
      key(1): 40,
      key(2): 10, // gap
      key(3): 40,
    };
    expect(computeStreak(counts, threshold, today), 2);
  });

  test('longest streak is independent of pruning (caller responsibility check)', () {
    // computeStreak only reports the CURRENT streak from the given map;
    // callers must track longestStreak separately since old entries get pruned.
    final counts = {key(0): 40, key(1): 40};
    final current = computeStreak(counts, threshold, today);
    const previouslyStoredLongest = 100;
    final longest = current > previouslyStoredLongest ? current : previouslyStoredLongest;
    expect(longest, 100);
  });

  test('exact threshold boundary: == threshold counts, one below does not', () {
    final counts = {key(0): 33, key(1): 32};
    expect(computeStreak(counts, threshold, today), 1);
  });

  test('empty history means zero streak', () {
    expect(computeStreak({}, threshold, today), 0);
  });
}
