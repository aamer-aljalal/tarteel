import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import '../models/khatma_plan_model.dart';

class KhatmaPlanSelector extends StatefulWidget {
  final Future<void> Function({
    required String title,
    required KhatmaPlanType type,
    required int targetPagesPerDay,
    required int targetDays,
    required TimeOfDay reminderTime,
  })
  onStartPlan;

  const KhatmaPlanSelector({super.key, required this.onStartPlan});

  @override
  State<KhatmaPlanSelector> createState() => _KhatmaPlanSelectorState();
}

class _KhatmaPlanSelectorState extends State<KhatmaPlanSelector> {
  KhatmaPlanType _selectedType = KhatmaPlanType.prayers;
  final TextEditingController _titleController = TextEditingController(
    text: 'ختمة القرآن الكريم',
  );
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  // Configuration values
  int _pagesPerPrayer = 4; // for prayers mode (4 * 5 = 20 pages/day)
  int _dailyPages = 20; // for dailyPages mode
  int _targetDays = 30; // for durationDays mode

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  void _showPrayersInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.mosque_rounded,
                color: const Color(0xFFC5953C),
                size: 22.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'تنبيهات الصلوات الخمس',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'في هذا المسار، يتم تذكيرك تلقائياً بقراءة وردك في رحاب كل صلاة مكتوبة (الفجر، الظهر، العصر، المغرب، العشاء) بعد انقضاء وقت الصلاة بـ 15 دقيقة، استناداً إلى مواقيت الصلاة الدقيقة لموقعك.',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5.sp,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'فهمت ذلك',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFC5953C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    setState(() => _isSubmitting = true);
    try {
      int pagesPerDay = 20;
      int days = 30;

      switch (_selectedType) {
        case KhatmaPlanType.prayers:
          pagesPerDay = _pagesPerPrayer * 5;
          days = (604 / pagesPerDay).ceil();
          break;
        case KhatmaPlanType.dailyPages:
          pagesPerDay = _dailyPages;
          days = (604 / pagesPerDay).ceil();
          break;
        case KhatmaPlanType.durationDays:
          days = _targetDays;
          pagesPerDay = (604 / days).ceil();
          break;
        case KhatmaPlanType.freeReading:
          pagesPerDay = 10;
          days = 60;
          break;
      }

      await widget.onStartPlan(
        title: _titleController.text.trim().isEmpty
            ? 'ختمة القرآن الكريم'
            : _titleController.text.trim(),
        type: _selectedType,
        targetPagesPerDay: pagesPerDay,
        targetDays: days,
        reminderTime: _reminderTime,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const accentGold = Color(0xFFE2B755);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // حقل عنوان الخطة + زر التذكير بجانبه في نفس الصف
        _buildTitleAndReminderRow(
          theme: theme,
          isDark: isDark,
          accentGold: accentGold,
        ),
        SizedBox(height: 18.h),

        // Section Title: Select Path
        Text(
          'مسارات الختمة المتاحة',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleMedium?.color,
          ),
        ),
        SizedBox(height: 10.h),

        // 4 Path Cards in 2x2 Grid
        Row(
          children: [
            Expanded(
              child: _buildPlanTypeGridOption(
                type: KhatmaPlanType.prayers,
                title: 'مسار الصلوات الخمس',
                subtitle: 'ورد في رحاب كل صلاة',
                icon: Icons.access_time_filled_rounded,
                isDark: isDark,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildPlanTypeGridOption(
                type: KhatmaPlanType.dailyPages,
                title: 'مسار الورد اليومي',
                subtitle: 'تحديد صفحات يومية',
                icon: Icons.menu_book_rounded,
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildPlanTypeGridOption(
                type: KhatmaPlanType.durationDays,
                title: 'المدة بالأيام',
                subtitle: 'مدة محددة للختم',
                icon: Icons.calendar_month_rounded,
                isDark: isDark,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildPlanTypeGridOption(
                type: KhatmaPlanType.freeReading,
                title: 'القراءة الحرة',
                subtitle: 'قراءة ميسرة بلا قيود',
                icon: Icons.workspace_premium_rounded,
                isDark: isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Dynamic Configuration Settings based on chosen plan
        _buildConfigurationBox(isDark),
        SizedBox(height: 20.h),

        // Submit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.check_circle_outline_rounded, size: 20.sp),
            label: Text(
              'بدء مسار الختمة المباركة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5953C),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanTypeGridOption({
    required KhatmaPlanType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedType == type;
    const accentGold = Color(0xFFE2B755);

    final cardBg = isDark
        ? (isSelected ? const Color(0xFF143B2E) : const Color(0xFF161F1C))
        : (isSelected ? const Color(0xFFF3F9F6) : Colors.white);

    final borderColor = isSelected
        ? accentGold
        : (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08));

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.6.w : 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? accentGold.withValues(alpha: 0.2)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04)),
                  ),
                  child: Icon(
                    icon,
                    size: 18.sp,
                    color: isSelected
                        ? accentGold
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected ? accentGold : Colors.grey,
                  size: 18.sp,
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.primary)
                    : null,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 9.sp,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// دالة عامة موحدة وقابلة لإعادة الاستخدام لبطاقة إعدادات المسار السفلية
  Widget _buildConfigCard({
    required bool isDark,
    required Color accentGold,
    String? title,
    String? valueText,
    List<int>? options,
    int? selectedOption,
    String unit = '',
    double chipFontSize = 9.0,
    double chipSpacing = 6.0,
    ValueChanged<int>? onOptionSelected,
    String? infoText,
    double? infoFontSize,
    String? freeReadingText,
  }) {
    final cardBg = isDark ? const Color(0xFF16241E) : const Color(0xFFF7FAF8);

    if (freeReadingText != null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: accentGold.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: accentGold,
              size: 18.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                freeReadingText,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: accentGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || valueText != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null)
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (valueText != null)
                  Text(
                    valueText,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: accentGold,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
          ],
          if (options != null && options.isNotEmpty) ...[
            Wrap(
              spacing: chipSpacing.w,
              children: options.map((val) {
                final isCurrent = selectedOption == val;
                return ChoiceChip(
                  label: Text(
                    '$val $unit',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: chipFontSize.sp,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? Colors.white : null,
                    ),
                  ),
                  selected: isCurrent,
                  selectedColor: AppColors.primary,
                  onSelected: onOptionSelected != null
                      ? (_) => onOptionSelected(val)
                      : null,
                );
              }).toList(),
            ),
            SizedBox(height: 10.h),
          ],
          if (infoText != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: accentGold,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      infoText,
                      style: TextStyle(
                        fontSize: (infoFontSize ?? 10.sp),
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfigurationBox(bool isDark) {
    const accentGold = Color(0xFFE2B755);

    switch (_selectedType) {
      case KhatmaPlanType.prayers:
        final totalPerDay = _pagesPerPrayer * 5;
        final days = (604 / totalPerDay).ceil();
        return _buildConfigCard(
          isDark: isDark,
          accentGold: accentGold,
          title: 'عدد الصفحات بعد كل صلاة:',
          valueText: '$_pagesPerPrayer صفحات',
          options: const [2, 4, 6, 8],
          selectedOption: _pagesPerPrayer,
          unit: 'ص',
          chipSpacing: 8,
          onOptionSelected: (val) => setState(() => _pagesPerPrayer = val),
          infoText:
              'المعدل: $totalPerDay صفحة يومياً • إتمام المصحف خلال $days يوماً بإذن الله',
          infoFontSize: 10.sp,
        );

      case KhatmaPlanType.dailyPages:
        final days = (604 / _dailyPages).ceil();
        return _buildConfigCard(
          isDark: isDark,
          accentGold: accentGold,
          title: 'عدد الصفحات اليومية:',
          valueText: '$_dailyPages صفحة / يوم',
          options: const [5, 10, 20, 30, 40],
          selectedOption: _dailyPages,
          unit: 'ص',
          onOptionSelected: (val) => setState(() => _dailyPages = val),
          infoText: 'ستتم الختمة المباركة بإذن الله خلال $days يوماً',
          infoFontSize: 11.sp,
        );

      case KhatmaPlanType.durationDays:
        final pagesPerDay = (604 / _targetDays).ceil();
        return _buildConfigCard(
          isDark: isDark,
          accentGold: accentGold,
          title: 'المدة المستهدفة بالأيام:',
          valueText: '$_targetDays يوماً',
          options: const [15, 30, 60, 90],
          selectedOption: _targetDays,
          unit: 'يوم',
          chipFontSize: 10,
          onOptionSelected: (val) => setState(() => _targetDays = val),
          infoText:
              'المطلوب قراءة $pagesPerDay صفحة يومياً لإتمام الختمة في الموعد',
          infoFontSize: 10.sp,
        );

      case KhatmaPlanType.freeReading:
        return _buildConfigCard(
          isDark: isDark,
          accentGold: accentGold,
          freeReadingText:
              'مسار مفتوح بدون ضغوط، تقدم حسب استطاعتك وتتبع صفحاتك وأوسمتك وسلسلة التزامك.',
        );
    }
  }

  Widget _buildTitleAndReminderRow({
    required ThemeData theme,
    required bool isDark,
    required Color accentGold,
  }) {
    final isPrayers = _selectedType == KhatmaPlanType.prayers;

    final hour = _reminderTime.hourOfPeriod == 0
        ? 12
        : _reminderTime.hourOfPeriod;
    final period = _reminderTime.period == DayPeriod.am ? 'صباحاً' : 'مساءً';
    final minuteStr = _reminderTime.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$minuteStr $period';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16241E) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // حقل عنوان الخطة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 17.sp,
                      color: accentGold,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'عنوان الخطة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: _titleController,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4.h),
                    border: InputBorder.none,
                    hintText: 'ختمة القرآن الكريم',
                    hintStyle: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14.sp,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // فاصل رأسي
          Container(
            height: 40.h,
            width: 1.w,
            margin: EdgeInsets.symmetric(horizontal: 10.w),
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
          ),

          // زر التذكير اليومي أو تنبيه الصلوات الخمس
          InkWell(
            onTap: isPrayers ? _showPrayersInfoDialog : _pickReminderTime,
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: accentGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: accentGold.withValues(alpha: 0.35),
                  width: 1.w,
                ),
              ),
              child: isPrayers
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mosque_rounded,
                          size: 18.sp,
                          color: accentGold,
                        ),
                        SizedBox(width: 6.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'مع كل صلاة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: accentGold,
                              ),
                            ),
                            Text(
                              'تنبيه بالمواقيت',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9.sp,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.info_outline_rounded,
                          size: 13.sp,
                          color: accentGold,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          size: 18.sp,
                          color: accentGold,
                        ),
                        SizedBox(width: 6.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'تذكير يومي',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9.sp,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                            ),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.bold,
                                color: accentGold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.edit_outlined,
                          size: 13.sp,
                          color: accentGold,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
