import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/achievement.dart';

const _darkGreen = Color(0xFF1B4332);

// نافذة احتفال يدوية (scale + fade) بنفس شكل _showGoalReachedDialog الموجودة
// أصلاً بالشاشة الرئيسية، بدون أي مكتبة confetti خارجية
Future<void> showAchievementUnlockedDialog(BuildContext context, AchievementDef achievement) {
  return showDialog(
    context: context,
    builder: (context) => _AchievementUnlockedDialog(achievement: achievement),
  );
}

class _AchievementUnlockedDialog extends StatefulWidget {
  const _AchievementUnlockedDialog({required this.achievement});

  final AchievementDef achievement;

  @override
  State<_AchievementUnlockedDialog> createState() => _AchievementUnlockedDialogState();
}

class _AchievementUnlockedDialogState extends State<_AchievementUnlockedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
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
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'إنجاز جديد! 🎉',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: _darkGreen),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.achievement.icon, size: 56, color: _darkGreen),
              const SizedBox(height: 12),
              Text(
                widget.achievement.titleAr,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                widget.achievement.descriptionAr,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _darkGreen, foregroundColor: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('رائع!', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }
}
