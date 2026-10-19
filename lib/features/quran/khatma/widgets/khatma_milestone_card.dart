import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import '../models/khatma_badge_model.dart';
import 'khatma_share_card.dart';

class KhatmaMilestonesSection extends StatelessWidget {
  final List<KhatmaBadgeModel> badges;
  final int currentPage;
  final int streakDays;

  const KhatmaMilestonesSection({
    super.key,
    required this.badges,
    required this.currentPage,
    this.streakDays = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.military_tech_rounded,
                  color: const Color(0xFFE2B755),
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'المحطات والأوسمة القرآنية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${badges.where((b) => b.isUnlocked).length} / ${badges.length} أوسمة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFC5953C),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Milestones list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            final badge = badges[index];
            return _buildMilestoneTile(context, badge, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildMilestoneTile(
    BuildContext context,
    KhatmaBadgeModel badge,
    bool isDark,
  ) {
    const accentGold = Color(0xFFE2B755);
    final isUnlocked = badge.isUnlocked;

    final cardBg = isDark
        ? (isUnlocked
            ? const Color(0xFF13382B)
            : const Color(0xFF161E1B))
        : (isUnlocked
            ? const Color(0xFFF3F9F6)
            : const Color(0xFFF8F9FA));

    final borderColor = isUnlocked
        ? accentGold.withValues(alpha: 0.45)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08));

    final pagesRemaining = (badge.targetPage - currentPage).clamp(0, 604);
    final progress = (currentPage / badge.targetPage).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor, width: isUnlocked ? 1.4.w : 1.w),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: accentGold.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: isUnlocked
              ? () => KhatmaShareCardDialog.show(
                    context,
                    badge: badge,
                    totalPages: 604,
                    streakDays: streakDays,
                  )
              : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isUnlocked
                        ? const LinearGradient(
                            colors: [Color(0xFFE2B755), Color(0xFF9E7728)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUnlocked
                        ? null
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    badge.icon,
                    size: 22.sp,
                    color: isUnlocked
                        ? Colors.white
                        : (isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
                SizedBox(width: 12.w),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              badge.title,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? (isDark
                                        ? AppColors.darkPrimaryText
                                        : AppColors.lightPrimaryText)
                                    : (isDark ? Colors.white54 : Colors.black54),
                              ),
                            ),
                          ),
                          if (isUnlocked)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: accentGold.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: accentGold.withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'تم الإنجاز',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: accentGold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        badge.subtitle,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                      SizedBox(height: 6.h),

                      // Progress or Unlocked Action
                      if (isUnlocked)
                        Row(
                          children: [
                            Icon(
                              Icons.visibility_rounded,
                              size: 13.sp,
                              color: accentGold,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'اضغط لعرض وتحميل بطاقة التهنئة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: accentGold,
                              ),
                            ),
                            if (badge.unlockedAt != null) ...[
                              const Spacer(),
                              Text(
                                DateFormat('yyyy/MM/dd').format(badge.unlockedAt!),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10.sp,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ],
                        )
                      else ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5.h,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF227E67),
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'متبقي $pagesRemaining صفحة للوصول',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10.sp,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 12.sp,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
