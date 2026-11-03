import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/services/general_notification_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IslamicNotificationsPage extends StatefulWidget {
  const IslamicNotificationsPage({super.key});

  @override
  State<IslamicNotificationsPage> createState() => _IslamicNotificationsPageState();
}

class _IslamicNotificationsPageState extends State<IslamicNotificationsPage> {
  bool _notificationsAzkar = false;
  bool _notificationsCustom = false;
  bool _notificationsFriday = false;
  bool _notificationsFasting = false;
  bool _notificationsDuha = false;
  bool _notificationsQiyam = false;
  bool _notificationsDailyContent = false;
  bool _hapticFeedback = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      _notificationsAzkar = prefs.getBool('notifications_azkar') ?? true;
      _notificationsCustom = prefs.getBool('notifications_custom') ?? false;
      _notificationsFriday = prefs.getBool('notifications_friday') ?? true;
      _notificationsFasting = prefs.getBool('notifications_fasting') ?? true;
      _notificationsDuha = prefs.getBool('notifications_duha') ?? true;
      _notificationsQiyam = prefs.getBool('notifications_qiyam') ?? true;
      _notificationsDailyContent = prefs.getBool('notifications_daily_content') ?? true;
      _hapticFeedback = prefs.getBool('haptic_feedback') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const tarteelAppBar(titleText: 'الإشعارات الإسلامية', elevation: 0),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          children: [
            _buildSection(
              title: 'التنبيهات والأذكار المجدولة',
              isDark: isDark,
              children: [
                _buildSwitchTile(
                  title: 'أذكار الصباح والمساء والنوم',
                  subtitle: 'تنبيهات يومية لقراءة الأذكار المأثورة في أوقاتها',
                  value: _notificationsAzkar,
                  icon: Icons.spa_outlined,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_azkar', val);
                    setState(() {
                      _notificationsAzkar = val;
                    });
                    await GeneralNotificationService.scheduleAllEnabledNotifications();
                    if (_hapticFeedback) HapticFeedback.lightImpact();
                  },
                  iconColor: Colors.amber.shade700,
                ),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _buildSwitchTile(
                  title: 'التذكير الدوري بالأذكار',
                  subtitle: 'إشعارات دورية بالاستغفار والصلاة على النبي ﷺ',
                  value: _notificationsCustom,
                  icon: Icons.access_alarm_rounded,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_custom', val);
                    setState(() {
                      _notificationsCustom = val;
                    });
                    await GeneralNotificationService.scheduleAllEnabledNotifications();
                    if (_hapticFeedback) HapticFeedback.lightImpact();
                  },
                  iconColor: Colors.orange.shade700,
                ),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _buildSwitchTile(
                  title: 'تنبيهات يوم الجمعة',
                  subtitle: 'تذكير بقراءة سورة الكهف والسنن والصلاة على النبي ﷺ',
                  value: _notificationsFriday,
                  icon: Icons.mosque_outlined,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_friday', val);
                    setState(() {
                      _notificationsFriday = val;
                    });
                    await GeneralNotificationService.scheduleAllEnabledNotifications();
                    if (_hapticFeedback) HapticFeedback.lightImpact();
                  },
                  iconColor: Colors.green.shade700,
                ),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _buildSwitchTile(
                  title: 'تذكير صيام الاثنين والخميس',
                  subtitle: 'تنبيه في الليلة السابقة بفضل صيام السنن المؤكدة',
                  value: _notificationsFasting,
                  icon: Icons.calendar_month_outlined,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_fasting', val);
                    setState(() {
                      _notificationsFasting = val;
                    });
                    await GeneralNotificationService.scheduleAllEnabledNotifications();
                    if (_hapticFeedback) HapticFeedback.lightImpact();
                  },
                  iconColor: Colors.indigo.shade600,
                ),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _buildSwitchTile(
                  title: 'تذكير صلاة الضحى',
                  subtitle: 'تنبيه يومي لأداء صلاة الأوابين والصدقة اليومية',
                  value: _notificationsDuha,
                  icon: Icons.wb_sunny_outlined,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_duha', val);
                    setState(() {
                      _notificationsDuha = val;
                    });
                    await GeneralNotificationService.scheduleAllEnabledNotifications();
                    if (_hapticFeedback) HapticFeedback.lightImpact();
                  },
                  iconColor: Colors.amber.shade600,
                ),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _buildSwitchTile(
                  title: 'تذكير قيام الليل والوتر',
                  subtitle: 'تنبيه في الثلث الأخير من الليل للدعاء والاستغفار',
                  value: _notificationsQiyam,
                  icon: Icons.nights_stay_outlined,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_qiyam', val);
                    setState(() {
                      _notificationsQiyam = val;
                    });
                    await GeneralNotificationService.scheduleAllEnabledNotifications();
                    if (_hapticFeedback) HapticFeedback.lightImpact();
                  },
                  iconColor: Colors.purple.shade600,
                ),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _buildSwitchTile(
                  title: 'آية وحديث اليوم',
                  subtitle: 'إشعار يومي يجمع لك نور الهداية والقرآن والسنة',
                  value: _notificationsDailyContent,
                  icon: Icons.menu_book_outlined,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_daily_content', val);
                    setState(() {
                      _notificationsDailyContent = val;
                    });
                    await GeneralNotificationService.scheduleAllEnabledNotifications();
                    if (_hapticFeedback) HapticFeedback.lightImpact();
                  },
                  iconColor: Colors.blue.shade600,
                ),
              ],
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.shade100,
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              right: 20.w,
              left: 20.w,
              top: 18.h,
              bottom: 8.h,
            ),
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
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.primary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          ...children,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
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
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    color: Colors.grey.shade500,
                    height: 1.3,
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
