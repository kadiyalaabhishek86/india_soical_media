import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';

class AaraCountdownTimer extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final double size;

  const AaraCountdownTimer({
    super.key,
    required this.remainingSeconds,
    this.totalSeconds = 60,
    this.size = 210,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0 ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;
    final isLowTime = remainingSeconds <= 10;

    final progressColor = isLowTime ? AaraColors.error : AaraColors.plumViolet;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Track & Animated Progress (Soft Lavender Ring with Plum Fill)
          CustomPaint(
            size: Size(size, size),
            painter: _TimerPainter(
              progress: progress,
              trackColor: AaraColors.softLavender, // Soft lavender ring
              progressColor: progressColor, // Plum countdown ring
              strokeWidth: 8.0,
            ),
          ),
          // Clean White Inner Circle
          Container(
            width: size * 0.76,
            height: size * 0.76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AaraColors.plumViolet.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Large Plum Countdown Text in Inter font
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '0:${remainingSeconds.toString().padLeft(2, '0')}',
                style: AaraTypography.timerCountdown.copyWith(
                  color: progressColor,
                  fontSize: size * 0.22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isLowTime ? 'ENDING SOON' : 'CALL TIME',
                style: AaraTypography.labelSmall.copyWith(
                  letterSpacing: 1.5,
                  color: isLowTime ? AaraColors.error : AaraColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _TimerPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Soft lavender background ring
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Active plum progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
