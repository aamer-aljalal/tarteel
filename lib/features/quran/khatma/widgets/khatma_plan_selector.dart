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
        // Intro Banner
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F3A2E), const Color(0xFF175241)]
                  : [const Color(0xFF144D3E), const Color(0xFF227E67)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: accentGold.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: accentGold,
                    size: 22.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'اختر مسار ختمتك المناسب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                'اختر الطريقة التي تلائم وقتك وروتينك اليومي لبناء ورد قرآني مستمر ومتدرج، ونحن نرافقك بالمتابعة والأوسمة.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.sp,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18.h),

        // Section Title: Select Path
        Text(
          'مسارات الختمة المتاحة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleMedium?.color,
          ),
        ),
        SizedBox(height: 10.h),

        // 4 Path Cards
        _buildPlanTypeOption(
          type: KhatmaPlanType.prayers,
          title: 'مسار الصلوات الخمس',
          subtitle: 'قراءة ورد يسير في رحاب كل صلاة مكتوبة',
          icon: Icons.access_time_filled_rounded,
          isDark: isDark,
        ),
        SizedBox(height: 8.h),
        _buildPlanTypeOption(
          type: KhatmaPlanType.dailyPages,
          title: 'مسار الورد اليومي الثابت',
          subtitle: 'تحديد عدد الصفحات التي ترغب بقراءتها كل يوم',
          icon: Icons.menu_book_rounded,
          isDark: isDark,
        ),
        SizedBox(height: 8.h),
        _buildPlanTypeOption(
          type: KhatmaPlanType.durationDays,
          title: 'مسار المدة المحددة بالأيام',
          subtitle: 'تحديد مدة زمنية لختم المصحف (مثل 30 يوماً)',
          icon: Icons.calendar_month_rounded,
          isDark: isDark,
        ),
        SizedBox(height: 8.h),
        _buildPlanTypeOption(
          type: KhatmaPlanType.freeReading,
          title: 'مسار القراءة الحرة',
          subtitle: 'قراءة ميسرة بدون قيود زمنية مع تسجيل الإنجازات',
          icon: Icons.emoji_events_rounded,
          isDark: isDark,
        ),
        SizedBox(height: 16.h),

        // Dynamic Configuration Settings based on chosen plan
        _buildConfigurationBox(isDark),
        SizedBox(height: 16.h),

        // Khatma Title & Reminder Settings Card
        _buildSettingsCard(isDark),
        SizedBox(height: 22.h),

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

  Widget _buildPlanTypeOption({
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
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.6.w : 1.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
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
                size: 20.sp,
                color: isSelected
                    ? accentGold
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.primary)
                          : null,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.sp,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? accentGold : Colors.grey,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationBox(bool isDark) {
    const accentGold = Color(0xFFE2B755);
    final cardBg = isDark ? const Color(0xFF16241E) : const Color(0xFFF7FAF8);

    if (_selectedType == KhatmaPlanType.prayers) {
      final totalPerDay = _pagesPerPrayer * 5;
      final days = (604 / totalPerDay).ceil();

      return Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: accentGold.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'عدد الصفحات بعد كل صلاة:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$_pagesPerPrayer صفحات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: accentGold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [2, 4, 6, 8].map((val) {
                final isCurrent = _pagesPerPrayer == val;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: ChoiceChip(
                    label: Text(
                      '$val صفحات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? Colors.white : null,
                      ),
                    ),
                    selected: isCurrent,
                    selectedColor: AppColors.primary,
                    onSelected: (_) => setState(() => _pagesPerPrayer = val),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10.h),
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
                      'المعدل: $totalPerDay صفحة يومياً • إتمام المصحف خلال $days يوماً بإذن الله',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.sp,
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
    } else if (_selectedType == KhatmaPlanType.dailyPages) {
      final days = (604 / _dailyPages).ceil();
      return Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: accentGold.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'عدد الصفحات اليومية:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$_dailyPages صفحة / يوم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: accentGold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              children: [5, 10, 20, 30, 40].map((val) {
                final isCurrent = _dailyPages == val;
                return ChoiceChip(
                  label: Text(
                    '$val ص',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? Colors.white : null,
                    ),
                  ),
                  selected: isCurrent,
                  selectedColor: AppColors.primary,
                  onSelected: (_) => setState(() => _dailyPages = val),
                );
              }).toList(),
            ),
            SizedBox(height: 10.h),
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
                      'ستتم الختمة المباركة بإذن الله خلال $days يوماً',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.sp,
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
    } else if (_selectedType == KhatmaPlanType.durationDays) {
      final pagesPerDay = (604 / _targetDays).ceil();
      return Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: accentGold.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المدة المستهدفة بالأيام:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$_targetDays يوماً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: accentGold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              children: [15, 30, 60, 90].map((val) {
                final isCurrent = _targetDays == val;
                return ChoiceChip(
                  label: Text(
                    '$val يوم',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? Colors.white : null,
                    ),
                  ),
                  selected: isCurrent,
                  selectedColor: AppColors.primary,
                  onSelected: (_) => setState(() => _targetDays = val),
                );
              }).toList(),
            ),
            SizedBox(height: 10.h),
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
                      'المطلوب قراءة $pagesPerDay صفحة يومياً لإتمام الختمة في الموعد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.sp,
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
    } else {
      // Free Reading
      return Container(
        padding: EdgeInsets.all(12.w),
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
                'مسار مفتوح بدون ضغوط، تقدم حسب استطاعتك وتتبع صفحاتك وأوسمتك وسلسلة التزامك.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.sp,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSettingsCard(bool isDark) {
    const accentGold = Color(0xFFE2B755);
    final cardBg = isDark ? const Color(0xFF161F1C) : Colors.white;

    final hour = _reminderTime.hourOfPeriod == 0
        ? 12
        : _reminderTime.hourOfPeriod;
    final period = _reminderTime.period == DayPeriod.am ? 'صباحاً' : 'مساءً';
    final minuteStr = _reminderTime.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$minuteStr $period';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Name Field
          Text(
            'عنوان الخطة:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: _titleController,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              hintText: 'مثلاً: ختمة القرآن الكريم',
            ),
          ),
          SizedBox(height: 14.h),

          // Daily Reminder Picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: accentGold,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'التذكير اليومي:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _pickReminderTime,
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: accentGold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: accentGold,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Icon(Icons.edit_outlined, size: 14.sp, color: accentGold),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
