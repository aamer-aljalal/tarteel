import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';

/// [AnimatedAdhanBackground]
/// خلفية إسلامية تفاعلية ومتحركة مستوحاة من نداء الأذان:
/// - في الليل: سماء ليلية عميقة مع هلال منير ونجوم تتلألأ وشهب عابرة ومئذنة تصدح بموجات الأذان.
/// - في النهار: سماء نهارية واضحة ومشرقة مع شمس هادئة وغيوم لطيفة ومئذنة وقباب واضحة المعالم.
class AnimatedAdhanBackground extends StatefulWidget {
  final Widget child;

  /// تحديد يدوي هل الخلفية في الوضع الليلي (إذا تُرك فارغاً يستنتج من الثيم)
  final bool? isDark;

  /// إظهار موجات صدى الأذان المنبعثة
  final bool showSoundWaves;

  /// إظهار ذرات النور العائمة
  final bool showParticles;

  const AnimatedAdhanBackground({
    super.key,
    required this.child,
    this.isDark,
    this.showSoundWaves = true,
    this.showParticles = true,
  });

  @override
  State<AnimatedAdhanBackground> createState() =>
      _AnimatedAdhanBackgroundState();
}

class _AnimatedAdhanBackgroundState extends State<AnimatedAdhanBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_LightParticle> _particles;
  late final List<_StarData> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    final random = math.Random(777);

    // ذرات النور العائمة
    _particles = List.generate(24, (index) {
      return _LightParticle(
        xRatio: random.nextDouble(),
        yRatio: random.nextDouble(),
        size: 1.2 + random.nextDouble() * 2.0,
        speed: 0.5 + random.nextDouble() * 1.2,
        phase: random.nextDouble() * 2 * math.pi,
      );
    });

    // النجوم للوضع الليلي
    _stars = List.generate(42, (index) {
      return _StarData(
        xRatio: random.nextDouble(),
        yRatio: random.nextDouble() * 0.65,
        size: 1.0 + random.nextDouble() * 2.2,
        phase: random.nextDouble() * 2 * math.pi,
        twinkleSpeed: 0.7 + random.nextDouble() * 1.4,
        hasCrossGlint: index % 5 == 0,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark =
        widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. طبقة الرسم الرسومي المباشر
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _AdhanBackgroundPainter(
                  progress: _controller.value,
                  isDark: effectiveIsDark,
                  particles: _particles,
                  stars: _stars,
                  showSoundWaves: widget.showSoundWaves,
                  showParticles: widget.showParticles,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),

        // 2. محتوى الصفحة
        widget.child,
      ],
    );
  }
}

class _LightParticle {
  final double xRatio;
  final double yRatio;
  final double size;
  final double speed;
  final double phase;

  const _LightParticle({
    required this.xRatio,
    required this.yRatio,
    required this.size,
    required this.speed,
    required this.phase,
  });
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

class _AdhanBackgroundPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final List<_LightParticle> particles;
  final List<_StarData> stars;
  final bool showSoundWaves;
  final bool showParticles;

  _AdhanBackgroundPainter({
    required this.progress,
    required this.isDark,
    required this.particles,
    required this.stars,
    required this.showSoundWaves,
    required this.showParticles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawAtmosphereGradient(canvas, size);

    // موقع قمة المئذنة (مصدر انبعاث الأذان)
    final Offset minaretTop = Offset(size.width * 0.16, size.height * 0.46);

    if (isDark) {
      // عناصر الوضع الليلي: النجوم + الشهاب + الهلال
      _drawStars(canvas, size);
      _drawShootingStar(canvas, size);
      _drawNightCrescentMoon(canvas, size);
    } else {
      // عناصر الوضع النهاري: الشمس الهادئة + الغيوم اللطيفة
      _drawCalmDaySun(canvas, size);
      _drawDayClouds(canvas, size);
    }

    // موجات صدى الأذان المنبعثة
    if (showSoundWaves) {
      _drawAdhanEchoWaves(canvas, size, minaretTop);
    }

    // ذرات النور العائمة
    if (showParticles) {
      _drawFloatingLightParticles(canvas, size);
    }

    // المئذنة وقبة المسجد (واضحة وأنيقة في كلا الوضعين)
    _drawMosqueAndMinaret(canvas, size, minaretTop);
  }

  /// التدرج اللوني الأساسي للسماء
  void _drawAtmosphereGradient(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint();

    if (isDark) {
      // سماء ليلية فخمة وعميقة
      paint.shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xFF050E14),
          Color(0xFF091A23),
          Color(0xFF0B242C),
          Color(0xFF07131A),
        ],
        stops: [0.0, 0.38, 0.75, 1.0],
      ).createShader(rect);
    } else {
      // سماء نهارية حقيقية: زرقة سماوية صافية في الأعلى تتدفق إلى شروق دافئ مشرق
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

  /// رسم شمس نهارية هادئة ودافئة مع هالة نور تتنفس
  void _drawCalmDaySun(Canvas canvas, Size size) {
    final double sunX = size.width * 0.82;
    final double sunY = size.height * 0.12;
    final double sunRadius = 22.w;

    // نبض هادئ جداً لهالة الشمس
    final double pulse = math.sin(progress * 2 * math.pi) * 0.08;

    // 1. الهالة الخارجية الكبيرة المتوهجة
    final haloPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFCE198).withValues(alpha: 0.45 + pulse),
          const Color(0xFFF7CF76).withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(sunX, sunY),
          radius: size.width * (0.38 + pulse),
        ),
      );
    canvas.drawCircle(Offset(sunX, sunY), size.width * (0.38 + pulse), haloPaint);

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

  /// رسم غيوم نهارية رقيقة تتحرك في الأفق
  void _drawDayClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.42);

    final double move1 = (progress * size.width * 0.25) % (size.width + 140.w);
    final double c1X = move1 - 70.w;
    final double c1Y = size.height * 0.16;

    // غيمة أولى
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c1X, c1Y), width: 140.w, height: 26.h),
      cloudPaint,
    );

    // غيمة ثانية
    final double move2 =
        ((progress * size.width * 0.18) + size.width * 0.45) %
        (size.width + 160.w);
    final double c2X = move2 - 80.w;
    final double c2Y = size.height * 0.24;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(c2X, c2Y), width: 170.w, height: 30.h),
      cloudPaint..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  /// رسم النجوم المتلألئة في الليل
  void _drawStars(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;

    for (final star in stars) {
      final double x = star.xRatio * size.width;
      final double y = star.yRatio * size.height;

      final double pulse = math.sin(
        (progress * 2 * math.pi * star.twinkleSpeed) + star.phase,
      );
      final double opacity = (0.28 + 0.65 * ((pulse + 1) / 2)).clamp(0.0, 1.0);
      final double currentSize = star.size * (0.8 + 0.3 * pulse);

      starPaint.color = Colors.white.withValues(alpha: opacity * 0.88);
      canvas.drawCircle(Offset(x, y), currentSize, starPaint);

      if (star.hasCrossGlint && opacity > 0.62) {
        final glintPaint = Paint()
          ..color = const Color(0xFFD4AF37)
              .withValues(alpha: (opacity - 0.4) * 0.75)
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

  /// رسم شهاب عابر ليلي
  void _drawShootingStar(Canvas canvas, Size size) {
    final double cycle = (progress * 3.2) % 1.0;
    if (cycle > 0.22) return;

    final double t = cycle / 0.22;
    final double startX = size.width * 0.88;
    final double startY = size.height * 0.07;
    final double endX = size.width * 0.25;
    final double endY = size.height * 0.28;

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

  /// رسم هلال ليلي منير مع توهج ناعم
  void _drawNightCrescentMoon(Canvas canvas, Size size) {
    final double centerX = size.width * 0.84;
    final double centerY = size.height * 0.11;
    final double radius = 19.w;

    // توهج خفيف حول القمر
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE8D595).withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius * 3.0),
      );
    canvas.drawCircle(Offset(centerX, centerY), radius * 3.0, glowPaint);

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
          Color(0xFFFFF9E6),
          Color(0xFFE8C976),
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      );

    canvas.drawPath(crescent, moonPaint);
  }

  /// رسم موجات صدى الأذان المنبعثة من قمة المئذنة
  void _drawAdhanEchoWaves(Canvas canvas, Size size, Offset origin) {
    const int waveCount = 4;
    final double maxRadius = size.width * 0.88;

    for (int i = 0; i < waveCount; i++) {
      final double waveProgress = (progress + (i / waveCount)) % 1.0;
      final double radius = 30.w + (maxRadius * waveProgress);

      final double opacity =
          math.sin(waveProgress * math.pi).clamp(0.0, 1.0) *
          (isDark ? 0.40 : 0.32);

      if (opacity <= 0.01) continue;

      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 + (1.2 * (1.0 - waveProgress))
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            (isDark ? const Color(0xFFE5C158) : const Color(0xFFC79E32))
                .withValues(alpha: opacity * 0.95),
            (isDark ? Colors.teal : AppColors.primary)
                .withValues(alpha: opacity * 0.45),
            Colors.transparent,
          ],
          stops: const [0.72, 0.90, 1.0],
        ).createShader(Rect.fromCircle(center: origin, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: radius),
        -math.pi * 0.45,
        math.pi * 1.5,
        false,
        wavePaint,
      );
    }

    // هالة نور في شرفة المئذنة
    final double pulse = (math.sin(progress * 2 * math.pi) + 1) / 2;
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE5C158).withValues(alpha: 0.5 + 0.3 * pulse),
          const Color(0xFFD4AF37).withValues(alpha: 0.20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: origin, radius: 24.w));

    canvas.drawCircle(origin, 24.w, glowPaint);
  }

  /// رسم ذرات النور العائمة
  void _drawFloatingLightParticles(Canvas canvas, Size size) {
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final double x = p.xRatio * size.width;
      final double yOffset = (progress * p.speed * 0.15) % 1.0;
      final double y = ((p.yRatio - yOffset) % 1.0) * size.height;

      final double pulse =
          math.sin((progress * 2 * math.pi * p.speed) + p.phase);
      final double alpha = ((pulse + 1) / 2) * (isDark ? 0.48 : 0.35);

      particlePaint.color = (isDark
              ? const Color(0xFFE8D48E)
              : const Color(0xFFB5933C))
          .withValues(alpha: alpha);

      canvas.drawCircle(
        Offset(x, y),
        p.size * (0.8 + 0.3 * pulse),
        particlePaint,
      );
    }
  }

  /// رسم المئذنة وقبة المسجد بوضوح فائق وتصميم إسلامي راقٍ
  void _drawMosqueAndMinaret(Canvas canvas, Size size, Offset top) {
    // لون المسجد والمئذنة:
    // في الليل: كحلي داكن ملكي
    // في النهار: لون زمردي إسلامي غني وواضح (Crisp Emerald Teal) يبرز بدقة وفخامة
    final Color silhouetteColor = isDark
        ? const Color(0xFF040A0E).withValues(alpha: 0.52)
        : const Color(0xFF1B3D32).withValues(alpha: 0.28); // 👈 واضح وبارز وجميل جداً

    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = silhouetteColor;

    final double bottomY = size.height;
    final double mx = top.dx;
    final double mw = 22.w;

    // 1. رسم المئذنة
    final Path minaretPath = Path();

    // رأس المخروط
    minaretPath.moveTo(mx, top.dy - 20.h);
    minaretPath.lineTo(mx - 4.5.w, top.dy - 6.h);
    minaretPath.lineTo(mx + 4.5.w, top.dy - 6.h);
    minaretPath.close();

    // قبة المئذنة
    minaretPath.addOval(
      Rect.fromCenter(
        center: Offset(mx, top.dy - 2.h),
        width: 15.w,
        height: 13.h,
      ),
    );

    // شرفة الأذان (الدرابزين البارز)
    minaretPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(mx, top.dy + 8.h),
          width: 34.w,
          height: 9.h,
        ),
        Radius.circular(3.r),
      ),
    );

    // عمود المئذنة الممتد للأسفل
    final Path shaftPath = Path()
      ..moveTo(mx - mw * 0.72, top.dy + 12.h)
      ..lineTo(mx + mw * 0.72, top.dy + 12.h)
      ..lineTo(mx + mw, bottomY)
      ..lineTo(mx - mw, bottomY)
      ..close();

    canvas.drawPath(minaretPath, paint);
    canvas.drawPath(shaftPath, paint);

    // هلال ذهبي صغير في قمة المئذنة
    final finialPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFD4AF37).withValues(alpha: isDark ? 0.8 : 0.65);
    canvas.drawCircle(Offset(mx, top.dy - 22.h), 2.5.w, finialPaint);

    // 2. قبة المسجد في الأفق
    final double domeX = size.width * 0.55;
    final double domeRadius = size.width * 0.36;

    final Path domePath = Path();
    domePath.moveTo(domeX - domeRadius, bottomY);
    domePath.arcToPoint(
      Offset(domeX + domeRadius, bottomY),
      radius: Radius.circular(domeRadius),
      clockwise: true,
    );
    domePath.close();

    canvas.drawPath(domePath, paint);
  }

  @override
  bool shouldRepaint(covariant _AdhanBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.showSoundWaves != showSoundWaves ||
        oldDelegate.showParticles != showParticles;
  }
}
