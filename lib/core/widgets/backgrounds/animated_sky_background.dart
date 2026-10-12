import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// [AnimatedSkyBackground]
/// خلفية إسلامية تفاعلية ومتحركة بتقنية الرسم المباشر (CustomPainter)
/// تتكيف بسلاسة تامة بين أذكار الصباح والمساء والوضع الليلي والنهاري.
class AnimatedSkyBackground extends StatefulWidget {
  final Widget child;

  /// تحديد يدوي هل الخلفية ليلية أم نهارية (إذا تُرك فارغاً يُستنتج تلقائياً)
  final bool? isNight;

  /// عنوان القسم (مثل: "أذكار الصباح" أو "أذكار المساء") للاستنتاج التلقائي
  final String? categoryTitle;

  /// إظهار الهلال في الوضع الليلي
  final bool showCrescent;

  /// إظهار النجوم المتلألئة
  final bool showStars;

  /// إظهار ظلال قباب ومآذن المسجد في الأفق السفلي
  final bool showMosqueSilhouette;

  const AnimatedSkyBackground({
    super.key,
    required this.child,
    this.isNight,
    this.categoryTitle,
    this.showCrescent = true,
    this.showStars = true,
    this.showMosqueSilhouette = true,
  });

  @override
  State<AnimatedSkyBackground> createState() => _AnimatedSkyBackgroundState();
}

class _AnimatedSkyBackgroundState extends State<AnimatedSkyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_StarData> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    // إنشاء مصفوفة نجوم بمواقع ثابتة ولكن متنوعة
    final random = math.Random(786);
    _stars = List.generate(45, (index) {
      return _StarData(
        xRatio: random.nextDouble(),
        yRatio: random.nextDouble() * 0.72, // مركزة في النصف العلوي والمتوسط
        size: 1.0 + random.nextDouble() * 2.2,
        phase: random.nextDouble() * 2 * math.pi,
        twinkleSpeed: 0.6 + random.nextDouble() * 1.4,
        hasCrossGlint: index % 6 == 0,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _resolveIsNight(BuildContext context) {
    if (widget.isNight != null) return widget.isNight!;

    if (widget.categoryTitle != null) {
      final t = widget.categoryTitle!;
      if (t.contains('المساء') ||
          t.contains('النوم') ||
          t.contains('الآذان') ||
          t.contains('الليل')) {
        return true;
      }
      if (t.contains('الصباح') ||
          t.contains('الاستيقاظ') ||
          t.contains('الصلاة')) {
        return false;
      }
    }

    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isNight = _resolveIsNight(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. خلفية السماء المتدرجة + الرسوم المتحركة
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _SkyPainter(
                  progress: _controller.value,
                  isNight: isNight,
                  stars: _stars,
                  showStars: widget.showStars,
                  showCrescent: widget.showCrescent,
                  showSilhouette: widget.showMosqueSilhouette,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),

        // 2. المحتوى فوق الخلفية
        widget.child,
      ],
    );
  }
}

class _StarData {
  final double xRatio;
  final double yRatio;
  final double size;
  final double phase;
  final double twinkleSpeed;
  final bool hasCrossGlint;

  const _StarData({
    required this.xRatio,
    required this.yRatio,
    required this.size,
    required this.phase,
    required this.twinkleSpeed,
    required this.hasCrossGlint,
  });
}

class _SkyPainter extends CustomPainter {
  final double progress;
  final bool isNight;
  final List<_StarData> stars;
  final bool showStars;
  final bool showCrescent;
  final bool showSilhouette;

  _SkyPainter({
    required this.progress,
    required this.isNight,
    required this.stars,
    required this.showStars,
    required this.showCrescent,
    required this.showSilhouette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawSkyGradient(canvas, size);

    if (isNight) {
      if (showStars) {
        _drawStars(canvas, size);
        _drawShootingStar(canvas, size);
      }
      if (showCrescent) {
        _drawCrescent(canvas, size);
      }
    } else {
      _drawCalmDaySun(canvas, size);
      _drawMorningClouds(canvas, size);
    }

    if (showSilhouette) {
      _drawMosqueSilhouette(canvas, size);
    }
  }

  /// رسم التدرج اللوني للسماء
  void _drawSkyGradient(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint();

    if (isNight) {
      // سماء ليلية ملكية عميقة بتدرج إسلامي متناسق
      paint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF070F14), // ليل عميق
          Color(0xFF0C1921), // كحلي مائل للخضرة الإسلامية الخافتة
          Color(0xFF10222B),
          Color(0xFF0A141A),
        ],
        stops: [0.0, 0.4, 0.75, 1.0],
      ).createShader(rect);
    } else {
      // سماء صباحية نقية ودافئة: زرقة سماوية صافية في الأعلى تتدفق إلى شروق دافئ مشرق
      paint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFB9DBEB), // زرقة سماوية صافية ومنعشة
          Color(0xFFD4E9F2),
          Color(0xFFF3ECE0), // أفق دافئ مشرق بنور الصباح
          Color(0xFFF8F4EC),
        ],
        stops: [0.0, 0.35, 0.72, 1.0],
      ).createShader(rect);
    }

    canvas.drawRect(rect, paint);
  }

  /// رسم النجوم المتلألئة
  void _drawStars(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;

    for (final star in stars) {
      final double x = star.xRatio * size.width;
      final double y = star.yRatio * size.height;

      // حساب وميض النجم بحركة جيبية هادئة (Pulse)
      final double pulse = math.sin(
        (progress * 2 * math.pi * star.twinkleSpeed) + star.phase,
      );
      final double opacity = (0.25 + 0.65 * ((pulse + 1) / 2)).clamp(0.0, 1.0);
      final double currentSize = star.size * (0.8 + 0.3 * pulse);

      starPaint.color = Colors.white.withValues(alpha: opacity * 0.85);
      canvas.drawCircle(Offset(x, y), currentSize, starPaint);

      // بريق متقاطع ناعم للنجوم البارزة
      if (star.hasCrossGlint && opacity > 0.6) {
        final glintPaint = Paint()
          ..color = const Color(0xFFD4AF37)
              .withValues(alpha: (opacity - 0.4) * 0.7)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;

        final double glintLen = currentSize * 2.8;
        canvas.drawLine(
          Offset(x - glintLen, y),
          Offset(x + glintLen, y),
          glintPaint,
        );
        canvas.drawLine(
          Offset(x, y - glintLen),
          Offset(x, y + glintLen),
          glintPaint,
        );
      }
    }
  }

  /// رسم شهاب عابر كل بضع ثوانٍ
  void _drawShootingStar(Canvas canvas, Size size) {
    // الشهاب يظهر في دورة محددة من الأنيميشن
    final double cycle = (progress * 3) % 1.0;
    if (cycle > 0.22) return; // يمر في فترة وجيزة ثم يختفي

    final double t = cycle / 0.22;
    final double startX = size.width * 0.85;
    final double startY = size.height * 0.08;
    final double endX = size.width * 0.15;
    final double endY = size.height * 0.32;

    final double currentX = startX + (endX - startX) * t;
    final double currentY = startY + (endY - startY) * t;
    final double tailLen = 45.w;

    final double tailX = currentX + tailLen * 0.9;
    final double tailY = currentY - tailLen * 0.4;

    final double alpha = math.sin(t * math.pi).clamp(0.0, 1.0);

    final Paint shootPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: alpha * 0.9),
          const Color(0xFFD4AF37).withValues(alpha: alpha * 0.4),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromPoints(Offset(currentX, currentY), Offset(tailX, tailY)),
      );

    canvas.drawLine(
      Offset(currentX, currentY),
      Offset(tailX, tailY),
      shootPaint,
    );
  }

  /// رسم هلال إسلامي ناعم ومتوهج
  void _drawCrescent(Canvas canvas, Size size) {
    final double centerX = size.width * 0.84;
    final double centerY = size.height * 0.11;
    final double radius = 18.w;

    // توهج خفيف حول القمر
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE8D595).withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius * 2.8),
      );
    canvas.drawCircle(Offset(centerX, centerY), radius * 2.8, glowPaint);

    // الهلال عبر تفريغ دائرتين متداخلتين (Path.combine)
    final Path moonPath = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      );

    final Path shadowPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(centerX - radius * 0.55, centerY - radius * 0.2),
          radius: radius * 0.95,
        ),
      );

    final Path crescent = Path.combine(
      PathOperation.difference,
      moonPath,
      shadowPath,
    );

    final moonPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFF7DB),
          Color(0xFFE6C673),
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      );

    canvas.drawPath(crescent, moonPaint);
  }

  /// رسم شمس نهارية هادئة ودافئة مع قرص مشرق وهالة نور تتنفس
  void _drawCalmDaySun(Canvas canvas, Size size) {
    final double sunX = size.width * 0.82;
    final double sunY = size.height * 0.12;
    final double sunRadius = 22.w;

    // نبض بطيء جداً للأشعة
    final double breathe = math.sin(progress * 2 * math.pi) * 0.08;

    // 1. الهالة الخارجية الكبيرة المتوهجة
    final haloPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFCE198).withValues(alpha: 0.45 + breathe),
          const Color(0xFFF7CF76).withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(sunX, sunY),
          radius: size.width * (0.38 + breathe),
        ),
      );
    canvas.drawCircle(Offset(sunX, sunY), size.width * (0.38 + breathe), haloPaint);

    // 2. الهالة الوسطى المشرقة
    final innerHaloPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF0B8).withValues(alpha: 0.7),
          const Color(0xFFFDD475).withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(sunX, sunY),
          radius: sunRadius * 2.2,
        ),
      );
    canvas.drawCircle(Offset(sunX, sunY), sunRadius * 2.2, innerHaloPaint);

    // 3. قرص الشمس الذهبي الدافئ
    final sunDiscPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFBE8),
          Color(0xFFF9D874),
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(sunX, sunY), radius: sunRadius),
      );
    canvas.drawCircle(Offset(sunX, sunY), sunRadius, sunDiscPaint);
  }

  /// رسم غيوم صباحية خفيفة متعددة الطبقات تتحرك ببطء
  void _drawMorningClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.42);

    final double move1 = (progress * size.width * 0.25) % (size.width + 140.w);

    // سحابة أولى بطبقات ناعمة
    final double c1X = move1 - 70.w;
    final double c1Y = size.height * 0.16;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c1X, c1Y),
        width: 140.w,
        height: 26.h,
      ),
      cloudPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c1X + 22.w, c1Y - 7.h),
        width: 70.w,
        height: 22.h,
      ),
      cloudPaint,
    );

    // سحابة ثانية في أفق أوسع
    final double move2 =
        ((progress * size.width * 0.16) + size.width * 0.52) %
        (size.width + 170.w);
    final double c2X = move2 - 85.w;
    final double c2Y = size.height * 0.26;
    final cloudPaint2 = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.30);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c2X, c2Y),
        width: 160.w,
        height: 28.h,
      ),
      cloudPaint2,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c2X - 25.w, c2Y - 7.h),
        width: 80.w,
        height: 24.h,
      ),
      cloudPaint2,
    );
  }

  /// رسم ظلال المسجد الإسلامي (Mosque Silhouette) في الأفق السفلي
  void _drawMosqueSilhouette(Canvas canvas, Size size) {
    final double horizonY = size.height;
    final double w = size.width;

    // لون الظلال: في الليل كحلي عميق، وفي النهار أخضر زمردي إسلامي وقور وواضح
    final Color silhouetteColor = isNight
        ? const Color(0xFF03070A).withValues(alpha: 0.42)
        : const Color(0xFF1B3D32).withValues(alpha: 0.28);

    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = silhouetteColor;

    final Path path = Path();
    path.moveTo(0, horizonY);

    // خط الأساس السفلي
    path.lineTo(0, horizonY - 30.h);

    // مئذنة يسارية جانبية
    path.lineTo(w * 0.08, horizonY - 30.h);
    path.lineTo(w * 0.085, horizonY - 80.h);
    path.lineTo(w * 0.095, horizonY - 95.h); // رأس المئذنة
    path.lineTo(w * 0.105, horizonY - 80.h);
    path.lineTo(w * 0.11, horizonY - 30.h);

    // قبة صغرى
    path.lineTo(w * 0.22, horizonY - 30.h);
    path.arcToPoint(
      Offset(w * 0.34, horizonY - 30.h),
      radius: Radius.circular(26.r),
      clockwise: false,
    );

    // مئذنة متوسطة
    path.lineTo(w * 0.38, horizonY - 30.h);
    path.lineTo(w * 0.385, horizonY - 105.h);
    path.lineTo(w * 0.395, horizonY - 120.h); // رأس المئذنة
    path.lineTo(w * 0.405, horizonY - 105.h);
    path.lineTo(w * 0.41, horizonY - 30.h);

    // القبة المركزية الكبرى
    path.lineTo(w * 0.46, horizonY - 30.h);
    path.arcToPoint(
      Offset(w * 0.62, horizonY - 30.h),
      radius: Radius.circular(42.r),
      clockwise: false,
    );

    // قبة يمنى
    path.lineTo(w * 0.70, horizonY - 30.h);
    path.arcToPoint(
      Offset(w * 0.82, horizonY - 30.h),
      radius: Radius.circular(26.r),
      clockwise: false,
    );

    // مئذنة يمينية كبرى
    path.lineTo(w * 0.86, horizonY - 30.h);
    path.lineTo(w * 0.865, horizonY - 90.h);
    path.lineTo(w * 0.875, horizonY - 108.h);
    path.lineTo(w * 0.885, horizonY - 90.h);
    path.lineTo(w * 0.89, horizonY - 30.h);

    path.lineTo(w, horizonY - 30.h);
    path.lineTo(w, horizonY);
    path.close();

    canvas.drawPath(path, paint);

    // لمسة إسلامية جمالية: هلال ذهبي خفيف فوق قمة القبة المركزية
    final double finialX = w * 0.54;
    final double finialY = horizonY - 73.h;
    final finialPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = (isNight
              ? const Color(0xFFD4AF37)
              : const Color(0xFFC59B27))
          .withValues(alpha: isNight ? 0.65 : 0.45);
    canvas.drawCircle(Offset(finialX, finialY), 3.r, finialPaint);
    canvas.drawCircle(Offset(w * 0.395, horizonY - 122.h), 2.2.r, finialPaint);
    canvas.drawCircle(Offset(w * 0.875, horizonY - 110.h), 2.2.r, finialPaint);
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isNight != isNight ||
        oldDelegate.showStars != showStars ||
        oldDelegate.showCrescent != showCrescent ||
        oldDelegate.showSilhouette != showSilhouette;
  }
}
