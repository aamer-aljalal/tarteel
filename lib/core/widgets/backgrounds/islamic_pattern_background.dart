import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tarteel/core/providers/theme_provider.dart';

/// [IslamicPatternBackground]
/// «محراب النور والمصحف الشريف» (Sanctuary of Light & Holy Quran)
/// خلفية إسلامية معمارية متقنة وفائقة الجمال:
/// - قمة المحراب: شمس إسلامية ذهبية مشعة في النهار ☀️ تتحول إلى قمر وهلال منير في الليل 🌙.
/// - قلب المحراب: مصحف شريف مفتوح على حامل خشبي أصيل (الرحلة) ينبثق من صفحاته نور هادئ 📖.
/// - تأطير المحراب: قوس أندلسي مفصص مدبب يستند على عمودين رخاميين جانبيين بتيجان إسلامية 🏛️.
/// - قناديل إسلامية مضيئة على جانبي القوس تتدلى بسلاسل ذهبية 🪔.
/// - وضوح فائق وعالي التباين في الوضع النهاري، مع سكينة وفخامة مريحة للعين في كلا الوضعين.
class IslamicPatternBackground extends StatefulWidget {
  final Widget child;

  /// إمكانية إجبار تفعيل أو إيقاف الخلفية يدوياً (اختياري)
  final bool? forceEnabled;

  const IslamicPatternBackground({
    super.key,
    required this.child,
    this.forceEnabled,
  });

  @override
  State<IslamicPatternBackground> createState() =>
      _IslamicPatternBackgroundState();
}

class _IslamicPatternBackgroundState extends State<IslamicPatternBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_SanctuaryParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    final random = math.Random(777);
    _particles = List.generate(22, (index) {
      return _SanctuaryParticle(
        xRatio: 0.12 + random.nextDouble() * 0.76,
        yRatio: random.nextDouble(),
        size: 1.6 + random.nextDouble() * 2.8,
        speed: 0.35 + random.nextDouble() * 0.55,
        phase: random.nextDouble() * 2 * math.pi,
        isGold: index % 2 == 0,
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isEnabled =
        widget.forceEnabled ?? themeProvider.isPatternBackgroundEnabled;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isEnabled) {
      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: widget.child,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // لوحة رسم محراب المسجد والمصحف الشريف
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _MihrabQuranSanctuaryPainter(
                  progress: _controller.value,
                  isDark: isDark,
                  particles: _particles,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),

        // المحتوى التفاعلي (أزرار وشبكة التطبيق)
        widget.child,
      ],
    );
  }
}

class _SanctuaryParticle {
  final double xRatio;
  final double yRatio;
  final double size;
  final double speed;
  final double phase;
  final bool isGold;

  const _SanctuaryParticle({
    required this.xRatio,
    required this.yRatio,
    required this.size,
    required this.speed,
    required this.phase,
    required this.isGold,
  });
}

class _MihrabQuranSanctuaryPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final List<_SanctuaryParticle> particles;

  _MihrabQuranSanctuaryPainter({
    required this.progress,
    required this.isDark,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width * 0.5;
    final double apexY = 48.h;

    // 1. التدرج الرخامي النقي للأرضية
    _drawAtmosphereCanvas(canvas, size);

    // 2. هالة النور المنبثقة من أعلى المحراب
    _drawAmbientMihrabGlow(canvas, size, Offset(cx, apexY));

    // 3. قمة المحراب: شمس إسلامية ذهبية في النهار ☀️ وقمر وهلال في الليل 🌙
    _drawApexCelestialEmblem(canvas, Offset(cx, apexY));

    // 4. أقواس المحراب المفصصة الأندلسية (واضحة وعالية التباين)
    _drawCuspedMihrabArches(canvas, size, cx, apexY);

    // 5. العمودان الرخاميان الجانبيان المؤطران للشاشة
    _drawTwinSanctuaryColumns(canvas, size, apexY);

    // 6. القناديل الإسلامية المعلقة على جانبي القوس
    _drawSideHangingLanterns(canvas, size, cx, apexY);

    // 7. المصحف الشريف المفتوح على الحامل الخشبي في وسط المحراب تماماً
    final double quranCenterY = size.height * 0.42;
    _drawOpenHolyQuran(canvas, Offset(cx, quranCenterY));

    // 8. ذرات النور العائمة
    _drawFloatingSparks(canvas, size);
  }

  /// 1. التدرج الرخامي الأساسي
  void _drawAtmosphereCanvas(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint();

    if (isDark) {
      paint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF03090C),
          Color(0xFF06151B),
          Color(0xFF092128),
          Color(0xFF040E12),
        ],
        stops: [0.0, 0.35, 0.75, 1.0],
      ).createShader(rect);
    } else {
      // رخام زمردي نعناعي نقي ومشرق يتصل بالترويسة العلوية بانسجام تام
      paint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFD6EDE5),
          Color(0xFFE5F5EF),
          Color(0xFFF2FAF6),
          Color(0xFFE2F3EC),
        ],
        stops: [0.0, 0.25, 0.70, 1.0],
      ).createShader(rect);
    }

    canvas.drawRect(rect, paint);
  }

  /// 2. هالة النور في عمق المحراب
  void _drawAmbientMihrabGlow(Canvas canvas, Size size, Offset apex) {
    final double breathe = math.sin(progress * 2 * math.pi) * 0.12;

    final Paint glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: isDark
            ? [
                const Color(0xFFFAD782).withValues(alpha: 0.32 + breathe),
                const Color(0xFF267359).withValues(alpha: 0.14),
                Colors.transparent,
              ]
            : [
                const Color(0xFFFFF0B3).withValues(alpha: 0.55 + breathe),
                const Color(0xFF86D8AB).withValues(alpha: 0.18),
                Colors.transparent,
              ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Rect.fromCircle(center: apex, radius: 155.w));

    canvas.drawCircle(apex, 155.w, glowPaint);
  }

  /// 3. قمة المحراب: شمس إسلامية ذهبية في النهار ☀️ أو قمر وهلال منير في الليل 🌙
  void _drawApexCelestialEmblem(Canvas canvas, Offset center) {
    final double pulse = math.sin(progress * 2 * math.pi) * 0.08;
    final double radius = 18.r;

    if (!isDark) {
      // ☀️ الشمس الإسلامية الذهبية المشعة (في الوضع النهاري)
      // أ. هالة الشمس الخارجية
      final sunGlowPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFDE596).withValues(alpha: 0.55 + pulse),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 2.2));
      canvas.drawCircle(center, radius * 2.2, sunGlowPaint);

      // ب. أشعة الشمس الهندسية (12 شعاعاً إسلامياً ذهبياً)
      final rayPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFB58416).withValues(alpha: 0.75);

      for (int i = 0; i < 12; i++) {
        final double angle = (i * math.pi / 6) + (progress * 0.3);
        final double innerR = radius * 1.15;
        final double outerR = (i % 2 == 0) ? radius * 1.75 : radius * 1.45;
        canvas.drawLine(
          Offset(
            center.dx + innerR * math.cos(angle),
            center.dy + innerR * math.sin(angle),
          ),
          Offset(
            center.dx + outerR * math.cos(angle),
            center.dy + outerR * math.sin(angle),
          ),
          rayPaint,
        );
      }

      // ج. قرص الشمس الذهبي المشرق
      final sunPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBE8), Color(0xFFF8CF60), Color(0xFFEAA228)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, sunPaint);

      // إطار ذهبي محفور
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF9E7112),
      );

      // شمسة ثمانية صغيرة في قلب الشمس
      _drawMiniEightStar(
        canvas,
        center,
        radius * 0.52,
        const Color(0xFF8A620F),
      );
    } else {
      // 🌙 الهلال والنجمة الإسلامية اللامعة (في الوضع الليلي)
      // أ. هالة القمر الفضية الذهبية
      final moonGlowPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF7E49D).withValues(alpha: 0.40 + pulse),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 2.4));
      canvas.drawCircle(center, radius * 2.4, moonGlowPaint);

      // ب. رسم الهلال عبر تقاطع دائرتين
      final Path moonPath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: radius));
      final Path shadowPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(
              center.dx - radius * 0.52,
              center.dy - radius * 0.22,
            ),
            radius: radius * 0.94,
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
          colors: [Color(0xFFFFF7DD), Color(0xFFEFD277)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawPath(crescent, moonPaint);

      // ج. نجمة خماسية ذهبية تتلألأ أمام الهلال
      final Offset starPos = Offset(
        center.dx + radius * 0.38,
        center.dy - radius * 0.22,
      );
      _drawMiniStar(canvas, starPos, 4.5.r, const Color(0xFFFFF2C2));
    }
  }

  /// 4. رسم أقواس المحراب المفصصة الأندلسية (Cusped Moorish Arches)
  void _drawCuspedMihrabArches(
    Canvas canvas,
    Size size,
    double cx,
    double apexY,
  ) {
    final double bottomY = size.height;

    // ألوان فائقة الوضوح والتباين في النهار والليل
    final Color goldColor = isDark
        ? const Color(0xFFE2C26E).withValues(alpha: 0.65)
        : const Color(0xFF9E7112).withValues(alpha: 0.52);

    final Color emeraldColor = isDark
        ? const Color(0xFF288565).withValues(alpha: 0.55)
        : const Color(0xFF135237).withValues(alpha: 0.45);

    // أ. القوس الداخلي الرئيسي
    final double innerSpan = size.width * 0.41;
    final double innerHeight = 160.h;
    final Path innerArch = _createPointedArchPath(
      cx,
      apexY + 12.h,
      innerSpan,
      innerHeight,
      bottomY,
    );

    // خط ذهبي محفور وواضح
    final Paint goldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = goldColor;
    canvas.drawPath(innerArch, goldStroke);

    // خط زمردي موازٍ
    final Paint emeraldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = emeraldColor;
    canvas.drawPath(innerArch, emeraldStroke);

    // ب. تفصيصات القوس الأندلسي (Scalloped Cusps - تسننات معمارية فخمة)
    _drawArchCusps(canvas, cx, apexY + 12.h, innerSpan, innerHeight, goldColor);

    // ج. القوس الخارجي الكبير المؤطر
    final double outerSpan = size.width * 0.47;
    final double outerHeight = 195.h;
    final Path outerArch = _createPointedArchPath(
      cx,
      apexY - 14.h,
      outerSpan,
      outerHeight,
      bottomY,
    );

    canvas.drawPath(
      outerArch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = goldColor.withValues(alpha: (goldColor.a * 0.7)),
    );
  }

  /// رسم مسار القوس الإسلامي المدبب
  Path _createPointedArchPath(
    double cx,
    double topY,
    double span,
    double height,
    double bottomY,
  ) {
    final Path path = Path();
    final double shoulderY = topY + height * 0.38;
    final double leftX = cx - span;
    final double rightX = cx + span;

    path.moveTo(leftX, bottomY);
    path.lineTo(leftX, shoulderY);
    path.cubicTo(
      leftX,
      shoulderY - height * 0.14,
      cx - span * 0.36,
      topY + height * 0.05,
      cx,
      topY,
    );
    path.cubicTo(
      cx + span * 0.36,
      topY + height * 0.05,
      rightX,
      shoulderY - height * 0.14,
      rightX,
      shoulderY,
    );
    path.lineTo(rightX, bottomY);

    return path;
  }

  /// تفصيصات القوس الأندلسي (Cusps)
  void _drawArchCusps(
    Canvas canvas,
    double cx,
    double topY,
    double span,
    double height,
    Color color,
  ) {
    final Paint cuspPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    // دوائر زخرفية بارزة على مسار القوس
    const int count = 9;
    for (int i = 0; i < count; i++) {
      final double t = (i + 1) / (count + 1);
      final double sideSpan = span * (1.0 - t * 0.6);
      final double currentY =
          topY + height * 0.38 * (1.0 - math.sin(t * math.pi * 0.5));

      canvas.drawCircle(Offset(cx - sideSpan, currentY), 2.2.r, cuspPaint);
      canvas.drawCircle(Offset(cx + sideSpan, currentY), 2.2.r, cuspPaint);
    }
  }

  /// 5. العمودان الرخاميان الجانبيان المؤطران للشاشة (Twin Sanctuary Columns)
  void _drawTwinSanctuaryColumns(Canvas canvas, Size size, double apexY) {
    final double colTopY = apexY + 70.h;
    final double colBottomY = size.height;
    final double leftX = 14.w;
    final double rightX = size.width - 14.w;
    final double colWidth = 6.w;

    final Color colColor = isDark
        ? const Color(0xFFD4AF37).withValues(alpha: 0.38)
        : const Color(0xFF14532D).withValues(alpha: 0.28);

    final Paint colPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = colColor;

    for (final x in [leftX, rightX]) {
      // عمودان رأسيان بخطين متوازيين (Pinstripe Column Shaft)
      canvas.drawLine(
        Offset(x - colWidth / 2, colTopY),
        Offset(x - colWidth / 2, colBottomY),
        colPaint,
      );
      canvas.drawLine(
        Offset(x + colWidth / 2, colTopY),
        Offset(x + colWidth / 2, colBottomY),
        colPaint,
      );

      // تاج العمود الزخرفي (Capital at the top)
      final Path capital = Path();
      capital.moveTo(x - colWidth * 1.5, colTopY);
      capital.lineTo(x + colWidth * 1.5, colTopY);
      capital.lineTo(x + colWidth, colTopY + 8.h);
      capital.lineTo(x - colWidth, colTopY + 8.h);
      capital.close();
      canvas.drawPath(
        capital,
        Paint()
          ..style = PaintingStyle.fill
          ..color = (isDark ? const Color(0xFFD4AF37) : const Color(0xFF9E7112))
              .withValues(alpha: 0.45),
      );
    }
  }

  /// 6. القناديل المعلقة على جانبي القوس
  void _drawSideHangingLanterns(
    Canvas canvas,
    Size size,
    double cx,
    double apexY,
  ) {
    final double lanternSpan = size.width * 0.32;
    final double lanternY = apexY + 75.h;

    _drawSingleLantern(canvas, Offset(cx - lanternSpan, lanternY));
    _drawSingleLantern(canvas, Offset(cx + lanternSpan, lanternY));
  }

  void _drawSingleLantern(Canvas canvas, Offset pos) {
    final double breathe = math.sin(progress * 2 * math.pi) * 0.12;

    final Paint goldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = (isDark ? const Color(0xFFE2C26E) : const Color(0xFF9E7112))
          .withValues(alpha: 0.70);

    // سلسلة التعليق
    canvas.drawLine(
      Offset(pos.dx, 0),
      Offset(pos.dx, pos.dy - 8.h),
      goldPaint..strokeWidth = 0.8,
    );

    // زجاج القنديل المضيء
    final Rect rect = Rect.fromCenter(center: pos, width: 12.w, height: 15.h);
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.95),
          const Color(0xFFF9D874).withValues(alpha: 0.75 + breathe),
          const Color(0xFFEAA626).withValues(alpha: 0.30),
        ],
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(3.r)),
      glowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(3.r)),
      goldPaint,
    );

    // رأس وقاعدة القنديل
    final Path cap = Path()
      ..moveTo(pos.dx, pos.dy - 12.h)
      ..lineTo(pos.dx - 7.w, pos.dy - 7.h)
      ..lineTo(pos.dx + 7.w, pos.dy - 7.h)
      ..close();
    canvas.drawPath(
      cap,
      Paint()
        ..style = PaintingStyle.fill
        ..color = (isDark ? const Color(0xFFD4AF37) : const Color(0xFF9E7112))
            .withValues(alpha: 0.65),
    );
  }

  /// 7. المصحف الشريف المفتوح على الحامل الخشبي (الرحلة) في قلب المحراب 📖
  void _drawOpenHolyQuran(Canvas canvas, Offset center) {
    final double breathe = math.sin(progress * 2 * math.pi) * 0.15;
    final double quranWidth = 98.w;
    final double halfW = quranWidth * 0.5;

    // -------------------------------------------------------------
    // أ. أشعة النور الإلهي المنبثقة من صفحات المصحف للأعلى ("نور على نور")
    // -------------------------------------------------------------
    final quranGlowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFFFFF4C2) : const Color(0xFFFFFDE0))
              .withValues(alpha: 0.65 + breathe),
          (isDark ? const Color(0xFFF8D168) : const Color(0xFF90DCB1))
              .withValues(alpha: 0.22),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: quranWidth * 1.4));

    canvas.drawCircle(center, quranWidth * 1.4, quranGlowPaint);

    // حزمة أشعة نورانية صاعدة
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          (isDark ? const Color(0xFFFDE494) : const Color(0xFFB4EAC9))
              .withValues(alpha: 0.50 + breathe * 0.5),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromPoints(
          Offset(center.dx, center.dy),
          Offset(center.dx, center.dy - 65.h),
        ),
      );

    for (int i = -3; i <= 3; i++) {
      final double rayAngle = -math.pi / 2 + (i * 0.18);
      final double rayLen = 48.h + (i.abs() == 0 ? 16.h : 0);
      rayPaint.strokeWidth = (i == 0) ? 2.0 : 1.2;
      canvas.drawLine(
        Offset(center.dx + (i * 6.w), center.dy - 6.h),
        Offset(
          center.dx + rayLen * math.cos(rayAngle),
          center.dy + rayLen * math.sin(rayAngle),
        ),
        rayPaint,
      );
    }

    // -------------------------------------------------------------
    // ب. الحامل الخشبي الإسلامي التقليدي (الرَّحْل - Carved Wooden Rahl)
    // -------------------------------------------------------------
    final double rahlY = center.dy + 8.h;

    // ظل خفيف تحت الحامل على الأرضية الرخامية
    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: isDark ? 0.40 : 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, rahlY + 30.h),
        width: quranWidth * 0.95,
        height: 12.h,
      ),
      shadowPaint,
    );

    // لون خشب الجوز المذهب
    final Paint woodBack = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF42220F), const Color(0xFF2E170A)]
            : [const Color(0xFF6B3E1E), const Color(0xFF4A2A14)],
      ).createShader(Rect.fromLTWH(center.dx - halfW, rahlY, quranWidth, 36.h));

    final Paint woodFront = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isDark
            ? [const Color(0xFF63361A), const Color(0xFF3F210F)]
            : [const Color(0xFF8B5128), const Color(0xFF5D3519)],
      ).createShader(Rect.fromLTWH(center.dx - halfW, rahlY, quranWidth, 36.h));

    // الساق الخلفية (مائلة من اليسار للأعلى إلى اليمين للأسفل)
    final Path backLeg = Path();
    backLeg.moveTo(center.dx - halfW * 0.62, rahlY - 10.h);
    backLeg.lineTo(center.dx + halfW * 0.58, rahlY + 28.h);
    backLeg.lineTo(center.dx + halfW * 0.44, rahlY + 28.h);
    backLeg.lineTo(center.dx - halfW * 0.76, rahlY - 10.h);
    backLeg.close();
    canvas.drawPath(backLeg, woodBack);

    // الساق الأمامية (مائلة من اليمين للأعلى إلى اليسار للأسفل - تتقاطع مع الخلفية)
    final Path frontLeg = Path();
    frontLeg.moveTo(center.dx + halfW * 0.62, rahlY - 10.h);
    frontLeg.lineTo(center.dx - halfW * 0.58, rahlY + 28.h);
    frontLeg.lineTo(center.dx - halfW * 0.44, rahlY + 28.h);
    frontLeg.lineTo(center.dx + halfW * 0.76, rahlY - 10.h);
    frontLeg.close();
    canvas.drawPath(frontLeg, woodFront);

    // فتحة محرابية مقوسة محفورة في خشب الرَّحْل (أرابيسك إسلامي في الحامل)
    final Path archCutout = Path();
    archCutout.moveTo(center.dx - 8.w, rahlY + 28.h);
    archCutout.lineTo(center.dx - 8.w, rahlY + 21.h);
    archCutout.quadraticBezierTo(
      center.dx,
      rahlY + 14.h,
      center.dx + 8.w,
      rahlY + 21.h,
    );
    archCutout.lineTo(center.dx + 8.w, rahlY + 28.h);
    archCutout.close();

    final cutoutPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDark ? const Color(0xFF040E12) : const Color(0xFFE2F3EC);
    canvas.drawPath(archCutout, cutoutPaint);

    // حواف خشبية محفورة ومحددة بخط ذهبي خافت
    final woodEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.35);
    canvas.drawPath(frontLeg, woodEdgePaint);

    // -------------------------------------------------------------
    // ج. غلاف وتجليد المصحف الخارجي (جلد ملكي زمردي مذهب)
    // -------------------------------------------------------------
    final double bookTopY = center.dy - 22.h;
    final double bookGutterY = center.dy + 8.h;

    final Path outerCover = Path();
    // الكعب السفلي
    outerCover.moveTo(center.dx, bookGutterY + 5.h);
    // الحافة السفلية اليسرى للغلاف
    outerCover.cubicTo(
      center.dx - halfW * 0.35,
      bookGutterY + 8.h,
      center.dx - halfW * 0.78,
      center.dy + 2.h,
      center.dx - halfW * 0.95,
      bookTopY + 12.h,
    );
    // الحافة الخارجية اليسرى
    outerCover.lineTo(center.dx - halfW * 0.95, bookTopY - 4.h);
    // الحافة العلوية اليسرى
    outerCover.cubicTo(
      center.dx - halfW * 0.78,
      bookTopY - 14.h,
      center.dx - halfW * 0.35,
      bookTopY - 4.h,
      center.dx,
      bookTopY + 2.h,
    );
    // الحافة العلوية اليمنى
    outerCover.cubicTo(
      center.dx + halfW * 0.35,
      bookTopY - 4.h,
      center.dx + halfW * 0.78,
      bookTopY - 14.h,
      center.dx + halfW * 0.95,
      bookTopY - 4.h,
    );
    // الحافة الخارجية اليمنى
    outerCover.lineTo(center.dx + halfW * 0.95, bookTopY + 12.h);
    // الحافة السفلية اليمنى
    outerCover.cubicTo(
      center.dx + halfW * 0.78,
      center.dy + 2.h,
      center.dx + halfW * 0.35,
      bookGutterY + 8.h,
      center.dx,
      bookGutterY + 5.h,
    );
    outerCover.close();

    final coverPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [Color(0xFF0F4727), Color(0xFF1B6A3B), Color(0xFF0A3A1E)],
      ).createShader(outerCover.getBounds());
    canvas.drawPath(outerCover, coverPaint);

    // زوايا تذهيب نحاسية محفورة في أطراف الغلاف
    final goldCornerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.85);

    canvas.drawCircle(Offset(center.dx - halfW * 0.93, bookTopY - 2.h), 2.2.r, goldCornerPaint);
    canvas.drawCircle(Offset(center.dx + halfW * 0.93, bookTopY - 2.h), 2.2.r, goldCornerPaint);
    canvas.drawCircle(Offset(center.dx - halfW * 0.93, bookTopY + 10.h), 2.2.r, goldCornerPaint);
    canvas.drawCircle(Offset(center.dx + halfW * 0.93, bookTopY + 10.h), 2.2.r, goldCornerPaint);

    // -------------------------------------------------------------
    // د. كُتلة الأوراق المذهبة ثلاثية الأبعاد (Page Block Depth)
    // -------------------------------------------------------------
    final Paint pageEdgePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFCE69B), Color(0xFFC7982B), Color(0xFF9E7318)],
      ).createShader(Rect.fromLTWH(center.dx - halfW, bookTopY, quranWidth, 30.h));

    // حواف الصفحات المذهبة الجانبية لليسار
    final Path leftEdgeBlock = Path();
    leftEdgeBlock.moveTo(center.dx - halfW * 0.93, bookTopY - 2.h);
    leftEdgeBlock.lineTo(center.dx - halfW * 0.93, bookTopY + 10.h);
    leftEdgeBlock.lineTo(center.dx - halfW * 0.85, bookTopY + 9.h);
    leftEdgeBlock.lineTo(center.dx - halfW * 0.85, bookTopY - 3.h);
    leftEdgeBlock.close();
    canvas.drawPath(leftEdgeBlock, pageEdgePaint);

    // حواف الصفحات المذهبة الجانبية لليمين
    final Path rightEdgeBlock = Path();
    rightEdgeBlock.moveTo(center.dx + halfW * 0.93, bookTopY - 2.h);
    rightEdgeBlock.lineTo(center.dx + halfW * 0.93, bookTopY + 10.h);
    rightEdgeBlock.lineTo(center.dx + halfW * 0.85, bookTopY + 9.h);
    rightEdgeBlock.lineTo(center.dx + halfW * 0.85, bookTopY - 3.h);
    rightEdgeBlock.close();
    canvas.drawPath(rightEdgeBlock, pageEdgePaint);

    // -------------------------------------------------------------
    // هـ. الصفحتان المفتوحتان بانسيابية ثلاثية الأبعاد (Open Curved Pages)
    // -------------------------------------------------------------
    // الصفحة اليسرى
    final Path leftPage = Path();
    leftPage.moveTo(center.dx, bookGutterY);
    leftPage.cubicTo(
      center.dx - halfW * 0.32,
      bookGutterY + 4.h,
      center.dx - halfW * 0.70,
      center.dy - 1.h,
      center.dx - halfW * 0.88,
      bookTopY + 8.h,
    );
    leftPage.lineTo(center.dx - halfW * 0.88, bookTopY - 6.h);
    leftPage.cubicTo(
      center.dx - halfW * 0.70,
      bookTopY - 16.h,
      center.dx - halfW * 0.32,
      bookTopY - 6.h,
      center.dx,
      bookTopY,
    );
    leftPage.close();

    // الصفحة اليمنى
    final Path rightPage = Path();
    rightPage.moveTo(center.dx, bookGutterY);
    rightPage.cubicTo(
      center.dx + halfW * 0.32,
      bookGutterY + 4.h,
      center.dx + halfW * 0.70,
      center.dy - 1.h,
      center.dx + halfW * 0.88,
      bookTopY + 8.h,
    );
    rightPage.lineTo(center.dx + halfW * 0.88, bookTopY - 6.h);
    rightPage.cubicTo(
      center.dx + halfW * 0.70,
      bookTopY - 16.h,
      center.dx + halfW * 0.32,
      bookTopY - 6.h,
      center.dx,
      bookTopY,
    );
    rightPage.close();

    // تدرج ورقي عاجي فاخر مع ظل ناعم في المنتصف
    final leftPageShader = LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: const [Color(0xFFF3ECE0), Color(0xFFFFFDF8), Color(0xFFFCFAF4)],
      stops: const [0.0, 0.25, 1.0],
    ).createShader(leftPage.getBounds());

    final rightPageShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [Color(0xFFF3ECE0), Color(0xFFFFFDF8), Color(0xFFFCFAF4)],
      stops: const [0.0, 0.25, 1.0],
    ).createShader(rightPage.getBounds());

    canvas.drawPath(leftPage, Paint()..style = PaintingStyle.fill..shader = leftPageShader);
    canvas.drawPath(rightPage, Paint()..style = PaintingStyle.fill..shader = rightPageShader);

    // إطار تذهيب أنيق حول الصفحتين
    final goldBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFC99824);

    canvas.drawPath(leftPage, goldBorderPaint);
    canvas.drawPath(rightPage, goldBorderPaint);

    // -------------------------------------------------------------
    // و. تذهيب براويز المصحف الشريف النقية (صفحات بيضاء نقية بلا كتابة)
    // -------------------------------------------------------------
    final innerGoldLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.75);

    // إطار تذهيب نقي للصفحة اليسرى
    final Path leftInnerBox = Path();
    leftInnerBox.moveTo(center.dx - 4.w, bookGutterY - 3.h);
    leftInnerBox.cubicTo(
      center.dx - halfW * 0.30,
      bookGutterY + 1.h,
      center.dx - halfW * 0.65,
      center.dy - 3.h,
      center.dx - halfW * 0.80,
      bookTopY + 5.h,
    );
    leftInnerBox.lineTo(center.dx - halfW * 0.80, bookTopY - 2.h);
    leftInnerBox.cubicTo(
      center.dx - halfW * 0.65,
      bookTopY - 11.h,
      center.dx - halfW * 0.30,
      bookTopY - 3.h,
      center.dx - 4.w,
      bookTopY + 3.h,
    );
    leftInnerBox.close();
    canvas.drawPath(leftInnerBox, innerGoldLine);

    // إطار تذهيب نقي للصفحة اليمنى
    final Path rightInnerBox = Path();
    rightInnerBox.moveTo(center.dx + 4.w, bookGutterY - 3.h);
    rightInnerBox.cubicTo(
      center.dx + halfW * 0.30,
      bookGutterY + 1.h,
      center.dx + halfW * 0.65,
      center.dy - 3.h,
      center.dx + halfW * 0.80,
      bookTopY + 5.h,
    );
    rightInnerBox.lineTo(center.dx + halfW * 0.80, bookTopY - 2.h);
    rightInnerBox.cubicTo(
      center.dx + halfW * 0.65,
      bookTopY - 11.h,
      center.dx + halfW * 0.30,
      bookTopY - 3.h,
      center.dx + 4.w,
      bookTopY + 3.h,
    );
    rightInnerBox.close();
    canvas.drawPath(rightInnerBox, innerGoldLine);

    // نقاط زخرفية رقيقة في زوايا براويز الصفحات
    final cornerDotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFC59828).withValues(alpha: 0.85);
    canvas.drawCircle(Offset(center.dx - halfW * 0.78, bookTopY - 2.h), 1.5.r, cornerDotPaint);
    canvas.drawCircle(Offset(center.dx + halfW * 0.78, bookTopY - 2.h), 1.5.r, cornerDotPaint);

    // -------------------------------------------------------------
    // ز. شريط علامة المصحف الحريري المنسدل مع الشرابة (Bookmark Ribbon & Tassel)
    // -------------------------------------------------------------
    final Path silkRibbon = Path();
    silkRibbon.moveTo(center.dx, bookTopY - 1.h);
    silkRibbon.cubicTo(
      center.dx + 5.w,
      center.dy,
      center.dx - 4.w,
      bookGutterY + 8.h,
      center.dx + 2.w,
      rahlY + 16.h,
    );

    canvas.drawPath(
      silkRibbon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFD4AF37),
    );

    // الشرابة الذهبية في نهاية شريط المصحف
    final Offset tasselTip = Offset(center.dx + 2.w, rahlY + 17.h);
    canvas.drawCircle(tasselTip, 1.8.r, Paint()..style = PaintingStyle.fill..color = const Color(0xFFF9D874));
    canvas.drawLine(
      tasselTip,
      Offset(tasselTip.dx - 2.w, tasselTip.dy + 6.h),
      Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = const Color(0xFFC59828),
    );
    canvas.drawLine(
      tasselTip,
      Offset(tasselTip.dx, tasselTip.dy + 7.h),
      Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = const Color(0xFFC59828),
    );
    canvas.drawLine(
      tasselTip,
      Offset(tasselTip.dx + 2.w, tasselTip.dy + 6.h),
      Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = const Color(0xFFC59828),
    );
  }

  /// 8. ذرات النور العائمة
  void _drawFloatingSparks(Canvas canvas, Size size) {
    final sparkPaint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final double yOffset = (progress * p.speed) % 1.0;
      final double currentY = ((p.yRatio - yOffset + 1.0) % 1.0) * size.height;
      final double wave = math.sin((progress * 2 * math.pi) + p.phase) * 12.w;
      final double currentX = (p.xRatio * size.width + wave) % size.width;

      final double pulse =
          (math.sin((progress * 3 * math.pi) + p.phase) + 1) / 2;
      final double opacity = isDark
          ? (0.22 + 0.60 * pulse).clamp(0.0, 1.0)
          : (0.16 + 0.45 * pulse).clamp(0.0, 1.0);

      final Color pColor = p.isGold
          ? (isDark ? const Color(0xFFF9DC8A) : const Color(0xFFC99824))
          : (isDark ? const Color(0xFF7CE2BE) : const Color(0xFF2E9B66));

      sparkPaint.color = pColor.withValues(alpha: opacity * 0.75);
      canvas.drawCircle(Offset(currentX, currentY), p.size * 1.6, sparkPaint);

      sparkPaint.color = Colors.white.withValues(alpha: opacity * 0.9);
      canvas.drawCircle(Offset(currentX, currentY), p.size * 0.6, sparkPaint);
    }
  }

  void _drawMiniEightStar(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    final Path path = Path();
    for (int i = 0; i < 16; i++) {
      final double currentR = (i % 2 == 0) ? r : r * 0.55;
      final double angle = i * math.pi / 8;
      final double x = center.dx + currentR * math.cos(angle);
      final double y = center.dy + currentR * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawMiniStar(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    final Path path = Path();
    for (int i = 0; i < 10; i++) {
      final double currentR = (i % 2 == 0) ? r : r * 0.45;
      final double angle = i * math.pi / 5 - math.pi / 2;
      final double x = center.dx + currentR * math.cos(angle);
      final double y = center.dy + currentR * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MihrabQuranSanctuaryPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
