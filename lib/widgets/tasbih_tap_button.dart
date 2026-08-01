import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// زر التسبيح/الذكر مع حركة scale بسيطة عند الضغط. مستخدم بشاشة الرئيسية
// وشاشة جلسة الأذكار، فصار widget عام بدل ما يضل خاص بشاشة وحدة.
class TasbihTapButton extends StatefulWidget {
  const TasbihTapButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.size,
    this.color = const Color(0xFF1B4332),
  });

  final String label;
  final VoidCallback onTap;
  final double size;
  final Color color;

  @override
  State<TasbihTapButton> createState() => _TasbihTapButtonState();
}

class _TasbihTapButtonState extends State<TasbihTapButton> {
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
            color: widget.color,
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
