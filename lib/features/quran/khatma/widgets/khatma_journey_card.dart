import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/khatma_plan_model.dart';

class KhatmaJourneyCard extends StatelessWidget {
  final KhatmaPlanModel plan;
  final int streakDays;
  final VoidCallback onContinueReading;
  final VoidCallback onChangeReminder;
  final VoidCallback onCancelPlan;

  const KhatmaJourneyCard({
    super.key,
    required this.plan,
    required this.streakDays,
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
          color: accentGold.withValues(alpha: 0.35),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: emeraldDeep.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
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
                  ],
                ),
              ),
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
            width: 140.w,
            height: 140.w,
            child: CustomPaint(
              painter: _RadialProgressPainter(
                progress: progress,
                trackColor: Colors.white.withValues(alpha: 0.1),
                progressColor: accentGold,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'الصفحة ${plan.currentPage} من 604',
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
          SizedBox(height: 20.h),

          // 3 Metric Cards
          Row(
            children: [
              // 1. Streak
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.whatshot_rounded,
                  iconColor: const Color(0xFFFF9800),
                  title: 'سلسلة الالتزام',
                  value: streakDays > 0 ? '$streakDays يوم' : 'ابدأ اليوم',
                ),
              ),
              SizedBox(width: 8.w),

              // 2. Today's Reading
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  title: 'إنجاز اليوم',
                  value: plan.type == KhatmaPlanType.freeReading
                      ? '${plan.pagesReadToday} ص'
                      : '${plan.pagesReadToday} / ${plan.targetPagesPerDay} ص',
                ),
              ),
              SizedBox(width: 8.w),

              // 3. Remaining
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.flag_rounded,
                  iconColor: accentGold,
                  title: 'المتبقي',
                  value: plan.type == KhatmaPlanType.freeReading
                      ? '${plan.remainingPages} ص'
                      : '${plan.daysRemaining} يوم',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Continue Reading Action Button
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
