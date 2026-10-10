import 'dart:math' as math;
import 'package:flutter/material.dart';

// ======= رسام حلقة البوصلة =======
class CompassRingPainter extends CustomPainter {
  final bool isDark;
  final bool isAligned; // NEW
  CompassRingPainter({required this.isDark, required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5.0;

    final directions = {
      'ش': 0.0,
      'ق': math.pi / 2,
      'ج': math.pi,
      'غ': 3 * math.pi / 2,
    };

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 360; i += 5) {
      final rad = i * math.pi / 180 - math.pi / 2;
      final isMain = i % 90 == 0;
      final isSub = i % 30 == 0;

      // تكبير الأسنان قليلاً
      final len = isMain ? 16.0 : (isSub ? 12.0 : 7.0);
      final sw = isMain ? 2.5 : 1.5;

      // السن الرئيسي أصفر، والبقية أبيض، وإذا كان متطابق يصبح مضيئاً
      final color = isAligned
          ? const Color(0xFF00FF7F) // لون نيون أخضر
          : (isMain ? const Color(0xFFFFD700) : Colors.white);

      final start = Offset(
        center.dx + (radius - len) * math.cos(rad),
        center.dy + (radius - len) * math.sin(rad),
      );
      final end = Offset(
        center.dx + radius * math.cos(rad),
        center.dy + radius * math.sin(rad),
      );

      // رسم توهج نيون عند التطابق
      if (isAligned) {
        canvas.drawLine(
          start,
          end,
          Paint()
            ..color = const Color(0xFF00FF00).withValues(alpha: 0.6)
            ..strokeWidth = sw * 2.5
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      // السن الفعلي
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
    }

    directions.forEach((label, angle) {
      final rad = angle - math.pi / 2;
      // وضع الحروف بمحاذاة المحيط الخارجي مع إبعادها قليلاً عن الأسنان الجديدة
      final tr = radius - 24.0;
      final span = TextSpan(
        text: label,
        style: TextStyle(
          color: isAligned ? const Color(0xFF00FF7F) : Colors.white,
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
          shadows: isAligned
              ? [const Shadow(color: Colors.green, blurRadius: 12)]
              : [],
        ),
      );
      textPainter.text = span;
      textPainter.layout();
      final dx = center.dx + tr * math.cos(rad) - textPainter.width / 2;
      final dy = center.dy + tr * math.sin(rad) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(dx, dy));
    });
  }

  @override
  bool shouldRepaint(covariant CompassRingPainter old) =>
      old.isDark != isDark || old.isAligned != isAligned;
}

// ======= رسام سهم القبلة =======
class QiblaArrowPainter extends CustomPainter {
  final bool isAligned;
  QiblaArrowPainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // طول السهم محدد بدقة ليصل باتجاه الكعبة دون اختراقها
    final arrowLen = size.width / 2 - 58.0;

    final tip = Offset(center.dx, center.dy - arrowLen);

    // سهم رشيق وأنيق لا يحجب مسار الرادار
    final midLeft = Offset(center.dx - 11.0, center.dy);
    final midRight = Offset(center.dx + 11.0, center.dy);
    final tail = Offset(center.dx, center.dy + 22.0);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(midRight.dx, midRight.dy)
      ..lineTo(tail.dx, tail.dy)
      ..lineTo(midLeft.dx, midLeft.dy)
      ..close();

    // التوهج حول السهم
    canvas.drawPath(
      path,
      Paint()
        ..color = (isAligned ? const Color(0xFF00FF00) : Colors.amber)
            .withValues(alpha: isAligned ? 0.75 : 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isAligned ? 14 : 8),
    );

    // جسم السهم بلون جذاب
    canvas.drawPath(
      path,
      Paint()
        ..color = (isAligned ? const Color(0xFF00FFAA) : Colors.amber.shade500)
            .withValues(alpha: isAligned ? 0.95 : 0.85)
        ..style = PaintingStyle.fill,
    );

    // حواف السهم
    canvas.drawPath(
      path,
      Paint()
        ..color = isAligned ? const Color(0xFF00FF7F) : Colors.amber.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // خط طي ثلاثي الأبعاد بالمنتصف
    canvas.drawLine(
      tip,
      tail,
      Paint()
        ..color = isAligned ? const Color(0xFF004400) : Colors.amber.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // محور ارتكاز دائري مدمج وأنيق
    canvas.drawCircle(
      center,
      7.0,
      Paint()
        ..color = isAligned ? const Color(0xFF00FF7F) : const Color(0xFFD4AF37),
    );
    canvas.drawCircle(center, 4.0, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant QiblaArrowPainter old) =>
      old.isAligned != isAligned;
}
