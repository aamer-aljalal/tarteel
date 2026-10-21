import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import '../models/habit_category.dart';
import '../models/habit_item.dart';

/// ==============================================================================
/// ورقة تخصيص العبادات (اختيار النوافل والأوراد المناسبة لطاقة المستخدم)
/// ==============================================================================
class HabitCustomizationSheet extends StatefulWidget {
  final List<HabitItem> allHabits;
  final Set<String> initiallyEnabledIds;
  final Function(Set<String>) onSave;

  const HabitCustomizationSheet({
    super.key,
    required this.allHabits,
    required this.initiallyEnabledIds,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required List<HabitItem> allHabits,
    required Set<String> initiallyEnabledIds,
    required Function(Set<String>) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitCustomizationSheet(
        allHabits: allHabits,
        initiallyEnabledIds: initiallyEnabledIds,
        onSave: onSave,
      ),
    );
  }

  @override
  State<HabitCustomizationSheet> createState() =>
      _HabitCustomizationSheetState();
}

class _HabitCustomizationSheetState extends State<HabitCustomizationSheet> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.initiallyEnabledIds);
  }

  void _toggle(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // فصل العبادات حسب التصنيف (الصلوات لا تُعدل لأنها فرائض)
    final sunan = widget.allHabits
        .where((h) => h.category == HabitCategory.sunan)
        .toList();
    final azkarAndQuran = widget.allHabits
        .where((h) => h.category == HabitCategory.azkarAndQuran)
        .toList();
    final special = widget.allHabits
        .where((h) => h.category == HabitCategory.special)
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            // مقبض السحب العلوي
            SizedBox(height: 12.h),
            Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 14.h),

            // العنوان وزر الإغلاق
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تخصيص جدول العبادات',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'اختر النوافل والأوراد التي تود المداومة عليها يومياً',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(
              height: 20.h,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),

            // قائمة الخيارات القابلة للتمرير
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                children: [
                  // إشعار الصلوات المفروضة
                  Container(
                    margin: EdgeInsets.only(bottom: 14.h),
                    padding: EdgeInsets.all(12.w),
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
                          Icons.verified_outlined,
                          size: 18.sp,
                          color: AppColors.primaryLight,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'الصلوات الخمس المفروضة مثبتة دائماً في جدولك كركن أساسي.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // قسم السنن والرواتب
                  _buildSectionHeader('السنن والنوافل', isDark),
                  ...sunan.map((h) => _buildHabitSwitchTile(h, isDark)),

                  SizedBox(height: 12.h),

                  // قسم الأذكار والقرآن
                  _buildSectionHeader('الأذكار والأوراد القرآنية', isDark),
                  ...azkarAndQuran.map((h) => _buildHabitSwitchTile(h, isDark)),

                  SizedBox(height: 12.h),

                  // قسم المناسبات والسنن المؤكدة
                  _buildSectionHeader('المناسبات والسنن المؤكدة', isDark),
                  ...special.map((h) => _buildHabitSwitchTile(h, isDark)),

                  SizedBox(height: 20.h),
                ],
              ),
            ),

            // زر الحفظ في الأسفل
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onSave(_selectedIds);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'حفظ التعديلات والتطبيق',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, top: 4.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.goldAccent,
        ),
      ),
    );
  }

  Widget _buildHabitSwitchTile(HabitItem habit, bool isDark) {
    final isSelected = _selectedIds.contains(habit.id);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: SwitchListTile(
        value: isSelected,
        onChanged: (_) => _toggle(habit.id),
        activeTrackColor: AppColors.primaryLight,
        secondary: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : (isDark ? Colors.white10 : Colors.black12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            habit.icon,
            size: 18.sp,
            color: isSelected
                ? AppColors.primaryLight
                : (isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText),
          ),
        ),
        title: Text(
          habit.title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.darkPrimaryText
                : AppColors.lightPrimaryText,
          ),
        ),
        subtitle: Text(
          habit.subtitle,
          style: TextStyle(
            fontSize: 11.sp,
            color: isDark
                ? AppColors.darkSecondaryText
                : AppColors.lightSecondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
