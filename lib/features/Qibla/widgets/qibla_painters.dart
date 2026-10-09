import 'dart:math' as math;
import 'package:flutter/material.dart';

// ======= رسام حلقة البوصلة =======
class CompassRingPainter extends CustomPainter {
  final bool isDark;
  CompassRingPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

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
      final len = isMain
          ? 24.0
          : isSub
          ? 16.0
          : 10.0;
      final sw = isMain ? 3.0 : 1.5;

      // جعل لون الأسنان جميعها أصفر (أو درجات الذهبي) كما طلب المستخدم
      final color = isMain ? const Color(0xFFFFD700) : Colors.amber.shade400;

      final start = Offset(
        center.dx + (radius - len) * math.cos(rad),
        center.dy + (radius - len) * math.sin(rad),
      );
      final end = Offset(
        center.dx + radius * math.cos(rad),
        center.dy + radius * math.sin(rad),
      );
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
      final tr = radius - 42; // تحريك الحروف للداخل قليلاً بسبب تكبير الأسنان
      final span = TextSpan(
        text: label,
        style: TextStyle(
          // جعل كل الحروف بلون أحمر مميز ومضيء لتبرز على الخلفية السوداء
          color: Colors.redAccent.shade400,
          fontSize: 18,
          fontWeight: FontWeight.bold,
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
  bool shouldRepaint(covariant CompassRingPainter old) => old.isDark != isDark;
}

// ======= رسام سهم القبلة =======
class QiblaArrowPainter extends CustomPainter {
  final bool isAligned;
  QiblaArrowPainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final arrowLen = size.width / 2 - 30;

    // السهم يشير دائماً للأعلى (زاوية القبلة في إطار الرسم بعد تدويره)
    final tip = Offset(center.dx, center.dy - arrowLen);

    // شكل المعين (إبرة البوصلة الكلاسيكية)
    final midLeft = Offset(center.dx - 22, center.dy);
    final midRight = Offset(center.dx + 22, center.dy);
    final tail = Offset(
      center.dx,
      center.dy + arrowLen * 0.45,
    ); // الذيل أقصر من الرأس لتمييز الاتجاه

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(midRight.dx, midRight.dy)
      ..lineTo(tail.dx, tail.dy)
      ..lineTo(midLeft.dx, midLeft.dy)
      ..close();

    // التوهج (الظل) حول المثلث
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.amber.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // المثلث الأصفر الأساسي
    canvas.drawPath(
      path,
      Paint()
        ..color = isAligned ? const Color(0xFFFFD700) : Colors.amber.shade500
        ..style = PaintingStyle.fill,
    );

    // حد للمثلث ليعطيه شكلاً أنيقاً
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.amber.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // خط في المنتصف لإعطاء إيحاء طية البوصلة الكلاسيكية (3D)
    canvas.drawLine(
      tip,
      tail,
      Paint()
        ..color = Colors.amber.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // دائرة مركزية
    canvas.drawCircle(center, 14, Paint()..color = const Color(0xFFD4AF37));
    canvas.drawCircle(center, 9, Paint()..color = Colors.white);

    // أيقونة الكعبة الصغيرة في المركز
    final kaabaPaint = Paint()..color = const Color(0xFF2E2E2E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 10, height: 10),
        const Radius.circular(2),
      ),
      kaabaPaint,
    );
  }

  @override
  bool shouldRepaint(covariant QiblaArrowPainter old) =>
      old.isAligned != isAligned;
}
