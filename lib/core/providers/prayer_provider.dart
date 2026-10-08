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
import 'package:tarteel/Routes/AppRoutes.dart';

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
  String? _countryCode;
  double _lat = 21.4225;
  double _lng = 39.8262;
  late Coordinates _coordinates = Coordinates(_lat, _lng);
  CalculationMethod _calculationMethod = CalculationMethod.umm_al_qura;
  late CalculationParameters _calculationParameters = _calculationMethod
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
  String? get countryCode => _countryCode;
  CalculationMethod get calculationMethod => _calculationMethod;
  PrayerTimes? get prayerTimes => _prayerTimes;
  Prayer? get nextPrayer => _nextPrayer;
  DateTime? get nextPrayerTime => _nextPrayerTime;
  Duration get timeUntilNextPrayer => _timeUntilNextPrayer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// الاسم المعروض لطريقة الحساب المعتمدة حالياً
  String get calculationMethodName {
    switch (_calculationMethod) {
      case CalculationMethod.umm_al_qura:
        return 'تقويم أم القرى (مكة المكرمة)';
      case CalculationMethod.egyptian:
        return 'الهيئة المصرية العامة للمساحة';
      case CalculationMethod.dubai:
        return 'تقويم دبي الرسمي';
      case CalculationMethod.qatar:
        return 'تقويم قطر الرسمي';
      case CalculationMethod.kuwait:
        return 'تقويم الكويت الرسمي';
      case CalculationMethod.turkey:
        return 'رئاسة الشؤون الدينية التركية';
      case CalculationMethod.singapore:
        return 'المجلس الإسلامي لسنغافورة وجنوب شرق آسيا';
      case CalculationMethod.karachi:
        return 'جامعة العلوم الإسلامية بكراتشي';
      case CalculationMethod.north_america:
        return 'الجمعية الإسلامية لأمريكا الشمالية (ISNA)';
      case CalculationMethod.tehran:
        return 'جامعة طهران';
      case CalculationMethod.muslim_world_league:
      default:
        return 'رابطة العالم الإسلامي';
    }
  }

  /// تحديد طريقة الحساب الفلكية الأنسب تلقائياً بناءً على الدولة أو الإحداثيات
  CalculationMethod _determineCalculationMethod({
    String? countryCode,
    required double lat,
    required double lng,
  }) {
    if (countryCode != null && countryCode.trim().isNotEmpty) {
      switch (countryCode.trim().toUpperCase()) {
        case 'SA': // المملكة العربية السعودية
        case 'YE': // اليمن
          return CalculationMethod.umm_al_qura;
        case 'EG': // جمهورية مصر العربية
        case 'SD': // السودان
        case 'LY': // ليبيا
          return CalculationMethod.egyptian;
        case 'AE': // الإمارات العربية المتحدة
          return CalculationMethod.dubai;
        case 'QA': // قطر
          return CalculationMethod.qatar;
        case 'KW': // الكويت
          return CalculationMethod.kuwait;
        case 'TR': // تركيا
          return CalculationMethod.turkey;
        case 'SG': // سنغافورة
        case 'MY': // ماليزيا
        case 'ID': // إندونيسيا
          return CalculationMethod.singapore;
        case 'PK': // باكستان
        case 'IN': // الهند
        case 'BD': // بنغلاديش
        case 'AF': // أفغانستان
          return CalculationMethod.karachi;
        case 'US': // الولايات المتحدة
        case 'CA': // كندا
          return CalculationMethod.north_america;
        case 'IR': // إيران
          return CalculationMethod.tehran;
        default:
          // بلاد الشام والمغرب العربي وأوروبا وباقي دول العالم
          return CalculationMethod.muslim_world_league;
      }
    }

    // فحص جغرافي بديل بالإحداثيات في حال عدم توفر اتصال بالإنترنت لجلب رمز الدولة
    // نطاق جمهورية مصر العربية وشمال إفريقيا
    if (lat >= 12.0 && lat <= 32.0 && lng >= 22.0 && lng <= 37.0) {
      return CalculationMethod.egyptian;
    }
    // نطاق شبه الجزيرة العربية
    if (lat >= 12.0 && lat <= 32.5 && lng >= 37.0 && lng <= 60.0) {
      return CalculationMethod.umm_al_qura;
    }

    return CalculationMethod.muslim_world_league;
  }

  void _updateCalculationParameters() {
    _calculationParameters = _calculationMethod.getParameters();
  }

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
      _countryCode = prefs.getString('prayer_country_code');
      _coordinates = Coordinates(_lat, _lng);

      // استرجاع طريقة الحساب المحفوظة أو تحديدها تلقائياً للموقع
      final savedMethodIndex = prefs.getInt('prayer_calc_method_index');
      if (savedMethodIndex != null &&
          savedMethodIndex >= 0 &&
          savedMethodIndex < CalculationMethod.values.length) {
        _calculationMethod = CalculationMethod.values[savedMethodIndex];
      } else {
        _calculationMethod = _determineCalculationMethod(
          countryCode: _countryCode,
          lat: _lat,
          lng: _lng,
        );
      }
      _updateCalculationParameters();

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
      } else {
        // إذا كان الموقع قد تم سؤاله سابقاً، نتحقق من سؤال الأذان
        if (context.mounted) {
          await checkAndPromptAdhanActivation(context);
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
                    //
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
                          if (context.mounted && isFirstTime) {
                            await checkAndPromptAdhanActivation(context);
                          }
                        },
                        child: Text(
                          isFirstTime ? 'تفعيل الآن' : 'تحديث الموقع',
                          style: TextStyle(
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
                            _lat = 21.4225;
                            _lng = 39.8262;
                            _cityName = 'مكة المكرمة';
                            _countryCode = 'SA';
                            _coordinates = Coordinates(_lat, _lng);
                            _calculationMethod = CalculationMethod.umm_al_qura;
                            _updateCalculationParameters();
                            await _saveLocationToPrefs(
                              21.4225,
                              39.8262,
                              'مكة المكرمة',
                              countryCode: 'SA',
                            );
                            await prefs.setString(
                              'last_location_update_time',
                              DateTime.now().toIso8601String(),
                            );
                            _calculatePrayerTimes();
                            notifyListeners();
                            _showToast(
                              context,
                              'تم حفظ توقيت مكة المكرمة كخيار افتراضي',
                            );
                            if (context.mounted) {
                              await checkAndPromptAdhanActivation(context);
                            }
                          }
                        },
                        child: Text(
                          'ليس الآن',
                          style: TextStyle(
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

  /// التحقق وعرض رسالة تأكيد تفعيل أذان الصلوات التلقائي للمستخدم
  Future<void> checkAndPromptAdhanActivation(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasPromptedAdhan =
          prefs.getBool('has_prompted_adhan_activation') ?? false;

      if (!hasPromptedAdhan) {
        if (context.mounted) {
          await _showAdhanActivationDialog(context);
        }
      }
    } catch (e) {
      debugPrint("Error in checkAndPromptAdhanActivation: $e");
    }
  }

  /// نافذة حوار لتأكيد رغبة المستخدم في تفعيل تنبيهات الأذان والمؤذن
  Future<void> _showAdhanActivationDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
                // أيقونة المؤذن والأذان
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 38.sp,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 16.h),

                // العنوان الرئيسي
                Text(
                  'تفعيل أذان الصلوات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 12.h),

                // النص التوضيحي
                Text(
                  'هل ترغب في تشغيل صوت الأذان التلقائي عند دخول أوقات الصلاة بصوت المؤذن؟\n\nعند الموافقة، يمكنك اختيار المؤذن المفضل وتخصيص مستوى الصوت لكل صلاة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 24.h),

                // أزرار التحكم
                Row(
                  children: [
                    // زر الموافقة
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
                          Navigator.pop(dialogContext);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool(
                            'has_prompted_adhan_activation',
                            true,
                          );
                          await AdhanNotificationService.setPrayerNotificationsEnabled(
                            true,
                          );
                          await scheduleAdhanNotifications();
                          if (context.mounted) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.adhanMuezzin,
                            );
                          }
                        },
                        child: Text(
                          'موافق',
                          style: TextStyle(
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
                          Navigator.pop(dialogContext);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool(
                            'has_prompted_adhan_activation',
                            true,
                          );
                          await AdhanNotificationService.setPrayerNotificationsEnabled(
                            false,
                          );
                          await AdhanNotificationService.cancelPrayerAdhan();
                          if (context.mounted) {
                            _showToast(
                              context,
                              'تم إيقاف الأذان التلقائي، يمكنك تفعيله لاحقاً من قسم المؤذن',
                            );
                          }
                        },
                        child: Text(
                          'لا',
                          style: TextStyle(
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

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          _showToast(
            context,
            'تم رفض الوصول للموقع، يرجى إعطاء الصلاحية من إعدادات التطبيق للمتابعة',
          );
          await Geolocator.openAppSettings();
        }
        _calculationMethod = CalculationMethod.umm_al_qura;
        _updateCalculationParameters();
        await _saveLocationToPrefs(
          21.4225,
          39.8262,
          'مكة المكرمة',
          countryCode: 'SA',
        );
        await prefs.setString(
          'last_location_update_time',
          DateTime.now().toIso8601String(),
        );
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

      // جلب الاسم الجغرافي للمدينة ورمز الدولة
      String? detectedCountryCode;
      try {
        final placemarks = await placemarkFromCoordinates(_lat, _lng);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _cityName =
              place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              'موقعي الحالي';
          detectedCountryCode = place.isoCountryCode;
        }
      } catch (_) {
        _cityName = 'موقعي الحالي';
      }

      _countryCode = detectedCountryCode;
      _calculationMethod = _determineCalculationMethod(
        countryCode: _countryCode,
        lat: _lat,
        lng: _lng,
      );
      _updateCalculationParameters();

      // حفظ الإحداثيات والمدينة وطريقة الحساب في الذاكرة لتشغيل أوفلاين للأبد
      await _saveLocationToPrefs(
        _lat,
        _lng,
        _cityName,
        countryCode: _countryCode,
      );
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

  /// حفظ البيانات المشتركة وطريقة الحساب
  Future<void> _saveLocationToPrefs(
    double lat,
    double lng,
    String cityName, {
    String? countryCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('prayer_lat', lat);
    await prefs.setDouble('prayer_lng', lng);
    await prefs.setString('prayer_city_name', cityName);
    if (countryCode != null) {
      await prefs.setString('prayer_country_code', countryCode);
    }
    await prefs.setInt('prayer_calc_method_index', _calculationMethod.index);
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
            style: const TextStyle(fontWeight: FontWeight.bold),
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

          // جلب الاسم الجغرافي للمدينة ورمز الدولة
          String? detectedCountryCode;
          try {
            final placemarks = await placemarkFromCoordinates(_lat, _lng);
            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              _cityName =
                  place.locality ??
                  place.subAdministrativeArea ??
                  place.administrativeArea ??
                  'موقعي الحالي';
              detectedCountryCode = place.isoCountryCode;
            }
          } catch (_) {
            if (_cityName == 'مكة المكرمة') {
              _cityName = 'موقعي الحالي';
            }
          }

          _countryCode = detectedCountryCode;
          _calculationMethod = _determineCalculationMethod(
            countryCode: _countryCode,
            lat: _lat,
            lng: _lng,
          );
          _updateCalculationParameters();

          // حفظ الإحداثيات والمدينة وطريقة الحساب في الذاكرة لتشغيل أوفلاين للأبد
          await _saveLocationToPrefs(
            _lat,
            _lng,
            _cityName,
            countryCode: _countryCode,
          );

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
