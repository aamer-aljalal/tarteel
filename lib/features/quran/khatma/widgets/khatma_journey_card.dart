import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../models/khatma_plan_model.dart';
import '../models/khatma_badge_model.dart';
import 'khatma_share_card.dart';

class KhatmaJourneyCard extends StatelessWidget {
  final KhatmaPlanModel plan;
  final int streakDays;
  final bool isArchivedPreview;
  final VoidCallback onContinueReading;
  final VoidCallback onChangeReminder;
  final VoidCallback onCancelPlan;

  const KhatmaJourneyCard({
    super.key,
    required this.plan,
    required this.streakDays,
    this.isArchivedPreview = false,
    required this.onContinueReading,
    required this.onChangeReminder,
    required this.onCancelPlan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final emeraldDeep = isDark
        ? const Color(0xFF0A2B20)
        : const Color(0xFF0E3D2F);
    final emeraldLight = isDark
        ? const Color(0xFF144D3A)
        : const Color(0xFF1B634E);
    const accentGold = Color(0xFFE2B755);

    final progress = plan.progressPercentage;
    final isCompleted = isArchivedPreview || plan.isCompleted;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [emeraldDeep, emeraldLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: accentGold.withValues(alpha: isArchivedPreview ? 0.6 : 0.35),
          width: 1.4.w,
        ),
        boxShadow: [
          BoxShadow(
            color: emeraldDeep.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      child: Column(
        children: [
          // Header: Plan Title (Right) & Options Menu (Left)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isArchivedPreview)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white70,
                    size: 22.sp,
                  ),
                  color: isDark ? const Color(0xFF182923) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  onSelected: (value) {
                    if (value == 'reminder') {
                      onChangeReminder();
                    } else if (value == 'cancel') {
                      onCancelPlan();
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'reminder',
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 18.sp,
                            color: accentGold,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'تعديل موعد التذكير',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            size: 18.sp,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'إنهاء الخطة الحالية',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.sp,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // ========================================================
          // Center Section: Circular Indicator flanked by 4 corner tiles
          // ========================================================
          _buildFlankedCircleSection(
            progress: progress,
            isCompleted: isCompleted,
            accentGold: accentGold,
          ),
          SizedBox(height: 18.h),

          // ========================================================
          // 4 Square Milestones (الأوسمة الأربعة المربعة)
          // ========================================================
          _buildSquareMilestonesRow(context),
          SizedBox(height: 16.h),

          // ========================================================
          // Bottom Action Button
          // ========================================================
          if (isArchivedPreview) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final badges = plan.badges.isNotEmpty
                      ? plan.badges
                      : KhatmaBadgeModel.defaultBadges();
                  final completeBadge = badges.firstWhere(
                    (b) => b.milestoneType == MilestoneType.complete,
                    orElse: () => badges.last,
                  );
                  KhatmaShareCardDialog.show(
                    context,
                    badge: completeBadge,
                    totalPages: 604,
                    streakDays: streakDays,
                  );
                },
                icon: Icon(Icons.workspace_premium_rounded, size: 20.sp),
                label: Text(
                  'عرض شهادة ختم المصحف',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5953C),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onContinueReading,
                icon: Icon(Icons.arrow_back_rounded, size: 20.sp),
                label: Text(
                  'متابعة القراءة من صفحة ${plan.currentPage}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5953C),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// دائرة نسبة الإنجاز محاطة بالبطاقات الأربعة في الزوايا
  Widget _buildFlankedCircleSection({
    required double progress,
    required bool isCompleted,
    required Color accentGold,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // العمود الأيمن (الزاويتان اليمينيتان: أعلى اليمين وأسفل اليمين)
        Expanded(
          child: SizedBox(
            height: 126.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isArchivedPreview) ...[
                  _buildCornerTile(
                    icon: Icons.calendar_month_outlined,
                    iconColor: const Color(0xFF38BDF8),
                    title: 'تاريخ البدء',
                    value: DateFormat('yyyy/MM/dd').format(plan.startDate),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.16),
                      thickness: 0.8,
                      height: 1,
                    ),
                  ),
                  _buildCornerTile(
                    icon: Icons.timer_outlined,
                    iconColor: accentGold,
                    title: 'المدة',
                    value: '${plan.targetDays} يوماً',
                  ),
                ] else ...[
                  _buildCornerTile(
                    icon: Icons.whatshot_rounded,
                    iconColor: const Color(0xFFFF9800),
                    title: 'الالتزام',
                    value: streakDays > 0 ? '$streakDays يوم' : 'ابدأ اليوم',
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.16),
                      thickness: 0.8,
                      height: 1,
                    ),
                  ),
                  _buildCornerTile(
                    icon: Icons.menu_book_rounded,
                    iconColor: const Color(0xFF4ADE80),
                    title: 'ورد اليوم',
                    value: plan.type == KhatmaPlanType.freeReading
                        ? '${plan.pagesReadToday} ص'
                        : '${plan.pagesReadToday} / ${plan.targetPagesPerDay} ص',
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: 6.w),

        // الدائرة المركزية (مع عرض الحالة: مكتمل بلون أخضر أو مستمر بلون أصفر)
        SizedBox(
          width: 126.w,
          height: 126.w,
          child: CustomPaint(
            painter: _RadialProgressPainter(
              progress: isArchivedPreview ? 1.0 : progress,
              trackColor: Colors.white.withValues(alpha: 0.1),
              progressColor: accentGold,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // حالة الختمة أعلى النسبة مباشرة
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 7.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF22C55E).withValues(alpha: 0.22)
                          : const Color(0xFFEAB308).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFFFACC15),
                        width: 0.9,
                      ),
                    ),
                    child: Text(
                      isCompleted ? 'مكتمل' : 'مستمر',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFFFACC15),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // النسبة المئوية
                  Text(
                    isArchivedPreview
                        ? '100%'
                        : '${(progress * 100).toStringAsFixed(progress == 1.0 ? 0 : 1)}%',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  // إجمالي الصفحات أو الصفحة الحالية
                  Text(
                    isArchivedPreview || isCompleted
                        ? 'أُتمت 604 صفحة'
                        : 'ص ${plan.currentPage} من 604',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9.sp,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 6.w),

        // العمود الأيسر (الزاويتان اليساريتان: أعلى اليسار وأسفل اليسار)
        Expanded(
          child: SizedBox(
            height: 126.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isArchivedPreview) ...[
                  _buildCornerTile(
                    icon: Icons.event_available_rounded,
                    iconColor: const Color(0xFF4ADE80),
                    title: 'تاريخ الختم',
                    value: DateFormat(
                      'yyyy/MM/dd',
                    ).format(plan.completedDate ?? DateTime.now()),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.16),
                      thickness: 0.8,
                      height: 1,
                    ),
                  ),
                  _buildCornerTile(
                    icon: Icons.alt_route_rounded,
                    iconColor: const Color(0xFFFFB74D),
                    title: 'المسار',
                    value: _getShortPlanType(plan.type),
                  ),
                ] else ...[
                  _buildCornerTile(
                    icon: Icons.flag_rounded,
                    iconColor: accentGold,
                    title: 'المتبقي',
                    value: plan.type == KhatmaPlanType.freeReading
                        ? '${plan.remainingPages} ص'
                        : '${plan.daysRemaining} يوم',
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.16),
                      thickness: 0.8,
                      height: 1,
                    ),
                  ),
                  _buildCornerTile(
                    icon: Icons.alt_route_rounded,
                    iconColor: const Color(0xFFFFB74D),
                    title: 'المسار',
                    value: _getShortPlanType(plan.type),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getShortPlanType(KhatmaPlanType type) {
    switch (type) {
      case KhatmaPlanType.prayers:
        return 'صلوات خمس';
      case KhatmaPlanType.dailyPages:
        return 'ورد يومي';
      case KhatmaPlanType.durationDays:
        return 'مدة محددة';
      case KhatmaPlanType.freeReading:
        return 'قراءة حرة';
    }
  }

  Widget _buildCornerTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 12.sp),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 11.sp,
                    color: Colors.white70,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 12.5.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSquareMilestonesRow(BuildContext context) {
    const accentGold = Color(0xFFE2B755);
    final badges = plan.badges.isNotEmpty
        ? plan.badges
        : KhatmaBadgeModel.defaultBadges();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الأوسمة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            Text(
              '${badges.where((b) => b.isUnlocked).length} / 4 مكتملة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: accentGold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: badges.map((badge) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: _buildSquareMilestoneTile(context, badge),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSquareMilestoneTile(
    BuildContext context,
    KhatmaBadgeModel badge,
  ) {
    const accentGold = Color(0xFFE2B755);
    final isUnlocked = badge.isUnlocked;

    String shortLabel;
    switch (badge.milestoneType) {
      case MilestoneType.quarter:
        shortLabel = 'الربع';
        break;
      case MilestoneType.half:
        shortLabel = 'النصف';
        break;
      case MilestoneType.threeQuarters:
        shortLabel = '3 أرباع';
        break;
      case MilestoneType.complete:
        shortLabel = 'الختام';
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: () {
          if (isUnlocked) {
            KhatmaShareCardDialog.show(
              context,
              badge: badge,
              totalPages: 604,
              streakDays: streakDays,
            );
          } else {
            final remaining = (badge.targetPage - plan.currentPage).clamp(
              0,
              604,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'يُفتح هذا الوسام عند بلوغ صفحة ${badge.targetPage} (متبقي $remaining صفحة)',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
          decoration: BoxDecoration(
            color: isUnlocked
                ? accentGold.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isUnlocked
                  ? accentGold.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.14),
              width: isUnlocked ? 1.4.w : 1.w,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: accentGold.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUnlocked
                          ? accentGold.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      badge.icon,
                      size: 16.sp,
                      color: isUnlocked ? accentGold : Colors.white38,
                    ),
                  ),
                  if (isUnlocked)
                    Positioned(
                      top: -2.h,
                      right: -2.w,
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F3A2E),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 11.sp,
                          color: accentGold,
                        ),
                      ),
                    )
                  else
                    Positioned(
                      top: -2.h,
                      right: -2.w,
                      child: Icon(
                        Icons.lock_rounded,
                        size: 10.sp,
                        color: Colors.white24,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 5.h),
              Text(
                shortLabel,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.white : Colors.white60,
                ),
                maxLines: 1,
              ),
              Text(
                'ص ${badge.targetPage}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 9.sp,
                  color: isUnlocked ? accentGold : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadialProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  const _RadialProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12.0) / 2;
    const strokeWidth = 9.0;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Foreground progress
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [progressColor.withValues(alpha: 0.6), progressColor],
        startAngle: 0.0,
        endAngle: math.pi * 2,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (progress.clamp(0.0, 1.0)) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
