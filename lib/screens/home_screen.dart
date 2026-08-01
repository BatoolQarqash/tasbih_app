import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import '../data/achievements_data.dart';
import '../providers/achievements_provider.dart';
import '../providers/adhkar_reminder_provider.dart';
import '../providers/counter_provider.dart';
import '../providers/stats_provider.dart';
import '../services/notification_service.dart';
import '../widgets/achievement_unlocked_dialog.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/tasbih_tap_button.dart';
import 'achievements_screen.dart';
import 'adhkar_session_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _darkGreen = Color(0xFF1B4332);
  static const _midGreen = Color(0xFF2D6A4F);
  static const _lightGreen = Color(0xFF52B788);

  // اهتزاز مختلف وأقوى من اهتزاز الضغط العادي، لما يوصل العداد للهدف
  Future<void> _vibrateGoalReached() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 400]);
    }
  }

  void _showGoalReachedDialog(BuildContext context, WidgetRef ref, int achieved) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'ما شاء الله! 🎉',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: _darkGreen),
        ),
        content: Text(
          'أتممت $achieved تسبيحة',
          style: GoogleFonts.cairo(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إغلاق', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _darkGreen, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(counterProvider.notifier).reset();
              Navigator.of(context).pop();
            },
            child: Text('تصفير والبدء من جديد', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    final selectedTasbih = ref.watch(tasbihTypeProvider);
    final target = ref.watch(targetProvider);
    // بنقرا الـ provider هون فقط عشان يتهيّأ ويجدول تذكيري الأذكار المحفوظين من قبل
    ref.watch(adhkarReminderProvider);

    // مقاسات نسبية بدل الأرقام الثابتة، عشان تشتغل صح من أصغر هاتف لأكبر تابلت
    // وبالوضعين portrait/landscape (shortestSide بيمثل البعد الأصغر بالحالتين)
    final mediaSize = MediaQuery.sizeOf(context);
    final shortestSide = mediaSize.shortestSide;
    final circleSize = (shortestSide * 0.5).clamp(140.0, 240.0);
    final numberFontSize = (shortestSide * 0.18).clamp(44.0, 90.0);
    final progressWidth = (mediaSize.width * 0.6).clamp(160.0, 260.0);
    final dropdownMaxWidth = (mediaSize.width * 0.82).clamp(0.0, 380.0);

    // لما العداد يوصل للهدف بالضبط، منفعّل اهتزاز مختلف ومنفتح دايلوج التهنئة
    ref.listen<int>(counterProvider, (previous, next) {
      if (target > 0 && previous != null && previous < target && next >= target) {
        _vibrateGoalReached();
        _showGoalReachedDialog(context, ref, next);
      }
    });

    // احتفال بفتح إنجاز جديد (مجموع/سلسلة)
    ref.listen(achievementsProvider, (previous, next) {
      if (next.unlockQueue.isNotEmpty) {
        final id = next.unlockQueue.first;
        final def = achievementsData.firstWhere((a) => a.id == id);
        showAchievementUnlockedDialog(context, def);
        ref.read(achievementsProvider.notifier).consumeNextUnlock();
      }
    });

    // لو التطبيق انفتح بضغطة على إشعار وهو مقفول تماماً، نفتح جلسة الأذكار
    // المناسبة مرة وحدة بس بعد أول frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingType = NotificationService.instance.pendingAdhkarLaunchType;
      if (pendingType != null) {
        NotificationService.instance.pendingAdhkarLaunchType = null;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AdhkarSessionScreen(type: pendingType)),
        );
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'عداد التسبيح',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'الإحصائيات',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'الإنجازات',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'الإعدادات',
            onPressed: () => showSettingsDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة التصفير',
            onPressed: () {
              ref.read(counterProvider.notifier).reset();
            },
          ),
        ],
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
              // SingleChildScrollView + minHeight بدل Column ثابت، عشان لو
              // المحتوى أطول من الشاشة (Landscape على هاتف صغير مثلاً) يصير
              // قابل للتمرير بدل ما يعمل Overflow
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // إجمالي التسبيح منذ تنزيل التطبيق
                        Consumer(
                          builder: (context, ref, child) {
                            final total = ref.watch(totalCountProvider);
                            return Text(
                              'إجمالي التسبيح: $total',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Dropdown لاختيار نوع التسبيح
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: dropdownMaxWidth),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            child: DropdownButton<String>(
                              value: selectedTasbih,
                              isExpanded: true,
                              underline: const SizedBox(),
                              borderRadius: BorderRadius.circular(16),
                              dropdownColor: Colors.white,
                              items: tasbihOptions.map((option) {
                                return DropdownMenuItem(
                                  value: option,
                                  child: Text(
                                    option,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(fontSize: 18, color: _darkGreen),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  ref.read(tasbihTypeProvider.notifier).state = value;
                                  ref.read(counterProvider.notifier).reset();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // مؤشر التقدم نحو الهدف
                        if (target > 0)
                          SizedBox(
                            width: progressWidth,
                            child: Column(
                              children: [
                                Text(
                                  count >= target
                                      ? 'تم تحقيق الهدف 🎉'
                                      : 'باقي ${target - count} من $target',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: (count / target).clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        // عرض الرقم
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(scale: animation, child: child),
                          ),
                          child: Text(
                            '$count',
                            key: ValueKey<int>(count),
                            style: GoogleFonts.cairo(
                              fontSize: numberFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [
                                Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // زر التسبيح
                        TasbihTapButton(
                          label: selectedTasbih,
                          size: circleSize,
                          onTap: () async {
                            ref.read(counterProvider.notifier).increment();
                            // بتسجّل هاي بالإحصائيات اليومية وتحسب السلسلة
                            // وتفحص إنجازات المجموع/السلسلة (recordTap تنادي
                            // achievementsProvider.evaluate داخلياً)
                            ref.read(statsProvider.notifier).recordTap();

                            final hasVibrator = await Vibration.hasVibrator();
                            if (hasVibrator) {
                              Vibration.vibrate(duration: 40);
                            }
                          },
                        ),
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
