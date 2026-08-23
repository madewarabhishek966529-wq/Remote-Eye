import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showTagline;

  const BrandLogo({
    super.key,
    this.size = 80.0,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size * 0.75),
          painter: _RemoteEyeLogoPainter(),
        ),
        if (showTagline) ...[
          const SizedBox(height: 12),
          const Text(
            'REMOTE EYE',
            style: TextStyle(
              color: AppTheme.textBright,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Real-Time P2P Screen Control',
            style: TextStyle(
              color: AppTheme.primaryCyan,
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _RemoteEyeLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Eye Outline (Outer Cyan Glow & Path)
    final eyePaint = Paint()
      ..color = AppTheme.primaryCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round;

    final eyePath = Path();
    eyePath.moveTo(0, h / 2);
    eyePath.quadraticBezierTo(w / 2, -h * 0.2, w, h / 2);
    eyePath.quadraticBezierTo(w / 2, h * 1.2, 0, h / 2);
    canvas.drawPath(eyePath, eyePaint);

    // Center Pupil (Glowing Circle)
    final pupilPaint = Paint()
      ..color = AppTheme.accentNeon
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, w * 0.16, pupilPaint);

    final innerPupilPaint = Paint()
      ..color = AppTheme.darkBackground
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, w * 0.08, innerPupilPaint);

    // Signal/Wireless Waves (radiating from top of eye)
    final wavePaint = Paint()
      ..color = AppTheme.primaryCyan.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;

    // Wave 1
    final wave1 = Path();
    wave1.addArc(
      Rect.fromCircle(center: Offset(w / 2, h * 0.35), radius: w * 0.28),
      -2.4,
      1.6,
    );
    canvas.drawPath(wave1, wavePaint);

    // Wave 2
    final wave2 = Path();
    wave2.addArc(
      Rect.fromCircle(center: Offset(w / 2, h * 0.35), radius: w * 0.42),
      -2.4,
      1.6,
    );
    canvas.drawPath(wave2, wavePaint..color = AppTheme.primaryCyan.withValues(alpha: 0.4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
