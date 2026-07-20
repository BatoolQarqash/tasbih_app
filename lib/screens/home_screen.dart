import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import '../providers/counter_provider.dart';
import '../providers/reminder_provider.dart';
import '../widgets/settings_dialog.dart';

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
    // بنقرا الـ provider هون فقط عشان يتهيّأ ويجدول التذكير اليومي المحفوظ من قبل
    ref.watch(reminderProvider);

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
                            final totalAsync = ref.watch(totalCountProvider);
                            return totalAsync.when(
                              data: (total) => Text(
                                'إجمالي التسبيح: $total',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                                  ],
                                ),
                              ),
                              loading: () => const SizedBox(),
                              error: (_, _) => const SizedBox(),
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
                        _TasbihButton(
                          label: selectedTasbih,
                          size: circleSize,
                          onTap: () async {
                            ref.read(counterProvider.notifier).increment();
                            ref.invalidate(totalCountProvider);

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

// زر التسبيح مع حركة scale بسيطة عند الضغط
class _TasbihButton extends StatefulWidget {
  const _TasbihButton({required this.label, required this.onTap, required this.size});

  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  State<_TasbihButton> createState() => _TasbihButtonState();
}

class _TasbihButtonState extends State<_TasbihButton> {
  double _scale = 1.0;

  void _setScale(double value) => setState(() => _scale = value);

  @override
  Widget build(BuildContext context) {
    // خط اسم الذكر جوا الدائرة بيتناسب مع حجم الدائرة نفسها، عشان ما يلمس
    // الحواف على الدوائر الصغيرة وما يضل صغير جداً على الدوائر الكبيرة
    final labelFontSize = (widget.size * 0.11).clamp(14.0, 22.0);

    return GestureDetector(
      onTapDown: (_) => _setScale(0.95),
      onTapUp: (_) => _setScale(1.0),
      onTapCancel: () => _setScale(1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: widget.size,
          height: widget.size,
          padding: EdgeInsets.all(widget.size * 0.1),
          decoration: BoxDecoration(
            color: HomeScreen._darkGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: labelFontSize,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
