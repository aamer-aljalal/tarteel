import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';

class QiblaMapScreen extends StatefulWidget {
  final double userLat;
  final double userLng;

  const QiblaMapScreen({
    super.key,
    required this.userLat,
    required this.userLng,
  });

  @override
  State<QiblaMapScreen> createState() => _QiblaMapScreenState();
}

class _QiblaMapScreenState extends State<QiblaMapScreen>
    with SingleTickerProviderStateMixin {
  // إحداثيات الكعبة المشرفة
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  double? _heading;
  double _filteredHeading = 0.0;
  bool _isFirstHeading = true;
  double? _qiblaAngle;
  double _distanceKm = 0;
  bool _wasAligned = false;

  StreamSubscription<CompassEvent>? _compassSub;
  AnimationController? _animController;

  @override
  void initState() {
    super.initState();
    _initAnimation();

    _qiblaAngle = _calculateQiblaAngle(widget.userLat, widget.userLng);

    final distanceMeters = Geolocator.distanceBetween(
      widget.userLat,
      widget.userLng,
      _kaabaLat,
      _kaabaLng,
    );
    _distanceKm = distanceMeters / 1000;

    _startCompass();
  }

  void _initAnimation() {
    _animController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  /// الاستماع لحساس البوصلة مع مرشح مانع الارتجاف (Jitter Filter & Deadband)
  void _startCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      final rawH = event.heading;
      if (rawH == null || _qiblaAngle == null) return;

      if (_isFirstHeading) {
        _filteredHeading = rawH;
        _isFirstHeading = false;
      } else {
        double delta = (rawH - _filteredHeading + 180) % 360 - 180;

        // عتبة تصفية الارتجاف عند ثبات الهاتف (Deadband)
        if (delta.abs() < 0.4) {
          return;
        }

        // مرشح التنعيم الحركي (Exponential Moving Average Filter)
        double alpha = delta.abs() > 8 ? 0.35 : 0.16;
        _filteredHeading = (_filteredHeading + delta * alpha + 360) % 360;
      }

      double diff = ((_filteredHeading - _qiblaAngle! + 180) % 360) - 180;
      bool isAligned = diff.abs() <= 2.0;

      if (isAligned && !_wasAligned) {
        HapticFeedback.mediumImpact();
      }
      _wasAligned = isAligned;

      setState(() {
        _heading = _filteredHeading;
      });
    });
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _animController?.dispose();
    super.dispose();
  }

  /// حساب زاوية القبلة الدقيقة
  double _calculateQiblaAngle(double lat, double lng) {
    final dLng = (_kaabaLng - lng) * math.pi / 180;
    final lat1 = lat * math.pi / 180;
    final lat2 = _kaabaLat * math.pi / 180;

    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    double? diff;
    if (_heading != null && _qiblaAngle != null) {
      diff = ((_heading! - _qiblaAngle! + 180) % 360) - 180;
    }

    final bool isAligned = diff != null && diff.abs() <= 2.0;

    return Scaffold(
      backgroundColor: const Color(0xFF09120C),
      appBar: tarteelAppBar(
        titleText: 'محاذاة مسار القبلة المباشر',
        backgroundColor: const Color(0xFF09120C),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. بطاقة دليل ألوان الخطوط الخفيفة والذكية في الأعلى
            // Padding(
            //   padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            //   child: Container(
            //     padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            //     decoration: BoxDecoration(
            //       color: const Color(0xFF101C13),
            //       borderRadius: BorderRadius.circular(12.r),
            //       border: Border.all(color: Colors.white12),
            //     ),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceAround,
            //       children: [
            //         Row(
            //           children: [
            //             Container(
            //               width: 16.w,
            //               height: 3.5.h,
            //               decoration: BoxDecoration(
            //                 color: const Color(0xFF00E676),
            //                 borderRadius: BorderRadius.circular(2.r),
            //                 boxShadow: [
            //                   BoxShadow(
            //                     color: Colors.green.withValues(alpha: 0.6),
            //                     blurRadius: 4,
            //                   ),
            //                 ],
            //               ),
            //             ),
            //             SizedBox(width: 6.w),
            //             Text(
            //               'مسار القبلة الفعلي',
            //               style: TextStyle(
            //                 fontSize: 10.5.sp,
            //                 color: const Color(0xFF00E676),
            //                 fontWeight: FontWeight.bold,
            //               ),
            //             ),
            //           ],
            //         ),
            //         Container(width: 1, height: 14.h, color: Colors.white12),
            //         Row(
            //           children: [
            //             Container(
            //               width: 16.w,
            //               height: 3.5.h,
            //               decoration: BoxDecoration(
            //                 color: isAligned ? const Color(0xFF00E676) : Colors.redAccent,
            //                 borderRadius: BorderRadius.circular(2.r),
            //                 boxShadow: [
            //                   BoxShadow(
            //                     color: (isAligned ? Colors.green : Colors.red)
            //                         .withValues(alpha: 0.6),
            //                     blurRadius: 4,
            //                   ),
            //                 ],
            //               ),
            //             ),
            //             SizedBox(width: 6.w),
            //             Text(
            //               isAligned ? 'تم التطابق بنجاح ✓' : 'اتجاه هاتفك الحالي',
            //               style: TextStyle(
            //                 fontSize: 10.5.sp,
            //                 color: isAligned ? const Color(0xFF00E676) : Colors.redAccent,
            //                 fontWeight: FontWeight.bold,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ],
            //     ),
            //   ),
            // ),

            // 2. ساحة المحاذاة البصرية (المسار الكامل الثابت)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;

                    _initAnimation();
                    final anim = _animController;
                    if (anim == null) return const SizedBox.shrink();

                    return AnimatedBuilder(
                      animation: anim,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size(width, height),
                          painter: QiblaRadarVisualizerPainter(
                            diffAngle: diff ?? 0.0,
                            isAligned: isAligned,
                            animValue: anim.value,
                            distanceKm: _distanceKm,
                          ),
                          child: Stack(
                            children: [
                              // أ) الكعبة المشرفة في رأس الشاشة
                              Positioned(
                                top: 6.h,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _buildKaabaTargetWidget(isAligned),
                                ),
                              ),

                              // ب) موقع المستخدم في أسفل الشاشة (مع إعطاء مساحة سفلية مناسبة)
                              Positioned(
                                bottom: 20.h,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _buildUserLocationWidget(isAligned),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // 3. لوحة البيانات الموحدة على صف واحد فقط في الأسفل
            Padding(
              padding: EdgeInsets.only(left: 12.w, right: 12.w, bottom: 10.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF112015),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isAligned ? const Color(0xFF00E676) : Colors.white12,
                    width: isAligned ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isAligned ? Colors.green : Colors.black)
                          .withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // عمود الحالة / درجة الميلان
                    _buildInfoColumn(
                      'الحالة',
                      isAligned
                          ? 'متطابق 🎯'
                          : (diff == null
                              ? 'جاري...'
                              : (diff < 0
                                  ? '${diff.abs().toStringAsFixed(1)}° يسار'
                                  : '${diff.toStringAsFixed(1)}° يمين')),
                      valueColor: isAligned
                          ? const Color(0xFF00E676)
                          : Colors.amber.shade400,
                    ),
                    Container(width: 1, height: 18.h, color: Colors.white24),

                    // زاوية القبلة
                    _buildInfoColumn(
                      'زاوية القبلة',
                      '${_qiblaAngle?.toStringAsFixed(1) ?? '--'}°',
                    ),
                    Container(width: 1, height: 18.h, color: Colors.white24),

                    // اتجاه الهاتف
                    _buildInfoColumn(
                      'اتجاه هاتفك',
                      '${_heading?.toStringAsFixed(1) ?? '--'}°',
                    ),
                    Container(width: 1, height: 18.h, color: Colors.white24),

                    // المسافة
                    _buildInfoColumn(
                      'المسافة',
                      '${_distanceKm.toStringAsFixed(0)} كم',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {Color? valueColor}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9.sp, color: Colors.white60),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }

  /// ودجت الكعبة في رأس الشاشة (أبعاد متناسقة ومصغرة قليلاً)
  Widget _buildKaabaTargetWidget(bool isAligned) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.5.h),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                blurRadius: 6,
              ),
            ],
          ),
          child: Text(
            '🕋 الكعبة المشرفة (الهدف)',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(height: 4.h),

        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAligned
                      ? const Color(0xFF00E676)
                      : const Color(0xFFD4AF37),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isAligned ? Colors.green : const Color(0xFFD4AF37))
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1.5,
                  ),
                ],
              ),
            ),

            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(3.r),
                border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 2.5.h),
                    height: 2.h,
                    width: 17.w,
                    color: const Color(0xFFD4AF37),
                  ),
                ],
              ),
            ),

            Container(
              width: 4.5.w,
              height: 4.5.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAligned ? Colors.greenAccent : const Color(0xFFD4AF37),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ودجت المستخدم في أسفل الشاشة (أبعاد متناسقة ومصغرة قليلاً)
  Widget _buildUserLocationWidget(bool isAligned) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.15),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
            ),
            Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2979FF),
                border: Border.all(color: Colors.white, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 13,
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            'موقعك الحالي',
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// رسام المسار والتضاريس مع معالجة ذكية لحساب اتجاه السهم للأسفل وتثبيت النصوص
class QiblaRadarVisualizerPainter extends CustomPainter {
  final double diffAngle; // فارق الزاوية بالدرجات
  final bool isAligned;
  final double animValue;
  final double distanceKm;

  QiblaRadarVisualizerPainter({
    required this.diffAngle,
    required this.isAligned,
    required this.animValue,
    required this.distanceKm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // رفع نقطة البداية للمستخدم قليلاً لتوفير مساحة آمنة تحتها عند توجيه السهم للخلف/للأسفل
    final startPoint = Offset(
      size.width / 2,
      size.height - 55,
    );
    final kaabaTarget = Offset(size.width / 2, 40);
    final pathLength = startPoint.dy - kaabaTarget.dy;

    // 1. رسم خطوط التضاريس والشبكة الكنتورية
    _drawTopographicTerrain(canvas, size, startPoint, pathLength);

    // 2. رسم مسار الكعبة الثابت المباشر والكتابة العمودية عليه
    _drawKaabaDirectTrack(canvas, startPoint, kaabaTarget);

    // 3. رسم خط اتجاه الهاتف التفاعلي مع حصر ذكي للمكان المرئي
    _drawPhoneHeadingBeam(canvas, size, startPoint, pathLength);
  }

  /// رسم خطوط التضاريس الكنتورية والمسافات
  void _drawTopographicTerrain(
    Canvas canvas,
    Size size,
    Offset origin,
    double totalLength,
  ) {
    final contourPaint = Paint()
      ..color = const Color(0xFF14271B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const ringsCount = 4;
    for (int i = 1; i <= ringsCount; i++) {
      final r = (totalLength / ringsCount) * i;
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: r),
        -math.pi * 0.85,
        math.pi * 0.70,
        false,
        contourPaint,
      );
    }

    final radialPaint = Paint()
      ..color = const Color(0xFF102015)
      ..strokeWidth = 0.8;

    for (int deg = -40; deg <= 40; deg += 20) {
      final rad = (-90 + deg) * math.pi / 180;
      final p2 = Offset(
        origin.dx + totalLength * math.cos(rad),
        origin.dy + totalLength * math.sin(rad),
      );
      canvas.drawLine(origin, p2, radialPaint);
    }
  }

  /// رسم مسار الكعبة الثابت مع كتابة عمودية بيضاء بدون خلفية
  void _drawKaabaDirectTrack(Canvas canvas, Offset p1, Offset p2) {
    final glowPaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.15)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, glowPaint);

    final trackPaint = Paint()
      ..color = const Color(0xFF00C853)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, trackPaint);

    // نبضة ضوئية متحركة
    final pulseY = p1.dy - (p1.dy - p2.dy) * animValue;
    final pulsePoint = Offset(p1.dx, pulseY);
    canvas.drawCircle(
      pulsePoint,
      3.8,
      Paint()..color = const Color(0xFFB9F6CA),
    );

    // كتابة عمودية بيضاء بدون خلفية بمحاذاة خط الكعبة
    _drawVerticalLabel(
      canvas,
      Offset(p1.dx + 14, p1.dy - (p1.dy - p2.dy) * 0.52),
      'مسار القبلة الفعلي',
      -math.pi / 2,
    );
  }

  /// رسم خط اتجاه الهاتف مع حصر المسافة ليظل النص ورأس الخط ظاهرين دائماً حتى لو اتجه لأسفل
  void _drawPhoneHeadingBeam(
    Canvas canvas,
    Size size,
    Offset origin,
    double length,
  ) {
    final currentRad = (-90 + diffAngle) * math.pi / 180;
    final sinVal = math.sin(currentRad);
    final cosVal = math.cos(currentRad);

    // حصر طول الشعاع بذكاء عند الاتجاه للأسفل حتى لا يخرج خارج الشاشة
    double effectiveLength = length;
    if (sinVal > 0) {
      // السهم متجه نحو الأسفل: نحسب المساحة المتبقية تحت المستخدم
      final availableDown = size.height - origin.dy - 8;
      if (availableDown > 0) {
        effectiveLength = math.min(length, (availableDown / sinVal).clamp(30.0, length));
      }
    }

    final beamEnd = Offset(
      origin.dx + effectiveLength * cosVal,
      origin.dy + effectiveLength * sinVal,
    );

    final beamColor = isAligned ? const Color(0xFF00E676) : Colors.redAccent;

    // توهج الليزر
    final beamGlow = Paint()
      ..color = beamColor.withValues(alpha: 0.3)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(origin, beamEnd, beamGlow);

    // خط الليزر الحقيقي
    final beamPaint = Paint()
      ..color = beamColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(origin, beamEnd, beamPaint);

    // نقطة رأس السهم
    canvas.drawCircle(
      beamEnd,
      isAligned ? 5.0 : 3.8,
      Paint()..color = beamColor,
    );

    // كتابة عمودية بيضاء بدون خلفية بمحاذاة خط الهاتف
    if (!isAligned && diffAngle.abs() > 3.0) {
      final normalAngle = currentRad + (diffAngle > 0 ? -math.pi / 2 : math.pi / 2);

      // وضع النص في منتصف الشعاع الفعلي مع إزاحة جانبية
      var labelPos = Offset(
        origin.dx + (effectiveLength * 0.5) * cosVal + 14 * math.cos(normalAngle),
        origin.dy + (effectiveLength * 0.5) * sinVal + 14 * math.sin(normalAngle),
      );

      // حصر مكان الكتابة بصرامة داخل حدود Canvas المرئية (لا تخرج للأسفل أبداً)
      labelPos = Offset(
        labelPos.dx.clamp(16.0, size.width - 16.0),
        labelPos.dy.clamp(16.0, size.height - 14.0),
      );

      _drawVerticalLabel(
        canvas,
        labelPos,
        'اتجاه هاتفك الحالي',
        currentRad,
      );
    }

    // إذا كان مائلاً، خط قياس الفارق بين رأس خطه والكعبة
    if (!isAligned) {
      final kaabaTop = Offset(origin.dx, origin.dy - length);
      final gapPaint = Paint()
        ..color = Colors.amber.withValues(alpha: 0.4)
        ..strokeWidth = 1.0;
      canvas.drawLine(beamEnd, kaabaTop, gapPaint);
    }
  }

  /// دالة رسم النص العمودي باللون الأبيض وبدون أي خلفية
  void _drawVerticalLabel(
    Canvas canvas,
    Offset pos,
    String text,
    double angle,
  ) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95),
          fontSize: 10.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant QiblaRadarVisualizerPainter old) {
    return old.diffAngle != diffAngle ||
        old.isAligned != isAligned ||
        old.animValue != animValue;
  }
}
