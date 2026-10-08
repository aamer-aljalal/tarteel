import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/features/home/widgets/home_header/home_mini_header.dart';
import 'package:tarteel/features/home/widgets/home_header/home_header_quick_actions.dart';
import 'package:tarteel/features/home/widgets/home_header/home_notifications_sheet.dart';
import 'package:tarteel/features/home/widgets/home_header/home_prayer_card.dart';
import 'package:tarteel/features/home/widgets/home_azkar_prompt_card.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tarteel/core/providers/prayer_provider.dart';
import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:tarteel/routes/AppRoutes.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/views/surah_detail_page.dart';
import 'package:tarteel/features/azkar/services/azkar_service.dart';
import 'package:tarteel/features/azkar/zkar_details.dart';
import 'package:tarteel/core/services/in_app_notification_service.dart';
import 'package:tarteel/main.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> with RouteAware {
  bool _isNumericFormat = false;
  List<InAppNotification> _activeNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      tarteel.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    tarteel.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadNotifications();
    if (mounted) {
      context.read<PrayerProvider>().initializeData();
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final list = await InAppNotificationService.getActiveNotifications();
      if (mounted) {
        setState(() {
          _activeNotifications = list;
        });
      }
    } catch (_) {}
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return HomeNotificationsSheet(
          notifications: _activeNotifications,
          onNotificationTap: (notification) async {
            await _handleNotificationClick(notification);
            await _loadNotifications();
          },
        );
      },
    );
  }

  Future<void> _handleNotificationClick(InAppNotification notif) async {
    if (notif.type == 'surah_kahf') {
      try {
        final surahs = await QuranService.loadSurahs();
        final kahfSurah = surahs.firstWhere((s) => s.number == 18);
        final ayahs = await QuranService.loadAyahs(18);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SurahDetailPage(surah: kahfSurah, ayahs: ayahs),
          ),
        ).then((_) => _loadNotifications());
      } catch (_) {}
    } else if (notif.type == 'morning_azkar' ||
        notif.type == 'evening_azkar' ||
        notif.type == 'sleep_azkar') {
      try {
        final targetTitle = notif.type == 'morning_azkar'
            ? 'أذكار الصباح'
            : notif.type == 'evening_azkar'
            ? 'أذكار المساء'
            : 'أذكار النوم';
        final categories = await AzkarService.loadAzkar();
        final match = categories.firstWhere((c) => c.title == targetTitle);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AzkarDetailsScreen(category: match),
          ),
        ).then((_) => _loadNotifications());
      } catch (_) {}
    } else {
      await InAppNotificationService.markCompleted(notif.type);

      String message = 'تقبل الله طاعتك وصالح أعمالك';
      if (notif.type == 'fasting') {
        message = 'تقبل الله صيامك وطاعتك المباركة';
      } else if (notif.type == 'daily_content') {
        message = 'تم الإطلاع على آية وحديث اليوم بنجاح';
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.hadith,
          ).then((_) => _loadNotifications());
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, textAlign: TextAlign.right),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  String _getGregorianDate(bool isNumeric) {
    final now = DateTime.now();
    final day = DateFormat('d', 'en').format(now);
    final year = DateFormat('yyyy', 'en').format(now);
    if (isNumeric) {
      final month = DateFormat('M', 'en').format(now);
      return '\u200F$day / $month / \u200F$year';
    } else {
      final month = DateFormat('MMMM', 'ar').format(now);
      return '\u200F$day $month \u200F$year';
    }
  }

  String _getHijriDate(bool isNumeric) {
    HijriCalendar.setLocal('ar');
    final hijri = HijriCalendar.now();
    final day = hijri.hDay;
    final year = hijri.hYear;
    if (isNumeric) {
      final month = hijri.hMonth;
      return '\u200F$day / $month / \u200F$year';
    } else {
      final month = hijri.getLongMonthName();
      return '\u200F$day $month \u200F$year';
    }
  }

  @override
  Widget build(BuildContext context) {
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentPrayerTimes = {
      'الفجر': prayerProvider.getFormattedPrayerTime(Prayer.fajr),
      'الظهر': prayerProvider.getFormattedPrayerTime(Prayer.dhuhr),
      'العصر': prayerProvider.getFormattedPrayerTime(Prayer.asr),
      'المغرب': prayerProvider.getFormattedPrayerTime(Prayer.maghrib),
      'العشاء': prayerProvider.getFormattedPrayerTime(Prayer.isha),
    };

    final dynamicNextPrayer =
        prayerProvider.nextPrayer != null &&
            prayerProvider.nextPrayer != Prayer.none
        ? prayerProvider.getPrayerName(prayerProvider.nextPrayer!)
        : '...';

    final countdown = prayerProvider.timeUntilNextPrayer.inSeconds > 0
        ? _formatDuration(prayerProvider.timeUntilNextPrayer)
        : '--:--';

    return SliverToBoxAdapter(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          margin: EdgeInsets.only(bottom: 20.h),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/img/header_bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 10.w,
                top: 10.h,
                right: 10.w,
                bottom: 16.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HomeMiniHeader(
                    hijriDate: _getHijriDate(_isNumericFormat),
                    gregorianDate: _getGregorianDate(_isNumericFormat),
                    onDateTap: () {
                      setState(() {
                        _isNumericFormat = !_isNumericFormat;
                      });
                      HapticFeedback.lightImpact();
                    },
                  ),

                  // بطاقة أوقات الصلاة الأفقية (تحتوي على التوقيت المحلي ومؤشر الباقي للصلاة)
                  HomePrayerCard(
                    countdown: countdown,
                    dynamicNextPrayer: dynamicNextPrayer,
                    currentPrayerTimes: currentPrayerTimes,
                    cityName: prayerProvider.cityName,
                    isLoadingLocation: prayerProvider.isLoading,
                    onUpdateLocation: () async {
                      await prayerProvider.updateLocationManually(context);
                    },
                  ),

                  // حاوية الأيقونات الأربعة في منتصف الترويسة (المفضلة، الإعدادات، القبلة، والتنبيهات)
                  HomeHeaderQuickActions(
                    activeNotifications: _activeNotifications,
                    onNotificationTap: () {
                      _showNotificationsBottomSheet(context);
                    },
                  ),

                  // بطاقة تنبيه الأذكار (لا تحركها أبداً)
                  const HomeAzkarPromptCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    int hours = d.inHours;
    int minutes = d.inMinutes.remainder(60);
    int seconds = d.inSeconds.remainder(60);
    return "$hours:${twoDigits(minutes)}:${twoDigits(seconds)}";
  }
}
