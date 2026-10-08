import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/providers/prayer_provider.dart';
import 'package:tarteel/core/services/adhan_notification_service.dart';
import 'package:tarteel/core/services/native_alarm_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/muezzin_selection_sheet.dart';
import '../widgets/prayers_selection_sheet.dart';
import '../widgets/advance_time_selector.dart';
import '../widgets/volume_control_slider.dart';

class AdhanMuezzinScreen extends StatefulWidget {
  const AdhanMuezzinScreen({super.key});

  @override
  State<AdhanMuezzinScreen> createState() => _AdhanMuezzinScreenState();
}

class _AdhanMuezzinScreenState extends State<AdhanMuezzinScreen>
    with WidgetsBindingObserver {
  bool _soundEnabled = true;
  AdhanMuezzin _selectedMuezzin = AdhanNotificationService.defaultMuezzin;
  bool _hapticFeedback = true;
  double _adhanVolume = 1.0;
  bool _vibrationEnabled = true;
  bool _stopOnPowerButton = true;
  bool _isTestingAdhan = false;
  int _advanceMinutes = 15;

  // حالات تفعيل الأذان لكل صلاة على حدة
  bool _fajrEnabled = true;
  bool _dhuhrEnabled = true;
  bool _asrEnabled = true;
  bool _maghribEnabled = true;
  bool _ishaEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isTestingAdhan) {
      NativeAlarmService.stopActiveAlarm();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_stopOnPowerButton &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden)) {
      NativeAlarmService.stopActiveAlarm();
      if (mounted) {
        setState(() {
          _isTestingAdhan = false;
        });
      }
    }
  }

  Future<void> _loadSettings() async {
    final notificationsEnabled =
        await AdhanNotificationService.arePrayerNotificationsEnabled();
    final activeMuezzin = await AdhanNotificationService.selectedMuezzin();
    final advanceMinutes =
        await AdhanNotificationService.getAdhanAdvanceMinutes();
    final prefs = await SharedPreferences.getInstance();

    final fajr = await AdhanNotificationService.isSinglePrayerAdhanEnabled(
      Prayer.fajr,
    );
    final dhuhr = await AdhanNotificationService.isSinglePrayerAdhanEnabled(
      Prayer.dhuhr,
    );
    final asr = await AdhanNotificationService.isSinglePrayerAdhanEnabled(
      Prayer.asr,
    );
    final maghrib = await AdhanNotificationService.isSinglePrayerAdhanEnabled(
      Prayer.maghrib,
    );
    final isha = await AdhanNotificationService.isSinglePrayerAdhanEnabled(
      Prayer.isha,
    );

    if (!mounted) return;
    setState(() {
      _soundEnabled = notificationsEnabled;
      _selectedMuezzin = activeMuezzin;
      _advanceMinutes = advanceMinutes;
      _hapticFeedback = prefs.getBool('haptic_feedback') ?? true;
      _adhanVolume = prefs.getDouble('adhan_volume') ?? 1.0;
      _vibrationEnabled = prefs.getBool('adhan_vibration_enabled') ?? true;
      _stopOnPowerButton = prefs.getBool('stop_on_power_button') ?? true;
      _fajrEnabled = fajr;
      _dhuhrEnabled = dhuhr;
      _asrEnabled = asr;
      _maghribEnabled = maghrib;
      _ishaEnabled = isha;
    });
  }

  Future<void> _updateAdvanceMinutes(int minutes) async {
    if (_hapticFeedback) HapticFeedback.lightImpact();
    setState(() {
      _advanceMinutes = minutes;
    });
    await AdhanNotificationService.setAdhanAdvanceMinutes(minutes);
    if (mounted) {
      final prayerProvider = context.read<PrayerProvider>();
      await prayerProvider.scheduleAdhanNotifications();
    }
  }

  Future<void> _updateSoundEnabled(bool enabled) async {
    if (_hapticFeedback) HapticFeedback.lightImpact();
    setState(() {
      _soundEnabled = enabled;
    });

    await AdhanNotificationService.setPrayerNotificationsEnabled(enabled);

    if (!mounted) return;
    final prayerProvider = context.read<PrayerProvider>();
    if (enabled) {
      await prayerProvider.scheduleAdhanNotifications();
    } else {
      await AdhanNotificationService.cancelPrayerAdhan();
    }
  }

  Future<void> _updateAdhanVolume(double val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('adhan_volume', val);
    setState(() {
      _adhanVolume = val;
    });
    if (_isTestingAdhan) {
      await NativeAlarmService.stopActiveAlarm();
      if (mounted) {
        setState(() {
          _isTestingAdhan = false;
        });
      }
    }
    if (mounted) {
      final prayerProvider = context.read<PrayerProvider>();
      await prayerProvider.scheduleAdhanNotifications();
    }
  }

  Future<void> _updateVibrationEnabled(bool val) async {
    if (_hapticFeedback) HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhan_vibration_enabled', val);
    setState(() {
      _vibrationEnabled = val;
    });
    if (_isTestingAdhan) {
      await NativeAlarmService.updateTestVibration(val);
    }
    if (mounted) {
      final prayerProvider = context.read<PrayerProvider>();
      await prayerProvider.scheduleAdhanNotifications();
    }
  }

  Future<void> _toggleTestAdhan() async {
    if (_isTestingAdhan) {
      await NativeAlarmService.stopActiveAlarm();
      setState(() {
        _isTestingAdhan = false;
      });
    } else {
      if (_hapticFeedback) HapticFeedback.mediumImpact();

      setState(() {
        _isTestingAdhan = true;
      });

      final success = await NativeAlarmService.playTestAdhan(
        audioFile: _selectedMuezzin.rawResourceName,
        volume: _adhanVolume,
        vibrate: _vibrationEnabled,
      );

      if (!success) {
        setState(() {
          _isTestingAdhan = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل تشغيل الأذان التجريبي')),
          );
        }
      }
    }
  }

  Future<void> _startTestAdhanWithVolume(double val) async {
    if (_isTestingAdhan) return;

    setState(() {
      _isTestingAdhan = true;
    });

    final success = await NativeAlarmService.playTestAdhan(
      audioFile: _selectedMuezzin.rawResourceName,
      volume: val,
      vibrate: _vibrationEnabled,
    );

    if (!success) {
      setState(() {
        _isTestingAdhan = false;
      });
    }
  }

  void _showMuezzinSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MuezzinSelectionSheet(
        selectedMuezzin: _selectedMuezzin,
        isTestingAdhan: _isTestingAdhan,
        onStopTesting: () async {
          await NativeAlarmService.stopActiveAlarm();
          if (mounted) setState(() => _isTestingAdhan = false);
        },
        onMuezzinSelected: (muezzin) {
          setState(() {
            _selectedMuezzin = muezzin;
          });
        },
      ),
    );
  }

  void _showPrayersSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PrayersSelectionSheet(
        fajrEnabled: _fajrEnabled,
        dhuhrEnabled: _dhuhrEnabled,
        asrEnabled: _asrEnabled,
        maghribEnabled: _maghribEnabled,
        ishaEnabled: _ishaEnabled,
        onPrayerToggled: (prayer, enabled) {
          setState(() {
            switch (prayer) {
              case Prayer.fajr:
                _fajrEnabled = enabled;
                break;
              case Prayer.dhuhr:
                _dhuhrEnabled = enabled;
                break;
              case Prayer.asr:
                _asrEnabled = enabled;
                break;
              case Prayer.maghrib:
                _maghribEnabled = enabled;
                break;
              case Prayer.isha:
                _ishaEnabled = enabled;
                break;
              default:
                break;
            }
          });
        },
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
    Color? iconColor,
  }) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: effectiveIconColor, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: const tarteelAppBar(
          titleText: 'إعدادات المؤذن والأذان',
          elevation: 0,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'إعدادات الأذان الرئيسية',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              _buildSwitchTile(
                title: 'تشغيل الأذان التلقائي',
                subtitle: 'تنبيه بصوت المؤذن عند دخول وقت الصلاة',
                value: _soundEnabled,
                icon: Icons.notifications_active_outlined,
                onChanged: (value) => _updateSoundEnabled(value),
                iconColor: Colors.teal,
              ),

              _buildSwitchTile(
                title: 'الاهتزاز مع الأذان',
                subtitle: 'تفعيل الاهتزاز أثناء رفع الأذان',
                value: _vibrationEnabled,
                icon: Icons.vibration_rounded,
                onChanged: (value) => _updateVibrationEnabled(value),
                iconColor: Colors.blueGrey,
              ),

              // زر اختبار الأذان (مؤقت للمطورين)
              // Padding(
              //   padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              //   child: ElevatedButton.icon(
              //     onPressed: () async {
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         const SnackBar(
              //           content: Text('سيتم تشغيل الأذان بعد 10 ثوانٍ.. يمكنك الخروج من التطبيق للتحقق!'),
              //           duration: Duration(seconds: 4),
              //         ),
              //       );
              //       await AdhanNotificationService.testScheduleAdhanInSeconds(10, prayerName: 'الاختبار');
              //     },
              //     icon: const Icon(Icons.timer_outlined, color: Colors.white),
              //     label: Text('اختبار الأذان (10 ثوانٍ)', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.redAccent.shade400,
              //       foregroundColor: Colors.white,
              //       padding: EdgeInsets.symmetric(vertical: 12.h),
              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              //       elevation: 0,
              //     ),
              //   ),
              // ),

              if (_soundEnabled) ...[
                SizedBox(height: 12.h),
                // صف الأزرار الجديدة (صوت المؤذن + تخصيص الصلوات)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          title: 'صوت المؤذن',
                          subtitle: _selectedMuezzin.name,
                          icon: Icons.record_voice_over_outlined,
                          color: Colors.teal,
                          onTap: _showMuezzinSelectionSheet,
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildActionCard(
                          title: 'تخصيص الصلوات',
                          subtitle: 'تفعيل أو إيقاف',
                          icon: Icons.mosque_outlined,
                          color: Colors.indigo,
                          onTap: _showPrayersSelectionSheet,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // اختيار وقت التنبيه المسبق (مفصول في ملف)
                AdvanceTimeSelector(
                  selectedMinutes: _advanceMinutes,
                  onChanged: (val) => _updateAdvanceMinutes(val),
                ),

                SizedBox(height: 12.h),

                // مستوى الصوت وزر التجربة (مفصول في ملف)
                VolumeControlSlider(
                  volume: _adhanVolume,
                  isTestingAdhan: _isTestingAdhan,
                  onVolumeChanged: (val) {
                    setState(() {
                      _adhanVolume = val;
                    });
                    if (_isTestingAdhan) {
                      NativeAlarmService.updateTestVolume(val);
                    } else {
                      _startTestAdhanWithVolume(val);
                    }
                  },
                  onVolumeChangeEnd: (val) => _updateAdhanVolume(val),
                  onToggleTest: _toggleTestAdhan,
                ),

                SizedBox(height: 24.h),

                // صندوق معلومات
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'يتم تشغيل صوت الأذان كاملاً تلقائياً عند حلول وقت الصلاة وفقاً لموقع مكة المكرمة المبرمج محلياً في التطبيق.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
