import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/services/adhan_notification_service.dart';
import 'package:tarteel/core/services/adhan_player_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrayerProvider extends ChangeNotifier {
  PrayerProvider() {
    _initLocationListener();
  }

  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  void _initLocationListener() {
    if (defaultTargetPlatform == TargetPlatform.windows) return;
    try {
      _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((
        ServiceStatus status,
      ) {
        if (status == ServiceStatus.enabled) {
          silentlyUpdateLocation();
        }
      });
    } catch (e) {
      debugPrint("Error initializing service status stream: $e");
    }
  }

  // موقع مكة المكرمة الافتراضي والاحتياطي
  String _cityName = 'مكة المكرمة';
  double _lat = 21.4225;
  double _lng = 39.8262;
  late Coordinates _coordinates = Coordinates(_lat, _lng);
  late final CalculationParameters _calculationParameters = CalculationMethod
      .umm_al_qura
      .getParameters();

  // بيانات أوقات الصلاة
  PrayerTimes? _prayerTimes;
  Prayer? _nextPrayer;
  DateTime? _nextPrayerTime;
  Duration _timeUntilNextPrayer = Duration.zero;
  Timer? _timer;

  // حالة التحميل والأخطاء
  bool _isLoading = true;
  String? _errorMessage;

  // Getters
  String get cityName => _cityName;
  PrayerTimes? get prayerTimes => _prayerTimes;
  Prayer? get nextPrayer => _nextPrayer;
  DateTime? get nextPrayerTime => _nextPrayerTime;
  Duration get timeUntilNextPrayer => _timeUntilNextPrayer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// تهيئة مواقيت الصلاة عند فتح التطبيق بشكل فوري وأوفلاين
  Future<void> initializeData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. تحميل الإحداثيات والمدينة المخزنة مسبقاً من ذاكرة الهاتف
      final prefs = await SharedPreferences.getInstance();
      _lat = prefs.getDouble('prayer_lat') ?? 21.4225;
      _lng = prefs.getDouble('prayer_lng') ?? 39.8262;
      _cityName = prefs.getString('prayer_city_name') ?? 'مكة المكرمة';
      _coordinates = Coordinates(_lat, _lng);

      // 2. حساب المواقيت فوراً وبشكل أوفلاين 100% باستخدام مكتبة adhan
      _calculatePrayerTimes();
      await scheduleAdhanNotifications();
      _startTimer();

      // 3. تحديث الموقع تلقائياً وبصمت في الخلفية إذا كانت الصلاحيات مفعلة والـ GPS يعمل
      silentlyUpdateLocation();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء جلب البيانات: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// التحقق من الموقع وعرض رسالة للمستخدم لتحديد إحداثيات تحديد المواقيت لأول مرة فقط
  Future<void> checkAndPromptLocation(BuildContext context) async {
    // تجنب تشغيل Geolocator على نظام الويندوز تفادياً لأي أعطال أثناء الاختبار
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasAskedPermissionBefore =
          prefs.getBool('asked_location_permission') ?? false;

      if (!hasAskedPermissionBefore) {
        // المرة الأولى فقط: تنبيه المستخدم بلطف لأخذ إذن الموقع
        if (context.mounted) {
          await _showLocationSetupDialog(context, isFirstTime: true);
        }
      }
    } catch (e) {
      debugPrint("Error in checkAndPromptLocation: $e");
    }
  }

  /// تحديث الموقع يدوياً بطلب الصلاحيات والـ GPS
  Future<void> updateLocationManually(BuildContext context) async {
    // تجنب تشغيل Geolocator على نظام الويندوز تفادياً لأي أعطال أثناء الاختبار
    if (defaultTargetPlatform == TargetPlatform.windows) {
      _showToast(context, 'تحديد الموقع غير مدعوم على نظام ويندوز');
      return;
    }
    await _enableLocationAndFetch(context);
  }

  /// فحص وجود اتصال بالإنترنت بطريقة سريعة وآمنة
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// عرض نافذة التنبيه الأنيقة والمتناسقة مع هوية التطبيق
  Future<void> _showLocationSetupDialog(
    BuildContext context, {
    required bool isFirstTime,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      barrierDismissible:
          !isFirstTime, // إجبار التحديد في المرة الأولى أو الرفض يدوياً
      builder: (context) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            contentPadding: EdgeInsets.all(22.w),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // أيقونة الموقع بتأثير دائري جذاب
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 38.sp,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 16.h),

                // العنوان
                Text(
                  isFirstTime
                      ? 'تحديد مواقيت الصلاة بدقة'
                      : 'تحديث موقعك الحالي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 12.h),

                Text(
                  isFirstTime
                      ? 'يرغب تطبيق "ترتيل" في تحديد موقعك الجغرافي لحساب مواقيت الصلاة والقبلة. في حال الرفض أو عدم توفر إنترنت، سيتم اعتماد توقيت مكة المكرمة كخيار افتراضي.'
                      : 'لقد مر عدة أيام منذ آخر تحديث لموقعك الجغرافي. هل ترغب في تحديث موقعك الحالي لضمان دقة مواقيت الصلاة والأذان (في حال سافرت أو غيرت مكانك)؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5.sp,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 24.h),

                // أزرار التحكم
                Row(
                  children: [
                    // زر الموافقة والتفعيل
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _enableLocationAndFetch(context);
                        },
                        child: Text(
                          isFirstTime ? 'تفعيل الآن' : 'تحديث الموقع',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),

                    // زر الرفض
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool(
                            'asked_location_permission',
                            true,
                          );

                          if (isFirstTime) {
                            // حفظ مكة المكرمة كافتراضي
                            await _saveLocationToPrefs(
                              21.4225,
                              39.8262,
                              'مكة المكرمة',
                            );
                            await prefs.setString(
                              'last_location_update_time',
                              DateTime.now().toIso8601String(),
                            );
                            _lat = 21.4225;
                            _lng = 39.8262;
                            _cityName = 'مكة المكرمة';
                            _coordinates = Coordinates(_lat, _lng);
                            _calculatePrayerTimes();
                            notifyListeners();
                            _showToast(
                              context,
                              'تم حفظ توقيت مكة المكرمة كخيار افتراضي',
                            );
                          }
                        },
                        child: Text(
                          'ليس الآن',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13.sp,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// طلب صلاحيات الـ GPS وجلب الإحداثيات وحفظها
  Future<void> _enableLocationAndFetch(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('asked_location_permission', true);

      // التحقق من تفعيل الـ GPS بالهاتف
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        if (context.mounted) {
          _showToast(
            context,
            'الرجاء تفعيل خدمة تحديد الموقع (GPS) أولاً في إعدادات الهاتف',
          );
          await Geolocator.openLocationSettings();
        }
        _isLoading = false;
        notifyListeners();
        return;
      }

      // التحقق من صلاحيات الموقع
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          _showToast(
            context,
            'تم رفض الوصول للموقع بشكل دائم، يرجى تفعيله من إعدادات التطبيق',
          );
          await Geolocator.openAppSettings();
        }
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          _showToast(
            context,
            'تم رفض الوصول للموقع، سيتم الاستمرار بتوقيت مكة المكرمة كافتراضي',
          );
        }
        await _saveLocationToPrefs(21.4225, 39.8262, 'مكة المكرمة');
        await prefs.setString(
          'last_location_update_time',
          DateTime.now().toIso8601String(),
        );
        _lat = 21.4225;
        _lng = 39.8262;
        _cityName = 'مكة المكرمة';
        _coordinates = Coordinates(_lat, _lng);
        _calculatePrayerTimes();
        await scheduleAdhanNotifications();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // جلب آخر موقع معروف أو الموقع الحالي بمهلة 8 ثوانٍ
      Position? pos;
      try {
        pos = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      final locationSettings = defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(
              accuracy: LocationAccuracy.low,
              forceLocationManager: true,
            )
          : const LocationSettings(accuracy: LocationAccuracy.low);

      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(const Duration(seconds: 8));

      _lat = pos.latitude;
      _lng = pos.longitude;
      _coordinates = Coordinates(_lat, _lng);

      // جلب الاسم الجغرافي للمدينة
      try {
        final placemarks = await placemarkFromCoordinates(_lat, _lng);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _cityName =
              place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              'موقعي الحالي';
        }
      } catch (_) {
        _cityName = 'موقعي الحالي';
      }

      // حفظ الإحداثيات والمدينة في الذاكرة لتشغيل أوفلاين للأبد
      await _saveLocationToPrefs(_lat, _lng, _cityName);
      await prefs.setString(
        'last_location_update_time',
        DateTime.now().toIso8601String(),
      );

      _calculatePrayerTimes();
      await scheduleAdhanNotifications();

      if (context.mounted) {
        _showToast(context, 'تم تحديد موقعك بنجاح: $_cityName');
      }
        } catch (e) {
      if (context.mounted) {
        _showToast(
          context,
          'تعذر الحصول على موقعك الحالي، تم الاستمرار بالبيانات السابقة',
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// حفظ البيانات المشتركة
  Future<void> _saveLocationToPrefs(
    double lat,
    double lng,
    String cityName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('prayer_lat', lat);
    await prefs.setDouble('prayer_lng', lng);
    await prefs.setString('prayer_city_name', cityName);
  }

  /// عرض رسالة إرشادية للمستخدم
  void _showToast(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  void _calculatePrayerTimes() {
    _prayerTimes = PrayerTimes.today(_coordinates, _calculationParameters);
    _updateNextPrayer();
  }

  Future<void> scheduleAdhanNotifications() {
    return AdhanNotificationService.schedulePrayerAdhan(
      coordinates: _coordinates,
      calculationParameters: _calculationParameters,
    );
  }

  void _updateNextPrayer() {
    _prayerTimes = PrayerTimes.today(_coordinates, _calculationParameters);
    if (_prayerTimes != null) {
      Prayer next = _prayerTimes!.nextPrayer();

      // تخطي صلاة الشروق وجعل الصلاة القادمة هي الظهر
      if (next == Prayer.sunrise) {
        next = Prayer.dhuhr;
      }

      if (next == Prayer.none) {
        // إذا انتهت صلوات اليوم، فالصلاة القادمة هي الفجر غداً
        _nextPrayer = Prayer.fajr;

        // حساب وقت الفجر للغد
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowTimes = PrayerTimes(
          _coordinates,
          DateComponents.from(tomorrow),
          _calculationParameters,
        );
        _nextPrayerTime = tomorrowTimes.timeForPrayer(Prayer.fajr);
      } else {
        _nextPrayer = next;
        _nextPrayerTime = _prayerTimes!.timeForPrayer(next);
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prayerTimes != null &&
          _nextPrayer != null &&
          _nextPrayerTime != null) {
        final now = DateTime.now();
        if (now.isAfter(_nextPrayerTime!)) {
          final enteredPrayer = _nextPrayer!;
          if (enteredPrayer != Prayer.sunrise) {
            final prayerName = getPrayerName(enteredPrayer);
            // لتفادي الصوت المزدوج في الأندرويد، نمنع تشغيل الصوت من فلاتر
            // لأن نظام التنبيه الأصلي الجديد (Native Alarm) سيتكفل بالرنين الكامل.
            if (!Platform.isAndroid) {
              AdhanPlayerService().playAdhan(prayerName);
            }
          }

          // إذا حان وقت الصلاة، نعيد حساب الصلاة التي تليها
          _updateNextPrayer();
          scheduleAdhanNotifications();
          notifyListeners();
        } else {
          _timeUntilNextPrayer = _nextPrayerTime!.difference(now);
          notifyListeners();
        }
      }
    });
  }

  // دوال مساعدة لجلب الوقت كـ String منسق
  String getFormattedPrayerTime(Prayer prayer) {
    if (_prayerTimes == null) return '--:--';
    final time = _prayerTimes!.timeForPrayer(prayer);
    if (time == null) return '--:--';
    return DateFormat('hh:mm').format(time);
  }

  String getPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      case Prayer.none:
        return '';
    }
  }

  /// تحديث الموقع تلقائياً وبصمت دون إزعاج المستخدم إذا كانت الصلاحية ممنوحة مسبقاً
  Future<void> silentlyUpdateLocation() async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return;
    }

    try {
      // التحقق من صلاحيات الموقع
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        // التحقق من تفعيل الـ GPS بالهاتف
        final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
        if (isServiceEnabled) {
          final locationSettings =
              defaultTargetPlatform == TargetPlatform.android
              ? AndroidSettings(
                  accuracy: LocationAccuracy.low,
                  forceLocationManager: true,
                )
              : const LocationSettings(accuracy: LocationAccuracy.low);

          Position? pos = await Geolocator.getCurrentPosition(
            locationSettings: locationSettings,
          ).timeout(const Duration(seconds: 6));

          _lat = pos.latitude;
          _lng = pos.longitude;
          _coordinates = Coordinates(_lat, _lng);

          // جلب الاسم الجغرافي للمدينة
          try {
            final placemarks = await placemarkFromCoordinates(_lat, _lng);
            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              _cityName =
                  place.locality ??
                  place.subAdministrativeArea ??
                  place.administrativeArea ??
                  'موقعي الحالي';
            }
          } catch (_) {
            if (_cityName == 'مكة المكرمة') {
              _cityName = 'موقعي الحالي';
            }
          }

          // حفظ الإحداثيات والمدينة في الذاكرة لتشغيل أوفلاين للأبد
          await _saveLocationToPrefs(_lat, _lng, _cityName);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'last_location_update_time',
            DateTime.now().toIso8601String(),
          );

          _calculatePrayerTimes();
          await scheduleAdhanNotifications();
          notifyListeners();
                }
      }
    } catch (e) {
      debugPrint("Error in silentlyUpdateLocation: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _serviceStatusSubscription?.cancel();
    super.dispose();
  }
}
