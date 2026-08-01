import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/stats_provider.dart';
import '../widgets/animated_count_text.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  static const _darkGreen = Color(0xFF1B4332);
  static const _midGreen = Color(0xFF2D6A4F);
  static const _lightGreen = Color(0xFF52B788);

  static const _weekdayShort = {
    1: 'إثن',
    2: 'ثلا',
    3: 'أرب',
    4: 'خمي',
    5: 'جمع',
    6: 'سبت',
    7: 'أحد',
  };

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final todayCount = ref.watch(todayCountProvider);
    final weekCounts = ref.watch(last7DaysCountsProvider);
    final weekTotal = ref.watch(thisWeekTotalProvider);
    final monthCounts = ref.watch(currentMonthCountsProvider);
    final monthTotal = ref.watch(thisMonthTotalProvider);

    final mediaSize = MediaQuery.sizeOf(context);
    final maxContentWidth = mediaSize.width.clamp(0.0, 560.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('الإحصائيات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_darkGreen, _midGreen, _lightGreen],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        _card(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 32)),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  stats.currentStreak > 0
                                      ? 'لقد حافظت على الاستمرارية لمدة ${stats.currentStreak} يوم'
                                      : 'ابدأ اليوم لتبني سلسلة استمرارية جديدة',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: _darkGreen),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'أطول سلسلة: ${stats.longestStreak} يوم',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _card(
                          child: Column(
                            children: [
                              Text('اليوم', style: GoogleFonts.cairo(fontSize: 14, color: Colors.black54)),
                              const SizedBox(height: 4),
                              AnimatedCountText(
                                value: todayCount,
                                style: GoogleFonts.cairo(fontSize: 40, fontWeight: FontWeight.bold, color: _darkGreen),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'هذا الأسبوع: $weekTotal',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: _darkGreen),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 160,
                                child: _WeekBarChart(counts: weekCounts, weekdayShort: _weekdayShort, color: _midGreen),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'هذا الشهر: $monthTotal',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: _darkGreen),
                              ),
                              const SizedBox(height: 12),
                              _MonthHeatmap(counts: monthCounts, color: _lightGreen),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WeekBarChart extends StatelessWidget {
  const _WeekBarChart({required this.counts, required this.weekdayShort, required this.color});

  final List<int> counts;
  final Map<int, String> weekdayShort;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final maxCount = counts.fold<int>(1, (m, c) => c > m ? c : m);

    return BarChart(
      BarChartData(
        maxY: (maxCount * 1.25),
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          for (var i = 0; i < counts.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: counts[i].toDouble(),
                  color: color,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= counts.length) return const SizedBox();
                final day = today.subtract(Duration(days: counts.length - 1 - index));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    weekdayShort[day.weekday] ?? '',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.black54),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _MonthHeatmap extends StatelessWidget {
  const _MonthHeatmap({required this.counts, required this.color});

  final Map<int, int> counts;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxCount = counts.values.fold<int>(1, (m, c) => c > m ? c : m);

    return LayoutBuilder(
      builder: (context, constraints) {
        // شبكة مرنة: عدد الأعمدة يتكيّف مع عرض الشاشة (هاتف صغير لتابلت)
        final columns = (constraints.maxWidth / 40).floor().clamp(6, 10);
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final day in counts.keys)
              SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 6) / columns,
                height: (constraints.maxWidth - (columns - 1) * 6) / columns,
                child: Tooltip(
                  message: '$day: ${counts[day]}',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Colors.grey.shade200,
                        color,
                        (counts[day]! / maxCount).clamp(0.0, 1.0),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: GoogleFonts.cairo(fontSize: 10, color: Colors.black54),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
