import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/providers/prayer_provider.dart';
import 'package:tarteel/core/services/adhan_notification_service.dart';
import 'package:tarteel/core/services/native_alarm_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdhanMuezzinScreen extends StatefulWidget {
  const AdhanMuezzinScreen({super.key});

  @override
  State<AdhanMuezzinScreen> createState() => _AdhanMuezzinScreenState();
}

class _AdhanMuezzinScreenState extends State<AdhanMuezzinScreen>
    with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();

  bool _soundEnabled = true;
  AdhanMuezzin _selectedMuezzin = AdhanNotificationService.defaultMuezzin;
  bool _hapticFeedback = true;
  double _adhanVolume = 1.0;
  bool _vibrationEnabled = true;
  bool _stopOnPowerButton = true;
  bool _isTestingAdhan = false;
  String? _playingMuezzinId;
  bool _isSaving = false;

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
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() => _playingMuezzinId = null);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
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
      _player.stop();
      NativeAlarmService.stopActiveAlarm();
      if (mounted) {
        setState(() {
          _isTestingAdhan = false;
          _playingMuezzinId = null;
        });
      }
    }
  }

  Future<void> _loadSettings() async {
    final notificationsEnabled =
        await AdhanNotificationService.arePrayerNotificationsEnabled();
    final activeMuezzin = await AdhanNotificationService.selectedMuezzin();
    final prefs = await SharedPreferences.getInstance();

    final fajr = await AdhanNotificationService.isSinglePrayerAdhanEnabled(Prayer.fajr);
    final dhuhr = await AdhanNotificationService.isSinglePrayerAdhanEnabled(Prayer.dhuhr);
    final asr = await AdhanNotificationService.isSinglePrayerAdhanEnabled(Prayer.asr);
    final maghrib = await AdhanNotificationService.isSinglePrayerAdhanEnabled(Prayer.maghrib);
    final isha = await AdhanNotificationService.isSinglePrayerAdhanEnabled(Prayer.isha);

    if (!mounted) return;
    setState(() {
      _soundEnabled = notificationsEnabled;
      _selectedMuezzin = activeMuezzin;
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

  Future<void> _updatePrayerAdhanEnabled(Prayer prayer, bool enabled) async {
    if (_hapticFeedback) HapticFeedback.lightImpact();

    await AdhanNotificationService.setSinglePrayerAdhanEnabled(prayer, enabled);

    if (!mounted) return;
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

    final prayerProvider = context.read<PrayerProvider>();
    await prayerProvider.scheduleAdhanNotifications();
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

  // ignore: unused_element
  Future<void> _updateStopOnPowerButton(bool val) async {
    if (_hapticFeedback) HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('stop_on_power_button', val);
    setState(() {
      _stopOnPowerButton = val;
    });
  }

  Future<void> _toggleTestAdhan() async {
    if (_isTestingAdhan) {
      await NativeAlarmService.stopActiveAlarm();
      setState(() {
        _isTestingAdhan = false;
      });
    } else {
      if (_playingMuezzinId != null) {
        await _player.stop();
        setState(() {
          _playingMuezzinId = null;
        });
      }

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
    if (_playingMuezzinId != null) {
      await _player.stop();
      setState(() {
        _playingMuezzinId = null;
      });
    }

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

  Future<void> _togglePreview(AdhanMuezzin muezzin) async {
    if (_isTestingAdhan) {
      await NativeAlarmService.stopActiveAlarm();
      setState(() {
        _isTestingAdhan = false;
      });
    }

    if (_playingMuezzinId == muezzin.id) {
      await _player.stop();
      if (!mounted) return;
      setState(() => _playingMuezzinId = null);
      return;
    }

    setState(() => _playingMuezzinId = muezzin.id);
    try {
      await _player.stop();
      await _player.setAsset(muezzin.assetPath);
      await _player.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingMuezzinId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر تشغيل صوت المؤذن')));
    }
  }

  Future<void> _selectMuezzin(AdhanMuezzin muezzin) async {
    if (_hapticFeedback) HapticFeedback.mediumImpact();
    setState(() {
      _selectedMuezzin = muezzin;
      _isSaving = true;
    });

    if (_isTestingAdhan) {
      await NativeAlarmService.stopActiveAlarm();
      setState(() {
        _isTestingAdhan = false;
      });
    }

    await AdhanNotificationService.setSelectedMuezzin(muezzin);

    if (!mounted) return;
    await context.read<PrayerProvider>().scheduleAdhanNotifications();

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('تم اختيار ${muezzin.name} للأذان')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: const tarteelAppBar(
            titleText: 'إعدادات المؤذن والأذان',
            elevation: 0,
          ),
          body: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                height: 44.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      isDark ? Colors.white60 : Colors.grey.shade700,
                  labelStyle: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: EdgeInsets.all(3.w),
                  tabs: const [
                    Tab(text: 'تخصيص المؤذن'),
                    Tab(text: 'تنبيهات الفرائض'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildMuezzinSettingsTab(context, theme, isDark),
                    _buildPrayerTogglesTab(context, theme, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMuezzinSettingsTab(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return SingleChildScrollView(
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
                'اعدادات الاذان',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
            ],
          ),

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
            subtitle: 'تفعيل اهتزاز الهاتف عند تشغيل الأذان',
            value: _vibrationEnabled,
            icon: Icons.vibration_rounded,
            onChanged: (value) => _updateVibrationEnabled(value),
            iconColor: Colors.blueGrey,
          ),

          SizedBox(height: 10.h),

          // الحاوية الأصلية لمستوى صوت الأذان بزر المعاينة التجريبي
          if (_soundEnabled) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            'مستوى صوت الأذان',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: Colors.amber,
                          size: 15.sp,
                        ),
                      ),
                      Slider(
                        value: _adhanVolume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.primary.withValues(
                          alpha: 0.2,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _adhanVolume = val;
                          });
                          if (_isTestingAdhan) {
                            NativeAlarmService.updateTestVolume(val);
                          } else {
                            _startTestAdhanWithVolume(val);
                          }
                        },
                        onChangeEnd: (val) {
                          _updateAdhanVolume(val);
                        },
                      ),
                      Text(
                        '${(_adhanVolume * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(
                        width: 100.w,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            FilledButton(
                              onPressed: _toggleTestAdhan,
                              style: FilledButton.styleFrom(
                                backgroundColor: _isTestingAdhan
                                    ? Colors.red.shade600
                                    : AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: Size(40.w, 10.h),
                                padding: EdgeInsets.all(2.w),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                elevation: 2,
                                shadowColor:
                                    (_isTestingAdhan
                                            ? Colors.red.shade600
                                            : AppColors.primary)
                                        .withValues(alpha: 0.25),
                              ),
                              child: Icon(
                                _isTestingAdhan
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // قائمة اختيار المؤذنين الأصلية
          if (_soundEnabled) ...[
            SizedBox(height: 16.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
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
                    'اختر صوت المؤذن للأذان',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            ...List.generate(AdhanNotificationService.muezzins.length, (
              index,
            ) {
              final muezzin = AdhanNotificationService.muezzins[index];
              final isSelected = _selectedMuezzin.id == muezzin.id;
              final isPlaying = _playingMuezzinId == muezzin.id;

              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100),
                    width: isSelected ? 1.6 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(
                        alpha: isSelected ? 0.05 : 0.02,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : (isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check
                            : Icons.record_voice_over_outlined,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600),
                        size: 15.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        muezzin.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isSelected ? AppColors.primary : null,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton.filledTonal(
                      tooltip: isPlaying ? 'إيقاف المعاينة' : 'استماع للمؤذن',
                      onPressed: () => _togglePreview(muezzin),
                      icon: Icon(
                        isPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        size: 20.sp,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: isPlaying
                            ? Colors.red.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.1),
                        foregroundColor: isPlaying
                            ? Colors.red
                            : AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    FilledButton(
                      onPressed: isSelected || _isSaving
                          ? null
                          : () => _selectMuezzin(muezzin),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: _isSaving && isSelected
                          ? SizedBox(
                              width: 10.w,
                              height: 10.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isSelected ? 'مختار' : 'تفعيل',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              );
            }),
          ],

          SizedBox(height: 16.h),

          // صندوق معلومات الموعد التلقائي الأصلي
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
                      fontSize: 12.sp,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTogglesTab(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.primary,
                  size: 22.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'يمكنك تفعيل أو إيقاف تشغيل نغمة الأذان لكل صلاة بشكل مستقل حسب اختيارك.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildPrayerSwitchTile(
            title: 'صلاة الفجر',
            subtitle: 'تفعيل الأذان لصلاة الفجر',
            value: _fajrEnabled,
            icon: Icons.wb_twilight,
            iconColor: Colors.amber.shade800,
            onChanged: (val) => _updatePrayerAdhanEnabled(Prayer.fajr, val),
            isDark: isDark,
          ),

          _buildPrayerSwitchTile(
            title: 'صلاة الظهر',
            subtitle: 'تفعيل الأذان لصلاة الظهر',
            value: _dhuhrEnabled,
            icon: Icons.wb_sunny,
            iconColor: Colors.orange.shade700,
            onChanged: (val) => _updatePrayerAdhanEnabled(Prayer.dhuhr, val),
            isDark: isDark,
          ),

          _buildPrayerSwitchTile(
            title: 'صلاة العصر',
            subtitle: 'تفعيل الأذان لصلاة العصر',
            value: _asrEnabled,
            icon: Icons.wb_sunny_outlined,
            iconColor: Colors.deepOrange,
            onChanged: (val) => _updatePrayerAdhanEnabled(Prayer.asr, val),
            isDark: isDark,
          ),

          _buildPrayerSwitchTile(
            title: 'صلاة المغرب',
            subtitle: 'تفعيل الأذان لصلاة المغرب',
            value: _maghribEnabled,
            icon: Icons.wb_twilight_outlined,
            iconColor: Colors.indigo,
            onChanged: (val) => _updatePrayerAdhanEnabled(Prayer.maghrib, val),
            isDark: isDark,
          ),

          _buildPrayerSwitchTile(
            title: 'صلاة العشاء',
            subtitle: 'تفعيل الأذان لصلاة العشاء',
            value: _ishaEnabled,
            icon: Icons.nights_stay_outlined,
            iconColor: Colors.blueGrey,
            onChanged: (val) => _updatePrayerAdhanEnabled(Prayer.isha, val),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color iconColor,
    required Function(bool) onChanged,
    required bool isDark,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: value
              ? iconColor.withValues(alpha: 0.3)
              : (isDark ? Colors.white10 : Colors.grey.shade200),
          width: value ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: iconColor,
            activeTrackColor: iconColor.withValues(alpha: 0.3),
          ),
        ],
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
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
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
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
}
