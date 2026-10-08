/// وصف الملف:
/// هذا الملف يحتوي على الـ Widget المخصص لعرض حاوية الإجراءات السريعة في ترويسة الصفحة الرئيسية (HomeHeader).
/// يشمل أزرار الانتقال إلى: المفضلة، الإعدادات، القبلة، والتنبيهات (مع شارة عداد التنبيهات).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tarteel/core/providers/theme_provider.dart';
import 'package:tarteel/core/services/in_app_notification_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/routes/AppRoutes.dart';

class HomeHeaderQuickActions extends StatelessWidget {
  const HomeHeaderQuickActions({
    super.key,
    required this.activeNotifications,
    required this.onNotificationTap,
  });

  final List<InAppNotification> activeNotifications;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(top: 2.h, bottom: 2.h),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            context: context,
            icon: Icons.favorite_outline,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, AppRoutes.bookmarks);
            },
          ),
          _buildActionButton(
            context: context,
            icon: Icons.settings_outlined,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),

          _buildActionButton(
            context: context,
            icon: Icons.explore_outlined,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, AppRoutes.qibla);
            },
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildActionButton(
                context: context,
                icon: activeNotifications.isNotEmpty
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onNotificationTap();
                },
              ),
              if (activeNotifications.isNotEmpty)
                Positioned(
                  top: -2.h,
                  right: -2.w,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 12.w,
                      minHeight: 15.h,
                    ),
                    child: Text(
                      '${activeNotifications.length}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _buildActionButton(
            context: context,
            icon: isDark ? Icons.nights_stay_outlined : Icons.wb_sunny_outlined,
            onPressed: () async {
              HapticFeedback.lightImpact();
              final newTheme = isDark ? 'نهاري' : 'ليلي';
              await Provider.of<ThemeProvider>(
                context,
                listen: false,
              ).updateTheme(newTheme);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 32.w,
      height: 32.h,
      decoration: BoxDecoration(
        // border: Border.all(color: AppColors.darkPrimaryText),

        // color: colorScheme.surface.withValues(alpha: 0.3),
        color: Colors.black.withOpacity(0.15),

        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 20,
      ),
    );
  }
}
