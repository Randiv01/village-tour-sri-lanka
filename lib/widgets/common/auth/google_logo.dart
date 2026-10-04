import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Google Colors
    final Color blue = const Color(0xFF4285F4);
    final Color red = const Color(0xFFEA4335);
    final Color yellow = const Color(0xFFFBBC05);
    final Color green = const Color(0xFF34A853);

    // Red part (Top)
    paint.color = red;
    final Path redPath = Path()
      ..moveTo(w * 0.5, h * 0.2)
      ..arcToPoint(
        Offset(w * 0.18, h * 0.35),
        radius: Radius.circular(w * 0.5),
        clockwise: false,
      )
      ..lineTo(w * 0.3, h * 0.46)
      ..arcToPoint(
        Offset(w * 0.5, h * 0.35),
        radius: Radius.circular(w * 0.2),
        clockwise: true,
      )
      ..arcToPoint(
        Offset(w * 0.7, h * 0.45),
        radius: Radius.circular(w * 0.2),
        clockwise: true,
      )
      ..lineTo(w * 0.85, h * 0.3)
      ..arcToPoint(
        Offset(w * 0.5, h * 0.2),
        radius: Radius.circular(w * 0.5),
        clockwise: false,
      );
    canvas.drawPath(redPath, paint);

    // Blue part (Right)
    paint.color = blue;
    // Simpler Blue part
    final Path simpleBluePath = Path()
      ..moveTo(w * 0.48, h * 0.48)
      ..lineTo(w * 0.98, h * 0.48)
      ..lineTo(w * 0.98, h * 0.58)
      ..arcToPoint(
        Offset(w * 0.75, h * 0.94),
        radius: Radius.circular(w * 0.5),
        clockwise: false,
      )
      ..lineTo(w * 0.6, h * 0.78)
      ..arcToPoint(
        Offset(w * 0.65, h * 0.55),
        radius: Radius.circular(w * 0.2),
        clockwise: true,
      )
      ..lineTo(w * 0.48, h * 0.55)
      ..close();
    canvas.drawPath(simpleBluePath, paint);

    // Yellow part (Left)
    paint.color = yellow;
    final Path yellowPath = Path()
      ..moveTo(w * 0.18, h * 0.35)
      ..lineTo(w * 0.3, h * 0.46)
      ..arcToPoint(
        Offset(w * 0.3, h * 0.6),
        radius: Radius.circular(w * 0.2),
        clockwise: false,
      )
      ..lineTo(w * 0.15, h * 0.7)
      ..arcToPoint(
        Offset(w * 0.18, h * 0.35),
        radius: Radius.circular(w * 0.5),
        clockwise: true,
      );
    canvas.drawPath(yellowPath, paint);

    // Green part (Bottom)
    paint.color = green;
    final Path greenPath = Path()
      ..moveTo(w * 0.15, h * 0.7)
      ..lineTo(w * 0.3, h * 0.6)
      ..arcToPoint(
        Offset(w * 0.6, h * 0.78),
        radius: Radius.circular(w * 0.2),
        clockwise: false,
      )
      ..lineTo(w * 0.75, h * 0.94)
      ..arcToPoint(
        Offset(w * 0.15, h * 0.7),
        radius: Radius.circular(w * 0.5),
        clockwise: true,
      );
    canvas.drawPath(greenPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
