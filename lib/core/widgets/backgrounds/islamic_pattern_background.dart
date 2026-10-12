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

    // 7. المصحف الشريف المفتوح على الحامل الخشبي مع نور الآيات
    _drawOpenHolyQuran(canvas, Offset(cx, apexY + 54.h));

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

  /// 7. المصحف الشريف المفتوح على الحامل الخشبي (الرحلة) مع إشعاع النور 📖
  void _drawOpenHolyQuran(Canvas canvas, Offset center) {
    final double breathe = math.sin(progress * 2 * math.pi) * 0.15;
    final double quranWidth = 72.w;

    // أ. أشعة النور المنبثقة للأعلى من صفحات المصحف (نور على نور)
    final quranGlowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFFFFF2BD) : const Color(0xFFFFFDE8))
              .withValues(alpha: 0.55 + breathe),
          (isDark ? const Color(0xFFF7CF6D) : const Color(0xFF86D8AB))
              .withValues(alpha: 0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: quranWidth * 1.3));

    canvas.drawCircle(center, quranWidth * 1.3, quranGlowPaint);

    // ب. الحامل الخشبي التقليدي (الرَّحْل - Wooden Rahl X-Stand)
    final double rahlY = center.dy + 8.h;
    final Paint woodPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = (isDark ? const Color(0xFF78451D) : const Color(0xFF5A3414))
          .withValues(alpha: 0.75);

    final Path rahlStand = Path();
    // الساق اليسرى
    rahlStand.moveTo(center.dx - quranWidth * 0.46, rahlY - 6.h);
    rahlStand.lineTo(center.dx + quranWidth * 0.38, rahlY + 22.h);
    rahlStand.lineTo(center.dx + quranWidth * 0.30, rahlY + 22.h);
    rahlStand.lineTo(center.dx - quranWidth * 0.42, rahlY - 6.h);
    rahlStand.close();

    // الساق اليمنى المتقاطعة
    rahlStand.moveTo(center.dx + quranWidth * 0.46, rahlY - 6.h);
    rahlStand.lineTo(center.dx - quranWidth * 0.38, rahlY + 22.h);
    rahlStand.lineTo(center.dx - quranWidth * 0.30, rahlY + 22.h);
    rahlStand.lineTo(center.dx + quranWidth * 0.42, rahlY - 6.h);
    rahlStand.close();

    canvas.drawPath(rahlStand, woodPaint);

    // ج. غلاف وتجليد المصحف الخارجي (جلد زمردي مذهب)
    final Path coverPath = Path();
    coverPath.moveTo(center.dx, center.dy + 7.h); // كعب المصحف
    // الصفحة اليسرى المقوسة
    coverPath.cubicTo(
      center.dx - quranWidth * 0.25,
      center.dy + 9.h,
      center.dx - quranWidth * 0.50,
      center.dy + 3.h,
      center.dx - quranWidth * 0.54,
      center.dy - 12.h,
    );
    // قمة الصفحة اليسرى نزولاً للكعب
    coverPath.lineTo(center.dx - quranWidth * 0.54, center.dy - 16.h);
    coverPath.cubicTo(
      center.dx - quranWidth * 0.50,
      center.dy - 1.h,
      center.dx - quranWidth * 0.25,
      center.dy + 5.h,
      center.dx,
      center.dy + 3.h,
    );
    // الصفحة اليمنى المقوسة
    coverPath.cubicTo(
      center.dx + quranWidth * 0.25,
      center.dy + 5.h,
      center.dx + quranWidth * 0.50,
      center.dy - 1.h,
      center.dx + quranWidth * 0.54,
      center.dy - 16.h,
    );
    coverPath.lineTo(center.dx + quranWidth * 0.54, center.dy - 12.h);
    coverPath.cubicTo(
      center.dx + quranWidth * 0.50,
      center.dy + 3.h,
      center.dx + quranWidth * 0.25,
      center.dy + 9.h,
      center.dx,
      center.dy + 7.h,
    );
    coverPath.close();

    // رسم تجليد الغلاف باللون الزمردي الإسلامي
    final coverPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF14532D).withValues(alpha: 0.85);
    canvas.drawPath(coverPath, coverPaint);

    // د. صفحات المصحف الورقية البيضاء العاجية (المفتوحة بانسيابية)
    final Path leftPage = Path();
    leftPage.moveTo(center.dx, center.dy + 2.h);
    leftPage.cubicTo(
      center.dx - quranWidth * 0.22,
      center.dy + 3.h,
      center.dx - quranWidth * 0.46,
      center.dy - 4.h,
      center.dx - quranWidth * 0.50,
      center.dy - 16.h,
    );
    leftPage.lineTo(center.dx - quranWidth * 0.50, center.dy - 18.h);
    leftPage.cubicTo(
      center.dx - quranWidth * 0.46,
      center.dy - 6.h,
      center.dx - quranWidth * 0.22,
      center.dy + 1.h,
      center.dx,
      center.dy,
    );
    leftPage.close();

    final Path rightPage = Path();
    rightPage.moveTo(center.dx, center.dy + 2.h);
    rightPage.cubicTo(
      center.dx + quranWidth * 0.22,
      center.dy + 3.h,
      center.dx + quranWidth * 0.46,
      center.dy - 4.h,
      center.dx + quranWidth * 0.50,
      center.dy - 16.h,
    );
    rightPage.lineTo(center.dx + quranWidth * 0.50, center.dy - 18.h);
    rightPage.cubicTo(
      center.dx + quranWidth * 0.46,
      center.dy - 6.h,
      center.dx + quranWidth * 0.22,
      center.dy + 1.h,
      center.dx,
      center.dy,
    );
    rightPage.close();

    final Paint pagePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFFDF5);

    canvas.drawPath(leftPage, pagePaint);
    canvas.drawPath(rightPage, pagePaint);

    // إطار تذهيب وحواف الصفحات
    final Paint gildingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFC59B27).withValues(alpha: 0.85);

    canvas.drawPath(leftPage, gildingPaint);
    canvas.drawPath(rightPage, gildingPaint);

    // هـ. أسطر الآيات المحفورة برقة (Quranic Text Lines)
    final textLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = (isDark ? const Color(0xFF33291B) : const Color(0xFF6B5838))
          .withValues(alpha: 0.45);

    for (int i = 0; i < 4; i++) {
      final double lineY = center.dy - 13.h + (i * 3.4.h);
      // أسطر الصفحة اليسرى
      canvas.drawLine(
        Offset(center.dx - quranWidth * 0.42, lineY),
        Offset(center.dx - quranWidth * 0.08, lineY + 1.2.h),
        textLinePaint,
      );
      // أسطر الصفحة اليمنى
      canvas.drawLine(
        Offset(center.dx + quranWidth * 0.08, lineY + 1.2.h),
        Offset(center.dx + quranWidth * 0.42, lineY),
        textLinePaint,
      );
    }

    // و. شريط علامة المصحف الذهبي المنسدل من المنتصف (Golden Bookmark Ribbon)
    final Path ribbon = Path();
    ribbon.moveTo(center.dx, center.dy);
    ribbon.cubicTo(
      center.dx + 4.w,
      center.dy + 8.h,
      center.dx - 3.w,
      center.dy + 16.h,
      center.dx + 1.w,
      center.dy + 22.h,
    );
    canvas.drawPath(
      ribbon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFD4AF37),
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
