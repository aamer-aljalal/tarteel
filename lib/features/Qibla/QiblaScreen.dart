import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // تمت الإضافة من أجل الاهتزاز HapticFeedback
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'widgets/qibla_painters.dart';
import 'widgets/qibla_info_card.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  // إحداثيات الكعبة المشرفة
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  double? _heading; // اتجاه البوصلة الحالي (تراكمي)
  double? _qiblaAngle; // زاوية القبلة من الشمال
  double? _deviceQiblaAngle; // زاوية القبلة نسبة لاتجاه الجهاز
  double? _distanceToKaaba; // المسافة إلى الكعبة بالكيلومتر
  String _statusMessage = 'جاري تحديد موقعك...';
  bool _isLoading = true;
  bool _hasError = false;
  bool _isAligned = false;
  String _locationName = '';

  StreamSubscription<CompassEvent>? _compassSub;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // متغيرات التنعيم للبوصلة
  double _lastHeading = 0.0;
  double _cumulativeHeading = 0.0;
  bool _isFirstHeading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    await _requestPermissionsAndLocate(forceRefresh: false);
  }

  Future<void> _requestPermissionsAndLocate({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _statusMessage = 'جاري التحقق من صلاحيات الموقع...';
    });

    try {
      if (!forceRefresh) {
        final prefs = await SharedPreferences.getInstance();
        final double? cachedLat = prefs.getDouble('prayer_lat');
        final double? cachedLng = prefs.getDouble('prayer_lng');
        final String? cachedCity = prefs.getString('prayer_city_name');

        if (cachedLat != null && cachedLng != null) {
          final qibla = _calculateQiblaAngle(cachedLat, cachedLng);
          final distance = Geolocator.distanceBetween(
            cachedLat,
            cachedLng,
            _kaabaLat,
            _kaabaLng,
          );

          setState(() {
            _qiblaAngle = qibla;
            _distanceToKaaba = distance / 1000;
            _isLoading = false;
            _statusMessage = 'البوصلة نشطة (أوفلاين بالكامل)';
            _locationName =
                cachedCity ??
                '${cachedLat.toStringAsFixed(4)}°N, ${cachedLng.toStringAsFixed(4)}°E';
          });
          _startCompass();
          return;
        }
      }

      if (defaultTargetPlatform == TargetPlatform.windows) {
        final qibla = _calculateQiblaAngle(21.4225, 39.8262);
        final distance = Geolocator.distanceBetween(
          21.4225,
          39.8262,
          _kaabaLat,
          _kaabaLng,
        );
        setState(() {
          _qiblaAngle = qibla;
          _distanceToKaaba = distance / 1000;
          _isLoading = false;
          _statusMessage = 'البوصلة نشطة (الوضع الافتراضي للويندوز)';
          _locationName = 'مكة المكرمة (الافتراضي للويندوز)';
        });
        _startCompass();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        setState(() => _statusMessage = 'جاري طلب إذن الموقع...');
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _statusMessage =
                'يتطلب تحديد القبلة إذن الموقع.\nيُرجى تفعيله من الإعدادات.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _statusMessage =
              'صلاحية الموقع مرفوضة دائماً.\nيرجى تفعيلها من إعدادات الهاتف.';
        });
        await Geolocator.openAppSettings();
        return;
      }

      setState(() => _statusMessage = 'جاري تحديد موقعك...');

      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _statusMessage = 'يرجى تفعيل خدمة الموقع (GPS) في إعدادات الهاتف.';
        });
        await Geolocator.openLocationSettings();
        return;
      }

      Position? pos;
      try {
        pos = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      final locationSettingsLow =
          defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(
              accuracy: LocationAccuracy.low,
              forceLocationManager: true,
            )
          : const LocationSettings(accuracy: LocationAccuracy.low);

      final locationSettingsLowest =
          defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(
              accuracy: LocationAccuracy.lowest,
              forceLocationManager: true,
            )
          : const LocationSettings(accuracy: LocationAccuracy.lowest);

      if (pos == null) {
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: locationSettingsLow,
          ).timeout(const Duration(seconds: 6));
        } catch (_) {
          try {
            pos = await Geolocator.getCurrentPosition(
              locationSettings: locationSettingsLowest,
            ).timeout(const Duration(seconds: 6));
          } catch (err) {
            debugPrint("Qibla location fetch error: $err");
          }
        }
      }

      if (pos != null) {
        final currentPos = pos;
        final qibla = _calculateQiblaAngle(
          currentPos.latitude,
          currentPos.longitude,
        );
        final distance = Geolocator.distanceBetween(
          currentPos.latitude,
          currentPos.longitude,
          _kaabaLat,
          _kaabaLng,
        );

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble('prayer_lat', currentPos.latitude);
          await prefs.setDouble('prayer_lng', currentPos.longitude);
          await prefs.setString(
            'last_location_update_time',
            DateTime.now().toIso8601String(),
          );

          String cityName = 'موقعي الحالي';
          try {
            final placemarks = await placemarkFromCoordinates(
              currentPos.latitude,
              currentPos.longitude,
            );
            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              cityName =
                  place.locality ??
                  place.subAdministrativeArea ??
                  place.administrativeArea ??
                  'موقعي الحالي';
            }
          } catch (_) {}
          await prefs.setString('prayer_city_name', cityName);
        } catch (_) {}

        setState(() {
          _qiblaAngle = qibla;
          _distanceToKaaba = distance / 1000;
          _isLoading = false;
          _statusMessage = 'البوصلة نشطة';
          _locationName =
              '${currentPos.latitude.toStringAsFixed(4)}°N, ${currentPos.longitude.toStringAsFixed(4)}°E';
        });

        _startCompass();
      } else {
        throw Exception('Location service returned null coordinates');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _statusMessage =
            'تعذّر تحديد إحداثيات موقعك: ${e.toString().split("\n").first}\nيرجى التأكد من تفعيل الـ GPS والاتصال والمحاولة مجدداً.';
      });
    }
  }

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

  void _startCompass() {
    try {
      final stream = FlutterCompass.events;
      if (stream == null) {
        setState(() {
          _hasError = true;
          _statusMessage = 'حساس البوصلة غير مدعوم في هذا الجهاز.';
        });
        return;
      }

      _compassSub = stream.listen(
        (event) {
          if (!mounted) return;
          final h = event.heading;
          if (h == null) return;
          if (_qiblaAngle == null) return;

          if (_isFirstHeading) {
            _lastHeading = h;
            _cumulativeHeading = h;
            _isFirstHeading = false;
          } else {
            double delta = h - _lastHeading;
            if (delta > 180) {
              delta -= 360;
            } else if (delta < -180) {
              delta += 360;
            }
            _cumulativeHeading += delta;
            _lastHeading = h;
          }

          final deviceAngle = (_qiblaAngle! - h + 360) % 360;
          final aligned = deviceAngle < 3 || deviceAngle > 357;

          // إضافة ميزة الاهتزاز عند الوصول للقبلة
          if (aligned && !_isAligned) {
            HapticFeedback.mediumImpact(); // اهتزاز خفيف
          }

          setState(() {
            _heading = _cumulativeHeading;
            _deviceQiblaAngle = deviceAngle;
            _isAligned = aligned;
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _hasError = true;
            _statusMessage =
                'حدث خطأ في حساس البوصلة بالجهاز أو البوصلة غير مدعومة.';
          });
        },
      );
    } catch (e) {
      setState(() {
        _hasError = true;
        _statusMessage = 'حساس البوصلة غير مدعوم في هذا الجهاز.';
      });
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: tarteelAppBar(
        titleText: 'اتجاه القبلة',
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/img/Qibla/qibla.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              isDark
                  ? Colors.black.withValues(alpha: 0.75)
                  : Colors.black.withValues(alpha: 0.35),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState(primary)
              : _hasError
              ? _buildErrorState(primary)
              : _buildCompassView(context, isDark, primary, secondary),
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60.w,
            height: 60.w,
            child: CircularProgressIndicator(color: primary, strokeWidth: 3),
          ),
          SizedBox(height: 24.h),
          Text(
            _statusMessage,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color primary) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 64.sp, color: primary),
            SizedBox(height: 16.h),
            Text(
              _statusMessage,
              style: TextStyle(fontSize: 15.sp, height: 1.6),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => _requestPermissionsAndLocate(forceRefresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassView(
    BuildContext context,
    bool isDark,
    Color primary,
    Color secondary,
  ) {
    final angle = _deviceQiblaAngle ?? 0.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        children: [
          _buildCompassWidget(angle, primary, secondary, isDark),
          SizedBox(height: 24.h),
          _buildInfoRow(primary, secondary, isDark),
          SizedBox(height: 16.h),
          _buildLocationCard(primary, isDark),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildCompassWidget(
    double angle,
    Color primary,
    Color secondary,
    bool isDark,
  ) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Transform.scale(
              scale: _isAligned ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 350.w,
                height: 350.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _isAligned
                        ? [
                            Colors.green.withValues(alpha: 0.15),
                            Colors.transparent,
                          ]
                        : [primary.withValues(alpha: 0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 310.w,
            height: 310.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF151515),
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 3,
                    ),
                  ),
                  // التعديل السحري هنا: استخدام AnimatedRotation بدلاً من Transform.rotate ليعطينا نعومة فائقة
                  child: AnimatedRotation(
                    turns: -(_heading ?? 0.0) / 360, // نحول الزاوية إلى دورات
                    duration: const Duration(
                      milliseconds: 250,
                    ), // سرعة الانزلاق
                    curve: Curves.easeOutCubic, // نوع الحركة الفيزيائية السلسة
                    child: CustomPaint(
                      painter: CompassRingPainter(isDark: isDark),
                      child: Center(
                        child: Transform.rotate(
                          angle: (_qiblaAngle ?? 0.0) * math.pi / 180,
                          child: _buildQiblaArrow(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaArrow() {
    return CustomPaint(
      size: Size(280.w, 280.w),
      painter: QiblaArrowPainter(isAligned: _isAligned),
    );
  }

  Widget _buildInfoRow(Color primary, Color secondary, bool isDark) {
    final cardBg = (isDark ? const Color(0xFF1A2B1C) : Colors.white).withValues(
      alpha: 0.85,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: QiblaInfoCard(
              label: 'زاوية القبلة',
              value: '${_qiblaAngle?.toStringAsFixed(1) ?? '--'}°',
              icon: Icons.explore_rounded,
              color: primary,
              bg: cardBg,
              isDark: isDark,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: QiblaInfoCard(
              label: 'المسافة للكعبة',
              // إضافة المسافة المحسوبة
              value: '${_distanceToKaaba?.toStringAsFixed(0) ?? '--'} كم',
              icon: Icons.straighten_rounded,
              color: secondary,
              bg: cardBg,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Color primary, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1A2B1C) : Colors.white).withValues(
            alpha: 0.85,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, color: primary, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'موقعك: $_locationName',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded, size: 18.sp, color: primary),
              onPressed: () => _requestPermissionsAndLocate(forceRefresh: true),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.explore_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 8.w),
            const Text('كيف تستخدم القبلة؟'),
          ],
        ),
        content: Text(
          '• السهم الأصفر يشير دائماً نحو القبلة.\n'
          '• دوّر الهاتف حتى يتجه السهم للأعلى (نحو الشاشة).\n'
          '• سيهتز الهاتف ويتحول اللون للأخضر عند الاستقامة نحو القبلة.\n'
          '• حرّك الهاتف بشكل 8 لمعايرة البوصلة إذا كانت غير دقيقة.\n'
          '• تأكد من إبعاد الهاتف عن الأجسام المعدنية والمغناطيسية.',
          style: TextStyle(fontSize: 14.sp, height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'فهمت',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
