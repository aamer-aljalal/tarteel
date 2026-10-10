import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/qibla_painters.dart';
import 'QiblaMapScreen.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  /// دالة مساعدة لفتح البوصلة كقائمة سفلية منبثقة (Bottom Sheet) من أي مكان
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QiblaScreen(),
    );
  }

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  // إحداثيات الكعبة المشرفة
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  double? _heading;
  double _filteredHeading = 0.0;
  bool _wasAligned = false;
  double _distanceKm = 0;
  double? _qiblaAngle;
  double? _deviceQiblaAngle;
  String _statusMessage = 'جاري تحديد موقعك...';
  bool _isLoading = true;
  bool _hasError = false;
  bool _isAligned = false;
  String _locationName = '';

  StreamSubscription<CompassEvent>? _compassSub;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // تنعيم البوصلة
  bool _isFirstHeading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
          final dist =
              Geolocator.distanceBetween(
                cachedLat,
                cachedLng,
                _kaabaLat,
                _kaabaLng,
              ) /
              1000;
          setState(() {
            _distanceKm = dist;
            _qiblaAngle = qibla;
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
        setState(() {
          _distanceKm = 0;
          _qiblaAngle = qibla;
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

        final dist =
            Geolocator.distanceBetween(
              currentPos.latitude,
              currentPos.longitude,
              _kaabaLat,
              _kaabaLng,
            ) /
            1000;

        setState(() {
          _distanceKm = dist;
          _qiblaAngle = qibla;
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
            'تعذّر تحديد إحداثيات موقعك: ${e.toString().split("\n").first}\nيرجى التأكد من تفعيل الـ GPS والمحاولة مجدداً.';
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
            _isAligned = isAligned;
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _hasError = true;
            _statusMessage = 'حدث خطأ في حساس البوصلة بالجهاز.';
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

    // تصميم البوصلة كقائمة منبثقة من الأسفل (Bottom Sheet)
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1712) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 12.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. مقبض السحب (Drag Handle)
              Container(
                margin: EdgeInsets.only(top: 10.h, bottom: 4.h),
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // 2. شريط العنوان وأزرار التحكم
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.help_outline_rounded),
                      onPressed: () => _showHelpDialog(context),
                      tooltip: 'تعليمات',
                    ),
                    Text(
                      'اتجاه القبلة',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
              ),

              // 3. محتوى البوصلة
              if (_isLoading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 36.h),
                  child: _buildLoadingState(primary),
                )
              else if (_hasError)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: _buildErrorState(primary),
                )
              else
                _buildCompassView(context, isDark, primary, secondary),
            ],
          ),
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
            width: 50.w,
            height: 50.w,
            child: CircularProgressIndicator(color: primary, strokeWidth: 3),
          ),
          SizedBox(height: 18.h),
          Text(
            _statusMessage,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color primary) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 50.sp, color: primary),
            SizedBox(height: 12.h),
            Text(
              _statusMessage,
              style: TextStyle(fontSize: 13.sp, height: 1.5),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => _requestPermissionsAndLocate(forceRefresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. البوصلة بحجم كبير وواضح وبارز
        _buildCompassWidget(angle, primary, secondary, isDark),
        SizedBox(height: 16.h),

        // 2. زر الموقع وزر عرض القبلة بالخريطة بجانب بعضهما في نفس الصف
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              // زر / حاوية الموقع مع زر التحديث
              Expanded(
                child: Container(
                  height: 48.h,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF162518)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: primary,
                        size: 18.sp,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          _locationName.isNotEmpty
                              ? _locationName
                              : 'تحديد الموقع...',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 18.sp,
                          color: primary,
                        ),
                        onPressed: () =>
                            _requestPermissionsAndLocate(forceRefresh: true),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'تحديث الموقع',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),

              // زر عرض القبلة بالخريطة
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final lat = prefs.getDouble('prayer_lat') ?? 0.0;
                    final lng = prefs.getDouble('prayer_lng') ?? 0.0;
                    if (!context.mounted) return;
                    if (lat != 0.0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              QiblaMapScreen(userLat: lat, userLng: lng),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.map_rounded, size: 18.sp),
                  label: Text(
                    'القبلة بالخريطة',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size(0, 48.h),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildCompassWidget(
    double angle,
    Color primary,
    Color secondary,
    bool isDark,
  ) {
    double? diff;
    if (_heading != null && _qiblaAngle != null) {
      diff = ((_heading! - _qiblaAngle! + 180) % 360) - 180;
    }
    final bool isAligned = _isAligned;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // هالة خارجية نابضة
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Transform.scale(
              scale: isAligned ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 360.w,
                height: 360.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isAligned
                        ? [
                            Colors.green.withValues(alpha: 0.22),
                            Colors.transparent,
                          ]
                        : [primary.withValues(alpha: 0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // قرص البوصلة الحاوي لخريطة المسار والتضاريس (بحجم أوسع 330.w)
          Container(
            width: 330.w,
            height: 330.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isAligned ? Colors.green : primary).withValues(
                    alpha: 0.25,
                  ),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF09120C),
                  border: Border.all(
                    color: isAligned
                        ? const Color(0xFF00E676)
                        : const Color(0xFFD4AF37),
                    width: 2.5,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. الخريطة ومسار القبلة والتضاريس (تحت السهم في الخلفية)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return Padding(
                          padding: EdgeInsets.all(34.w),
                          child: CustomPaint(
                            size: Size(262.w, 262.w),
                            painter: QiblaRadarVisualizerPainter(
                              diffAngle: diff ?? 0.0,
                              isAligned: isAligned,
                              animValue: _pulseController.value,
                              distanceKm: _distanceKm,
                            ),
                            child: Stack(
                              children: [
                                // الكعبة المشرفة في رأس القرص
                                Positioned(
                                  top: 0.h,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: _buildKaabaTargetWidget(isAligned),
                                  ),
                                ),

                                // موقع المستخدم في أسفل القرص
                                Positioned(
                                  bottom: 4.h,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: _buildUserLocationWidget(isAligned),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // 2. البوصلة: حلقة التدريجات والاتجاهات وسهم القبلة الدوار (فوق الخريطة)
                    AnimatedRotation(
                      turns: -(_heading ?? 0.0) / 360,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: CustomPaint(
                        size: Size(330.w, 330.w),
                        painter: CompassRingPainter(isDark: isDark),
                        child: Center(
                          child: Transform.rotate(
                            angle: (_qiblaAngle ?? 0.0) * math.pi / 180,
                            child: _buildQiblaArrow(isAligned),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaArrow(bool isAligned) {
    return CustomPaint(
      size: Size(330.w, 330.w),
      painter: QiblaArrowPainter(isAligned: isAligned),
    );
  }

  /// ودجت الكعبة في رأس قرص البوصلة
  Widget _buildKaabaTargetWidget(bool isAligned) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                blurRadius: 5,
              ),
            ],
          ),
          child: Text(
            ' الكعبة المشرفة',
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(height: 2.5.h),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAligned
                      ? const Color(0xFF00E676)
                      : const Color(0xFFD4AF37),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isAligned ? Colors.green : const Color(0xFFD4AF37))
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(2.5.r),
                border: Border.all(color: const Color(0xFFD4AF37), width: 1.3),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 2.h),
                    height: 1.8.h,
                    width: 14.w,
                    color: const Color(0xFFD4AF37),
                  ),
                ],
              ),
            ),
            Container(
              width: 4.w,
              height: 4.w,
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

  /// ودجت المستخدم في أسفل قرص البوصلة
  Widget _buildUserLocationWidget(bool isAligned) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.15),
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.3),
                ),
              ),
            ),
            Container(
              width: 18.w,
              height: 18.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2979FF),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.5),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 11,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            'موقعك الحالي',
            style: TextStyle(
              fontSize: 8.sp,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
          '• دوّر الهاتف حتى يتجه السهم للأعلى (نحو رأس الشاشة).\n'
          '• سيهتز الهاتف ويتحول اللون للأخضر عند الاستقامة نحو القبلة.\n'
          '• حرّك الهاتف بشكل دائري لمعايرة البوصلة إذا كانت غير دقيقة.\n'
          '• يمكنك الضغط على "عرض القبلة بالخريطة" لمشاهدة المسار المباشر',
          style: TextStyle(fontSize: 13.5.sp, height: 1.7),
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
