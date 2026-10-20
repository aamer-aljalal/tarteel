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
  final VoidCallback? onReturnToActive;
  final VoidCallback onContinueReading;
  final VoidCallback onChangeReminder;
  final VoidCallback onCancelPlan;

  const KhatmaJourneyCard({
    super.key,
    required this.plan,
    required this.streakDays,
    this.isArchivedPreview = false,
    this.onReturnToActive,
    required this.onContinueReading,
    required this.onChangeReminder,
    required this.onCancelPlan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final emeraldDeep =
        isDark ? const Color(0xFF0A2B20) : const Color(0xFF0E3D2F);
    final emeraldLight =
        isDark ? const Color(0xFF144D3A) : const Color(0xFF1B634E);
    const accentGold = Color(0xFFE2B755);

    String planTypeName;
    switch (plan.type) {
      case KhatmaPlanType.prayers:
        planTypeName = 'مسار الصلوات الخمس';
        break;
      case KhatmaPlanType.dailyPages:
        planTypeName = 'مسار الورد اليومي';
        break;
      case KhatmaPlanType.durationDays:
        planTypeName = 'مسار المدة المحددة';
        break;
      case KhatmaPlanType.freeReading:
        planTypeName = 'مسار القراءة الحرة';
        break;
    }

    final progress = plan.progressPercentage;

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
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Banner if viewing archived past Khatma
          if (isArchivedPreview) ...[
            Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: accentGold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: accentGold.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history_edu_rounded,
                        color: accentGold,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'عرض بيانات ختمة سابقة أُنجزت',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (onReturnToActive != null)
                    InkWell(
                      onTap: onReturnToActive,
                      borderRadius: BorderRadius.circular(6.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'العودة للحالية',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Header: Plan Title + Type Chip + Options Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: accentGold.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            planTypeName,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: accentGold,
                            ),
                          ),
                        ),
                        if (isArchivedPreview && plan.completedDate != null) ...[
                          SizedBox(width: 8.w),
                          Text(
                            DateFormat('yyyy/MM/dd').format(plan.completedDate!),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10.sp,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
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

          // Circular Radial Progress Indicator
          SizedBox(
            width: 135.w,
            height: 135.w,
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
                    Text(
                      isArchivedPreview
                          ? '100%'
                          : '${(progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isArchivedPreview
                          ? 'أُتمت 604 صفحة'
                          : 'الصفحة ${plan.currentPage} من 604',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 18.h),

          // 3 Metric Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: isArchivedPreview
                      ? Icons.check_circle_outline_rounded
                      : Icons.whatshot_rounded,
                  iconColor: isArchivedPreview
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF9800),
                  title: isArchivedPreview ? 'حالة الختمة' : 'سلسلة الالتزام',
                  value: isArchivedPreview
                      ? 'مكتملة'
                      : (streakDays > 0 ? '$streakDays يوم' : 'ابدأ اليوم'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  title: isArchivedPreview ? 'إجمالي الصفحات' : 'إنجاز اليوم',
                  value: isArchivedPreview
                      ? '604 صفحة'
                      : (plan.type == KhatmaPlanType.freeReading
                          ? '${plan.pagesReadToday} ص'
                          : '${plan.pagesReadToday} / ${plan.targetPagesPerDay} ص'),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.flag_rounded,
                  iconColor: accentGold,
                  title: isArchivedPreview ? 'المدة المستغرقة' : 'المتبقي',
                  value: isArchivedPreview
                      ? '${plan.targetDays} يوماً'
                      : (plan.type == KhatmaPlanType.freeReading
                          ? '${plan.remainingPages} ص'
                          : '${plan.daysRemaining} يوم'),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // ==========================================
          // 4 Square Milestones (الأوسمة الأربعة المربعة داخل البطاقة)
          // ==========================================
          _buildSquareMilestonesRow(context),
          SizedBox(height: 18.h),

          // Bottom Action Button
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
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 20.sp,
                ),
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
              'أوسمة ومحطات هذه الختمة',
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
        SizedBox(height: 10.h),
        Row(
          children: badges.map((badge) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.5.w),
                child: _buildSquareMilestoneTile(context, badge),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSquareMilestoneTile(BuildContext context, KhatmaBadgeModel badge) {
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
            final remaining = (badge.targetPage - plan.currentPage).clamp(0, 604);
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
              // Icon with status badge
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

              // Title
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

              // Page target
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

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18.sp),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 9.sp,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
    const strokeWidth = 10.0;

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
        colors: [
          progressColor.withValues(alpha: 0.6),
          progressColor,
        ],
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
