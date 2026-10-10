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

  void _startCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      final h = event.heading;
      if (h == null || _qiblaAngle == null) return;

      double diff = ((h - _qiblaAngle! + 180) % 360) - 180;
      bool isAligned = diff.abs() <= 2.0;

      if (isAligned && !_wasAligned) {
        HapticFeedback.mediumImpact();
      }
      _wasAligned = isAligned;

      setState(() {
        _heading = h;
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
    // حساب فارق الزاوية
    double? diff;
    if (_heading != null && _qiblaAngle != null) {
      diff = ((_heading! - _qiblaAngle! + 180) % 360) - 180;
    }

    final bool isAligned = diff != null && diff.abs() <= 2.0;

    return Scaffold(
      backgroundColor: const Color(0xFF09120C), // خلفية ليلية داكنة فاخرة
      appBar: tarteelAppBar(
        titleText: 'محاذاة مسار القبلة المباشر',
        backgroundColor: const Color(0xFF09120C),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. بطاقة التوجيه الذكية العلوية (HUD Badge)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF112015),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isAligned
                        ? const Color(0xFF00E676)
                        : Colors.amber.shade700,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isAligned ? Colors.green : Colors.amber)
                          .withValues(alpha: 0.15),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isAligned
                          ? Icons.gps_fixed_rounded
                          : Icons.explore_rounded,
                      color: isAligned ? const Color(0xFF00E676) : Colors.amber,
                      size: 28.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAligned
                                ? 'متطابق مع مركز الكعبة تماماً 🎯'
                                : (diff == null
                                      ? 'جاري ضبط اتجاه البوصلة...'
                                      : (diff < 0
                                            ? 'مائل بمقدار ${diff.abs().toStringAsFixed(1)}° نحو اليسار'
                                            : 'مائل بمقدار ${diff.toStringAsFixed(1)}° نحو اليمين')),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: isAligned
                                  ? const Color(0xFF00E676)
                                  : Colors.white,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            isAligned
                                ? 'خط هاتفك يمر الآن في قلب الكعبة المشرفة مباشرة.'
                                : (diff != null && diff < 0
                                      ? '⟵ أدر هاتفك لليمين قليلاً لمطابقة المسار'
                                      : 'أدر هاتفك لليسار قليلاً لمطابقة المسار ⟶'),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. ساحة المحاذاة البصرية (المسار الكامل الثابت)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                              // أ) الكعبة المشرفة في رأس الشاشة (Top Center)
                              Positioned(
                                top: 12.h,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _buildKaabaTargetWidget(isAligned),
                                ),
                              ),

                              // ب) موقع المستخدم في أسفل الشاشة (Bottom Center)
                              Positioned(
                                bottom: 12.h,
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

            // 3. شريط المعلومات السريع في الأسفل
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF112015),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoColumn(
                      'زاوية القبلة',
                      '${_qiblaAngle?.toStringAsFixed(1) ?? '--'}°',
                    ),
                    Container(width: 1, height: 24.h, color: Colors.white24),
                    _buildInfoColumn(
                      'اتجاه هاتفك',
                      '${_heading?.toStringAsFixed(1) ?? '--'}°',
                    ),
                    Container(width: 1, height: 24.h, color: Colors.white24),
                    _buildInfoColumn(
                      'المسافة للكعبة',
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

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.white60),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// ودجت الكعبة في رأس الشاشة
  Widget _buildKaabaTargetWidget(bool isAligned) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // شارة عنوان الكعبة
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🕋 الكعبة المشرفة (الهدف)',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),

        // مجسم الكعبة وهدف المركز
        Stack(
          alignment: Alignment.center,
          children: [
            // حلقة هدف مشعة
            Container(
              width: 58.w,
              height: 58.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAligned
                      ? const Color(0xFF00E676)
                      : const Color(0xFFD4AF37),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isAligned ? Colors.green : const Color(0xFFD4AF37))
                        .withValues(alpha: 0.35),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),

            // مكعب الكعبة مع الستارة الذهبية
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 4.h),
                    height: 3.h,
                    width: 24.w,
                    color: const Color(0xFFD4AF37),
                  ),
                ],
              ),
            ),

            // علامة المركز الدقيق (Center Dot)
            Container(
              width: 6.w,
              height: 6.w,
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

  /// ودجت المستخدم في أسفل الشاشة
  Widget _buildUserLocationWidget(bool isAligned) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // هالة نبض حول المستخدم
            Container(
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.15),
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.4),
                ),
              ),
            ),
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2979FF),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.6),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            'موقعك الحالي',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// رسام المسار والتضاريس البصرية الشاملة
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
    final startPoint = Offset(
      size.width / 2,
      size.height - 55,
    ); // موقع المستخدم بالأسفل
    final kaabaTarget = Offset(size.width / 2, 55); // مركز الكعبة بالأعلى
    final pathLength = startPoint.dy - kaabaTarget.dy;

    // 1. رسم خطوط التضاريس والشبكة الكنتورية (Topographic Contours)
    _drawTopographicTerrain(canvas, size, startPoint, pathLength);

    // 2. رسم مسار الكعبة الثابت المباشر (المسار الأخضر / الذهبي)
    _drawKaabaDirectTrack(canvas, startPoint, kaabaTarget);

    // 3. رسم خط اتجاه الهاتف التفاعلي (ليزر الهاتف)
    _drawPhoneHeadingBeam(canvas, startPoint, pathLength);
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

    final ringsCount = 4;
    for (int i = 1; i <= ringsCount; i++) {
      final r = (totalLength / ringsCount) * i;
      // أقواس مسافات كنتورية
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: r),
        -math.pi * 0.85,
        math.pi * 0.70,
        false,
        contourPaint,
      );
    }

    // خطوط طول شعاعية طفيفة تعبر عن الرادار والاتجاهات
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

  /// رسم مسار الكعبة الثابت للأعلى مباشرة
  void _drawKaabaDirectTrack(Canvas canvas, Offset p1, Offset p2) {
    // هالة المسار
    final glowPaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.15)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, glowPaint);

    // الخط الرئيسي للمسار
    final trackPaint = Paint()
      ..color = const Color(0xFF00C853)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, trackPaint);

    // نبضة متحركة على طول المسار نحو الكعبة
    final pulseY = p1.dy - (p1.dy - p2.dy) * animValue;
    final pulsePoint = Offset(p1.dx, pulseY);
    canvas.drawCircle(
      pulsePoint,
      4.5,
      Paint()..color = const Color(0xFFB9F6CA),
    );
  }

  /// رسم خط اتجاه هاتفك الفعلي
  void _drawPhoneHeadingBeam(Canvas canvas, Offset origin, double length) {
    // الزاوية للأعلى مباشرة هي -90 درجة، نزيد عليها فارق انحراف الهاتف
    final currentRad = (-90 + diffAngle) * math.pi / 180;

    final beamEnd = Offset(
      origin.dx + length * math.cos(currentRad),
      origin.dy + length * math.sin(currentRad),
    );

    final beamColor = isAligned ? const Color(0xFF00E676) : Colors.redAccent;

    // توهج الليزر
    final beamGlow = Paint()
      ..color = beamColor.withValues(alpha: 0.3)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(origin, beamEnd, beamGlow);

    // خط الليزر الحقيقي
    final beamPaint = Paint()
      ..color = beamColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(origin, beamEnd, beamPaint);

    // نقطة رأس السهم / التصويب
    canvas.drawCircle(
      beamEnd,
      isAligned ? 6.0 : 4.5,
      Paint()..color = beamColor,
    );

    // إذا كان مائلاً، نرسم خط تنقيط يوضح الفارق بين رأس خطه والكعبة
    if (!isAligned) {
      final kaabaTop = Offset(origin.dx, origin.dy - length);
      final gapPaint = Paint()
        ..color = Colors.amber.withValues(alpha: 0.5)
        ..strokeWidth = 1.2;
      canvas.drawLine(beamEnd, kaabaTop, gapPaint);
    }
  }

  @override
  bool shouldRepaint(covariant QiblaRadarVisualizerPainter old) {
    return old.diffAngle != diffAngle ||
        old.isAligned != isAligned ||
        old.animValue != animValue;
  }
}
