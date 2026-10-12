import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tarteel/core/services/in_app_notification_service.dart';
import 'package:tarteel/core/services/recent_actions_navigator.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/bottom_sheets/app_modal_bottom_sheet.dart';

class HomeNotificationsSheet extends StatefulWidget {
  const HomeNotificationsSheet({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
  });

  final List<InAppNotification> notifications;
  final Future<void> Function(InAppNotification notification) onNotificationTap;

  @override
  State<HomeNotificationsSheet> createState() => _HomeNotificationsSheetState();
}

class _HomeNotificationsSheetState extends State<HomeNotificationsSheet> {
  List<RecentAction> _recentActions = [];
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    _loadRecentActions();
  }

  Future<void> _loadRecentActions() async {
    try {
      final actions = await RecentActionsManager.getActions();
      if (mounted) {
        setState(() {
          _recentActions = actions.take(5).toList();
          _isLoadingRecent = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRecent = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppModalBottomSheet(
      title: 'التنبيهات والمحطات الأخيرة',
      heightFraction: 0.52,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
      trailing: widget.notifications.isNotEmpty
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.red.shade700.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '${widget.notifications.length} معلقة',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                ),
              ),
            )
          : null,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. قسم تنبيهات اليوم الفائتة أولاً
            _buildNotificationsSection(context, isDark),

            SizedBox(height: 14.h),

            // 2. قسم آخر المواضع التي زرتها تحتها
            _buildRecentSection(context, isDark),

            SizedBox(height: 14.h),
          ],
        ),
      ),
    );
  }

  /// قسم عرض آخر 5 مواضع زارها المستخدم
  Widget _buildRecentSection(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF242424) : Colors.grey.shade50;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 15.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 5.w),
                Text(
                  'آخر المواضع التي زرتها',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primary,
                    // fontFamily: 'Amiri',
                  ),
                ),
              ],
            ),
            if (_recentActions.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${_recentActions.length} محطات',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 6.h),
        if (_isLoadingRecent)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_recentActions.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.grey.shade400,
                  size: 14.sp,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'لا توجد محطات مسجلة بعد. عند دخولك للقرآن أو الأذكار أو الأحاديث ستظهر محطاتك هنا.',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.grey.shade500,
                      fontFamily: 'Amiri',
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentActions.length,
            separatorBuilder: (context, index) => SizedBox(height: 6.h),
            itemBuilder: (context, index) {
              final action = _recentActions[index];
              return InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  await RecentActionNavigator.resume(context, action);
                },
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26.w,
                        height: 26.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: isDark ? 0.25 : 0.12,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.goldAccent.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          RecentActionNavigator.getCategoryIcon(
                            action.category,
                          ),
                          color: isDark ? Colors.white : AppColors.primary,
                          size: 13.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  RecentActionNavigator.getCategoryLabel(
                                    action.category,
                                  ),
                                  style: TextStyle(
                                    fontSize: 8.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontFamily: 'Amiri',
                                    height: 1.25,
                                  ),
                                ),
                                if (action.subtitle.isNotEmpty &&
                                    action.subtitle != action.title &&
                                    !action.title.contains(
                                      action.subtitle,
                                    )) ...[
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      '• ${action.subtitle}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 8.sp,
                                        color: Colors.grey.shade500,
                                        fontFamily: 'Amiri',
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              action.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                fontFamily: 'Amiri',
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 10.sp,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  /// قسم عرض تنبيهات اليوم المعلقة
  Widget _buildNotificationsSection(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF242424) : Colors.grey.shade50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  size: 15.sp,
                  color: Colors.orange.shade700,
                ),
                SizedBox(width: 5.w),
                Text(
                  'تنبيهات اليوم الفائتة',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primary,
                    // fontFamily: 'Amiri',
                  ),
                ),
              ],
            ),
            if (widget.notifications.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade700.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${widget.notifications.length} تنبيه',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 6.h),
        if (widget.notifications.isEmpty)
          _buildEmptyState(isDark)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.notifications.length,
            separatorBuilder: (context, index) => SizedBox(height: 6.h),
            itemBuilder: (context, index) {
              final notif = widget.notifications[index];
              return InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  await widget.onNotificationTap(notif);
                },
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                          color: notif.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          notif.icon,
                          color: notif.color,
                          size: 14.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontSize: 9.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontFamily: 'Amiri',
                                    height: 1.25,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'hh:mm a',
                                    'ar',
                                  ).format(notif.triggerTime),
                                  style: TextStyle(
                                    fontSize: 7.5.sp,
                                    color: Colors.grey.shade500,
                                    fontFamily: 'Amiri',
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              notif.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.sp,
                                height: 1.3,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey.shade700,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 10.sp,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.green.shade500.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.done_all_rounded,
              color: Colors.green.shade600,
              size: 18.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'ما شاء الله! يومك مبارك',
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: 'Amiri',
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'لا توجد تنبيهات فائتة اليوم. تقبل الله طاعتك',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8.5.sp,
              color: Colors.grey.shade500,
              fontFamily: 'Amiri',
            ),
          ),
        ],
      ),
    );
  }
}
