import 'package:flutter/material.dart';

/// Matches the demo list's pastel circles and solid, brightly colored symbols.
class HolidayDemoIcon extends StatelessWidget {
  const HolidayDemoIcon({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: CustomPaint(painter: _HolidayDemoIconPainter()),
  );
}

class _HolidayDemoIconPainter extends CustomPainter {
  const _HolidayDemoIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    canvas.drawCircle(
      const Offset(24, 24),
      21.6,
      Paint()..color = const Color(0xFFFFF0DD),
    );
    final calendar = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10.5, 12.5, 27, 25),
      const Radius.circular(5),
    );
    canvas.drawRRect(calendar, Paint()..color = const Color(0xFFFF9D3D));
    canvas.save();
    canvas.clipRRect(calendar);
    canvas.drawPath(
      Path()
        ..moveTo(10.5, 12.5)
        ..lineTo(37.5, 12.5)
        ..quadraticBezierTo(25, 32, 10.5, 32)
        ..close(),
      Paint()..color = const Color(0xFFFFB65D),
    );
    canvas.drawRect(
      const Rect.fromLTWH(10.5, 20.5, 27, 1.5),
      Paint()..color = const Color(0xFFFFF0DD),
    );
    canvas.drawPath(
      Path()
        ..moveTo(10.5, 37.5)
        ..quadraticBezierTo(26, 36, 37.5, 24)
        ..lineTo(37.5, 37.5)
        ..close(),
      Paint()..color = const Color(0xFFF78B2F),
    );
    canvas.restore();
    final binding = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.5
      ..color = const Color(0xFFFFF0DD);
    for (final x in [17.0, 29.0]) {
      canvas.drawLine(Offset(x, 10), Offset(x, 16), binding);
      canvas.drawLine(
        Offset(x, 10),
        Offset(x, 16),
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.8
          ..color = const Color(0xFFFFA545),
      );
    }
    for (final point in const [
      Offset(16, 25.5),
      Offset(25.5, 25.5),
      Offset(16, 31.5),
      Offset(25.5, 31.5),
    ]) {
      canvas.drawRect(
        point & const Size(4, 3.5),
        Paint()..color = const Color(0xFFFFF4E3),
      );
    }
    // A single broad sparkle keeps the symbol legible at the list's 46dp size.
    canvas.drawPath(
      Path()
        ..moveTo(37, 7)
        ..quadraticBezierTo(38.5, 12, 43.5, 13.5)
        ..quadraticBezierTo(38.5, 15, 37, 20)
        ..quadraticBezierTo(35.5, 15, 30.5, 13.5)
        ..quadraticBezierTo(35.5, 12, 37, 7)
        ..close(),
      Paint()..color = const Color(0xFFFFCC5B),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HolidayDemoIconPainter oldDelegate) => false;
}
