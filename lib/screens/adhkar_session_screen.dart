import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/achievements_data.dart';
import '../data/adhkar_data.dart';
import '../models/adhkar_session.dart';
import '../providers/achievements_provider.dart';
import '../providers/adhkar_session_provider.dart';
import '../widgets/achievement_unlocked_dialog.dart';
import '../widgets/tasbih_tap_button.dart';

class AdhkarSessionScreen extends ConsumerWidget {
  const AdhkarSessionScreen({super.key, required this.type});

  final AdhkarType type;

  static const _darkGreen = Color(0xFF1B4332);
  static const _midGreen = Color(0xFF2D6A4F);
  static const _lightGreen = Color(0xFF52B788);

  StateNotifierProvider<AdhkarSessionNotifier, AdhkarSessionState> get _provider =>
      type == AdhkarType.morning ? adhkarSessionMorningProvider : adhkarSessionEveningProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = adhkarSessions[type]!.items;
    final session = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);

    // احتفال بفتح إنجاز جديد (نفس المنطق المستخدم بالشاشة الرئيسية)
    ref.listen(achievementsProvider, (previous, next) {
      if (next.unlockQueue.isNotEmpty) {
        final id = next.unlockQueue.first;
        final def = achievementsData.firstWhere((a) => a.id == id);
        showAchievementUnlockedDialog(context, def);
        ref.read(achievementsProvider.notifier).consumeNextUnlock();
      }
    });

    final mediaSize = MediaQuery.sizeOf(context);
    final shortestSide = mediaSize.shortestSide;
    final circleSize = (shortestSide * 0.5).clamp(140.0, 240.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(type.titleAr, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
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
          child: session.completed
              ? _CompletionView(type: type)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final currentItem = items[session.currentIndex];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'الذكر ${session.currentIndex + 1} من ${items.length}',
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: session.currentIndex / items.length,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.25),
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                            const SizedBox(height: 24),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, animation) {
                                final slide = Tween<Offset>(
                                  begin: const Offset(0.15, 0),
                                  end: Offset.zero,
                                ).animate(animation);
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(position: slide, child: child),
                                );
                              },
                              child: Container(
                                key: ValueKey<int>(session.currentIndex),
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
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
                                child: Column(
                                  children: [
                                    Text(
                                      currentItem.text,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: _darkGreen,
                                      ),
                                    ),
                                    if (currentItem.virtue != null) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        currentItem.virtue!,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          color: Colors.black54,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              '${session.currentItemTapCount} / ${currentItem.targetCount}',
                              style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 24),
                            TasbihTapButton(
                              label: 'اضغط',
                              size: circleSize,
                              onTap: notifier.tap,
                            ),
                          ],
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

class _CompletionView extends StatefulWidget {
  const _CompletionView({required this.type});

  final AdhkarType type;

  @override
  State<_CompletionView> createState() => _CompletionViewState();
}

class _CompletionViewState extends State<_CompletionView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'أتممت ${widget.type.titleAr} كاملة',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text('تقبّل الله منك', style: GoogleFonts.cairo(fontSize: 15, color: Colors.white70)),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1B4332),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('العودة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
