import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/services/general_notification_service.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/views/surah_detail_page.dart';

class KhatmaPlannerScreen extends StatefulWidget {
  const KhatmaPlannerScreen({super.key});

  @override
  State<KhatmaPlannerScreen> createState() => _KhatmaPlannerScreenState();
}

class _KhatmaPlannerScreenState extends State<KhatmaPlannerScreen> {
  bool _isLoading = true;
  bool _showActiveKhatma = false;

  // Setup state variables
  double _daysSliderValue = 30;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);

  // Persistent active state variables
  int _totalAyahsRead = 0;
  int _ayahsReadToday = 0;
  DateTime? _startDate;

  static const int _totalQuranAyahs = 6236;

  @override
  void initState() {
    super.initState();
    _loadKhatmaPlan();
  }

  // Load plan state from SharedPreferences
  Future<void> _loadKhatmaPlan() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // إجبار التحديث من الذاكرة لضمان أحدث البيانات
      final active = prefs.getBool('khatma_active') ?? false;

      if (active) {
        final days = prefs.getInt('khatma_days') ?? 30;
        final startStr = prefs.getString('khatma_start_date');
        final totalRead = prefs.getInt('khatma_ayahs_read') ?? 0;
        var readToday = prefs.getInt('khatma_ayahs_read_today') ?? 0;
        final lastReadStr = prefs.getString('khatma_last_read_date');
        final rHour = prefs.getInt('khatma_reminder_hour') ?? 20;
        final rMin = prefs.getInt('khatma_reminder_minute') ?? 0;

        // Smart day change detection to reset daily pages
        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month}-${now.day}';

        if (lastReadStr != null) {
          final lastReadDate = DateTime.parse(lastReadStr);
          final lastReadDayStr =
              '${lastReadDate.year}-${lastReadDate.month}-${lastReadDate.day}';
          if (todayStr != lastReadDayStr) {
            readToday = 0;
            await prefs.setInt('khatma_ayahs_read_today', 0);
          }
        }

        if (mounted) {
          setState(() {
            _showActiveKhatma = true;
            _daysSliderValue = days.toDouble();
            _startDate = startStr != null ? DateTime.parse(startStr) : now;
            _totalAyahsRead = totalRead;
            _ayahsReadToday = readToday;
            _selectedTime = TimeOfDay(hour: rHour, minute: rMin);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _showActiveKhatma = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading Khatma Plan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Save and initialize a new Khatma Plan
  Future<void> _startKhatmaPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await prefs.setBool('khatma_active', true);
      await prefs.setInt('khatma_days', _daysSliderValue.toInt());
      await prefs.setString('khatma_start_date', now.toIso8601String());
      await prefs.setInt('khatma_ayahs_read', 0);
      await prefs.setInt('khatma_ayahs_read_today', 0);
      await prefs.setString('khatma_last_read_date', now.toIso8601String());
      await prefs.setInt('khatma_reminder_hour', _selectedTime.hour);
      await prefs.setInt('khatma_reminder_minute', _selectedTime.minute);
      await prefs.setInt('khatma_last_read_surah', 1);
      await prefs.setInt('khatma_last_read_ayah', 1);
      await prefs.setInt('khatma_max_reached_ayah', 0);

      // Schedule dynamic local notification
      await GeneralNotificationService.scheduleKhatmaReminder(
        _selectedTime.hour,
        _selectedTime.minute,
      );

      setState(() {
        _showActiveKhatma = true;
        _startDate = now;
        _totalAyahsRead = 0;
        _ayahsReadToday = 0;
      });
    } catch (e) {
      debugPrint('Error starting Khatma Plan: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Cancel the active plan entirely and delete from SharedPreferences
  Future<void> _cancelKhatmaPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('khatma_active');
      await prefs.remove('khatma_days');
      await prefs.remove('khatma_start_date');
      await prefs.remove('khatma_ayahs_read');
      await prefs.remove('khatma_ayahs_read_today');
      await prefs.remove('khatma_last_read_date');
      await prefs.remove('khatma_reminder_hour');
      await prefs.remove('khatma_reminder_minute');
      await prefs.remove('khatma_last_read_surah');
      await prefs.remove('khatma_last_read_ayah');
      await prefs.remove('khatma_max_reached_ayah');

      // Cancel local reminder notification
      await GeneralNotificationService.cancelKhatmaReminder();

      setState(() {
        _showActiveKhatma = false;
        _totalAyahsRead = 0;
        _ayahsReadToday = 0;
        _startDate = null;
      });
    } catch (e) {
      debugPrint('Error cancelling Khatma Plan: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToKhatmaReading() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final targetSurahNumber = prefs.getInt('khatma_last_read_surah') ?? 1;
      final targetAyah = prefs.getInt('khatma_last_read_ayah') ?? 1;

      final surahs = await QuranService.loadSurahs();
      final surah = surahs.firstWhere((s) => s.number == targetSurahNumber);
      final ayahs = await QuranService.loadAyahs(targetSurahNumber);

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurahDetailPage(
              surah: surah,
              ayahs: ayahs,
              initialAyah: targetAyah,
              isKhatmaSession: true,
            ),
          ),
        ).then((_) {
          _loadKhatmaPlan();
        });
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الانتقال إلى مصحف الختمة')),
        );
      }
    }
  }

  // Get calculated values
  int get _dailyAyahsNeeded {
    final double value = _totalQuranAyahs / _daysSliderValue;
    return value.ceil();
  }

  int get _elapsedDays {
    if (_startDate == null) return 1;
    final diff = DateTime.now().difference(_startDate!).inDays;
    return diff + 1;
  }

  int get _daysRemaining {
    final total = _daysSliderValue.toInt();
    if (_startDate == null) return total;
    final elapsed = DateTime.now().difference(_startDate!).inDays;
    final remaining = total - elapsed;
    return remaining.clamp(0, total);
  }

  double get _completionPercent {
    if (_totalAyahsRead == 0) return 0.0;
    return (_totalAyahsRead / _totalQuranAyahs).clamp(0.0, 1.0);
  }

  String _getExpectedCompletionDate() {
    final now = DateTime.now();
    final completionDate = now.add(Duration(days: _daysSliderValue.toInt()));
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${completionDate.day} ${months[completionDate.month - 1]} ${completionDate.year}';
  }

  // Daily Ward celebration dialog
  void _showCelebrationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.primary,
                      size: 48.sp,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    'الحمد لله حمداً كثيراً! 🎉✨',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'لقد أتممت قراءة الورد المحدد في خطتك اليومية بنجاح ($_dailyAyahsNeeded آية).',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'تقبل الله طاعتك وثبّت أجرك، ونراك غداً على خير في ورد جديد 🌸',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontFamily: 'Cairo',
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'آمين، تقبل الله 🤲',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Full Quran completion celebration dialog
  void _showFullQuranCelebrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 64.sp,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    'مبارك ختم القرآن الكريم! 🎉📖✨',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'الحمد لله الذي بنعمته تتم الصالحات! لقد أتممت ختم كتاب الله عز وجل بنجاح تام طوال هذه الرحلة المباركة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'تقبل الله منك صالح الأعمال وتلاوة القرآن العظيم، وجعله لك نوراً في الدنيا والآخرة وشفيعاً لك يوم القيامة 🤲🌸',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontFamily: 'Cairo',
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _cancelKhatmaPlan();
                      },
                      child: Text(
                        'آمين، وبدء ختمة جديدة 🌟',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Select reminder time
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });

      // Update notification time if the plan is already active
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('khatma_active') ?? false) {
        await prefs.setInt('khatma_reminder_hour', picked.hour);
        await prefs.setInt('khatma_reminder_minute', picked.minute);
        await GeneralNotificationService.scheduleKhatmaReminder(
          picked.hour,
          picked.minute,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const tarteelAppBar(
          titleText: 'خطة الختمة والورد اليومي',
          elevation: 0,
          toolbarHeight: 90,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _showActiveKhatma
                    ? _buildActiveKhatmaDashboard(cardBg, isDark)
                    : _buildSetupKhatmaView(cardBg, isDark),
              ),
      ),
    );
  }

  // ==================== 1. Setup Plan View ====================
  Widget _buildSetupKhatmaView(Color cardBg, bool isDark) {
    return ListView(
      key: const ValueKey('setup_view'),
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        // Premium Intro Header Card
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.85),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories, color: Colors.white, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'تحدي ختم القرآن الكريم',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                'اضبط لنفسك تحدياً مميزاً لختم كتاب الله بانتظام وتتبع وردك اليومي. حدد مدة التحدي وسيحسب التطبيق عدد الصفحات التي عليك قراءتها يومياً وسيذكرك بموعد القراءة.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11.sp,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        // Slider for choosing number of days
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'مدة تحدي الختمة (بالأيام)',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${_daysSliderValue.toInt()} يوماً',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Slider.adaptive(
                value: _daysSliderValue,
                min: 5,
                max: 120,
                divisions: 23,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    _daysSliderValue = val;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '5 أيام',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontFamily: 'Cairo',
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '30 يوماً',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontFamily: 'Cairo',
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '60 يوماً',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontFamily: 'Cairo',
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '120 يوماً',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontFamily: 'Cairo',
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Calculations Display
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              _buildCalculationRow(
                icon: Icons.menu_book_rounded,
                title: 'الورد اليومي المطلوب:',
                value: '$_dailyAyahsNeeded آية',
                subValue:
                    '(${(_dailyAyahsNeeded / 207).toStringAsFixed(1)} جزء تقريباً)',
                isPrimary: true,
              ),
              const Divider(height: 24),
              _buildCalculationRow(
                icon: Icons.event_available_rounded,
                title: 'تاريخ الختم المتوقع:',
                value: _getExpectedCompletionDate(),
                subValue: 'بإذن الله تعالى',
                isPrimary: false,
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Time picker for daily reminders
        InkWell(
          onTap: () => _selectTime(context),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'وقت التذكير اليومي بالورد',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'انقر لتعديل وقت ظهور التنبيه اليومي المخصص',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontFamily: 'Cairo',
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _selectedTime.format(context),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14.sp,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 30.h),

        // Start challenge button
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              onPressed: _startKhatmaPlan,
              child: Text(
                'بدء تحدي الختمة والالتزام 🌟',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildCalculationRow({
    required IconData icon,
    required String title,
    required String value,
    required String subValue,
    required bool isPrimary,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: (isPrimary ? AppColors.primary : Colors.teal).withValues(
              alpha: 0.1,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isPrimary ? AppColors.primary : Colors.teal,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                  color: Colors.grey.shade500,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                      color: isPrimary ? AppColors.primary : Colors.teal,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    subValue,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== 2. Active Dashboard View ====================
  Widget _buildActiveKhatmaDashboard(Color cardBg, bool isDark) {
    return ListView(
      key: const ValueKey('active_dashboard'),
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        // Overall circular progress card
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تحدي الختمة والورد',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'الخطة الكاملة: ${_daysSliderValue.toInt()} يوماً',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  // Edit Button
                  IconButton(
                    icon: Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                    onPressed: () {
                      // Confirms before editing existing plan
                      showDialog(
                        context: context,
                        builder: (ctx) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: AlertDialog(
                            backgroundColor: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            title: Text(
                              'تعديل الخطة الحالية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              'هل تريد تعديل الخطة الحالية؟ سيؤدي ذلك لإعادة ضبط الأيام والورد من جديد مع الاحتفاظ بالآيات المقروءة.',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.sp,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text(
                                  'إلغاء',
                                  style: TextStyle(fontFamily: 'Cairo'),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _showActiveKhatma = false;
                                  });
                                },
                                child: const Text(
                                  'تعديل',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Progress Circle
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120.w,
                    height: 120.w,
                    child: CircularProgressIndicator(
                      value: _completionPercent,
                      strokeWidth: 10.w,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(_completionPercent * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'مكتمل من المصحف',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Bottom row statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat(
                    'الآيات المقروءة',
                    '$_totalAyahsRead / $_totalQuranAyahs',
                  ),
                  Container(
                    width: 1,
                    height: 30.h,
                    color: Colors.grey.shade300,
                  ),
                  _buildMiniStat('الأيام المتبقية', '$_daysRemaining يوماً'),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Today's Ward Progress Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الورد المطلوب اليوم',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '$_ayahsReadToday / $_dailyAyahsNeeded آية',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: LinearProgressIndicator(
                  value: (_ayahsReadToday / _dailyAyahsNeeded).clamp(0.0, 1.0),
                  minHeight: 13.h,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الآيات المقروءة حتى الآن: $_totalAyahsRead',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontFamily: 'Cairo',
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _ayahsReadToday >= _dailyAyahsNeeded
                        ? 'أتممت ورد اليوم بنجاح'
                        : 'المتبقي لليوم: ${(_dailyAyahsNeeded - _ayahsReadToday).clamp(0, _dailyAyahsNeeded)} آية',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: _ayahsReadToday >= _dailyAyahsNeeded
                          ? Colors.green
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Reading Position Info Card
        FutureBuilder<Map<String, dynamic>>(
          future: () async {
            final prefs = await SharedPreferences.getInstance();
            final surahNumber = prefs.getInt('khatma_last_read_surah') ?? 1;
            final page = prefs.getInt('khatma_last_read_ayah') ?? 1;
            final surahs = await QuranService.loadSurahs();
            final surah = surahs.firstWhere((s) => s.number == surahNumber);
            final hasStarted = prefs.getInt('khatma_last_read_surah') != null;
            return {
              'surahName': surah.nameArabic,
              'ayah': page,
              'hasStarted': hasStarted,
            };
          }(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final data = snapshot.data!;
            final surahName = data['surahName'] as String;
            final ayah = data['ayah'] as int;
            final hasStarted = data['hasStarted'] as bool;

            return Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chrome_reader_mode_rounded,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'آخر موضع وصلت إليه',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo',
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          hasStarted
                              ? 'سورة $surahName (الآية $ayah)'
                              : 'لم تبدأ القراءة في هذه الختمة بعد (ستبدأ من الفاتحة)',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: hasStarted
                                ? AppColors.primary
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        SizedBox(height: 20.h),

        // Read daily ward button
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              onPressed: _navigateToKhatmaReading,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'اذهب لقراءة القرآن الكريم الآن',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 14.h),

        // Cancel Active Khatma Option
        Center(
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
            onPressed: () {
              // Confirm deletion
              showDialog(
                context: context,
                builder: (ctx) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    backgroundColor: isDark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    title: Text(
                      'إلغاء الختمة الحالية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    content: Text(
                      'هل أنت متأكد تماماً من إلغاء وحذف هذه الختمة نهائياً؟ سيؤدي ذلك لمسح كل تقدمك التراكمي بالأيام والآيات.',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp),
                    ),
                    actions: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'تراجع',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _cancelKhatmaPlan();
                            },
                            child: const Text(
                              'نعم، الغاء الخطة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white,
                                fontSize: 9,
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
            icon: Icon(Icons.delete_outline_rounded, size: 16.sp),
            label: Text(
              'إنهاء وإلغاء هذه الختمة نهائياً',
              style: TextStyle(
                fontSize: 11.sp,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
            fontFamily: 'Cairo',
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            fontFamily: 'Cairo',
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
