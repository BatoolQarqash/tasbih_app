import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// رقم إحصائية بيتحرك (count-up) للقيمة الجديدة كل ما تتغيّر، بدل ما تتبدّل فجأة
class AnimatedCountText extends StatelessWidget {
  const AnimatedCountText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  final int value;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          '$animatedValue',
          style: style ?? GoogleFonts.cairo(fontWeight: FontWeight.bold),
        );
      },
    );
  }
}
