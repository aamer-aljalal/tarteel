import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        // 1. عنوان القسم: مسارات الختمة المتاحة بأسلوب راقٍ ومضغوط
        Row(
          children: [
            Container(
              width: 3.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: accentGold,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              'مسارات الختمة المتاحة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 7.h),

        // 2. بطاقات المسارات الـ 4 في شبكة 2x2
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
            SizedBox(width: 7.w),
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
        SizedBox(height: 6.h),
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
            SizedBox(width: 7.w),
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
        SizedBox(height: 9.h),

        // 3. البطاقة الموحدة لإعدادات الخطة وتخصيصها
        _buildCustomizationCard(
          theme: theme,
          isDark: isDark,
          accentGold: accentGold,
        ),
        SizedBox(height: 10.h),

        // 4. زر بدء المسار المتقن والمتناسق
        SizedBox(
          width: double.infinity,
          height: 42.h,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.check_circle_outline_rounded, size: 17.sp),
            label: Text(
              'بدء مسار الختمة المباركة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.5.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5953C),
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              elevation: 1.5,
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
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.4.w : 0.8.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
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
                  width: 25.w,
                  height: 25.w,
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
                    size: 14.sp,
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
                  size: 15.sp,
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 9.5.sp,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.primary)
                    : null,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 8.sp,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// البطاقة الشاملة لإعدادات وتخصيص الخطة (العنوان، التذكير، والتحكم بمسار الخطة)
  Widget _buildCustomizationCard({
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

    final cardBg = isDark ? const Color(0xFF16241E) : Colors.white;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(
          color: accentGold.withValues(alpha: isDark ? 0.35 : 0.35),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. حقل عنوان الخطة وحقل اختيار التذكير/الوقت مدمجان بسلاسة وبنفس الحجم
          Row(
            children: [
              // حقل عنوان الخطة مباشرة باستخدام TextField مع InputDecoration متقن
              Expanded(
                flex: 11,
                child: SizedBox(
                  height: 38.h,
                  child: TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF7FAF7),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 9.h,
                      ),
                      prefixIcon: Icon(
                        Icons.edit_note_rounded,
                        size: 18.sp,
                        color: accentGold,
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: 32.w,
                        minHeight: 38.h,
                      ),
                      hintText: 'عنوان الخطة (اختياري)',
                      hintStyle: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.sp,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.1),
                          width: 0.9,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(
                          color: accentGold,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // حقل وقت التذكير كحقل اختيار تفاعلي واضح وبنفس الارتفاع والمظهر
              Expanded(
                flex: 9,
                child: InkWell(
                  onTap: isPrayers ? _showPrayersInfoDialog : _pickReminderTime,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    height: 38.h,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF7FAF7),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.1),
                        width: 0.9,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPrayers ? Icons.mosque_outlined : Icons.access_time_rounded,
                          size: 15.sp,
                          color: accentGold,
                        ),
                        SizedBox(width: 5.w),
                        Expanded(
                          child: Text(
                            isPrayers ? 'مع كل صلاة' : formattedTime,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                        Icon(
                          isPrayers ? Icons.info_outline_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 16.sp,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. فاصل ناعم ومضغوط
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Divider(
              height: 1,
              thickness: 0.6,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),

          // 3. محتوى تخصيص المسار المحدد
          _buildTrackSettingsContent(isDark: isDark, accentGold: accentGold),
        ],
      ),
    );
  }

  Widget _buildTrackSettingsContent({
    required bool isDark,
    required Color accentGold,
  }) {
    switch (_selectedType) {
      case KhatmaPlanType.prayers:
        final totalPerDay = _pagesPerPrayer * 5;
        final days = (604 / totalPerDay).ceil();
        return _buildSliderControls(
          isDark: isDark,
          accentGold: accentGold,
          title: 'عدد الصفحات بعد كل صلاة:',
          valueText: '$_pagesPerPrayer ${_pagesPerPrayer == 1 ? 'صفحة' : 'صفحات'}',
          value: _pagesPerPrayer.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          onChanged: (val) => setState(() => _pagesPerPrayer = val.round()),
          minLabel: '1 ص',
          maxLabel: '10 ص',
          infoText:
              'المعدل: $totalPerDay صفحة يومياً • إتمام المصحف خلال $days يوماً بإذن الله',
        );

      case KhatmaPlanType.dailyPages:
        final days = (604 / _dailyPages).ceil();
        return _buildSliderControls(
          isDark: isDark,
          accentGold: accentGold,
          title: 'عدد الصفحات اليومية:',
          valueText: _dailyPages == 1
              ? '1 صفحة / يوم'
              : '$_dailyPages صفحة / يوم',
          value: _dailyPages.toDouble(),
          min: 1,
          max: 60,
          divisions: 59,
          onChanged: (val) => setState(() => _dailyPages = val.round()),
          minLabel: '1 ص',
          maxLabel: '60 ص',
          infoText: _dailyPages == 1
              ? 'ستتم الختمة المباركة بإذن الله خلال 604 يوماً'
              : 'ستتم الختمة المباركة بإذن الله خلال $days يوماً',
        );

      case KhatmaPlanType.durationDays:
        final pagesPerDay = (604 / _targetDays).ceil();
        final daysLabel = _targetDays == 1
            ? 'يوم واحد'
            : _targetDays == 2
                ? 'يومان'
                : '$_targetDays يوماً';
        return _buildSliderControls(
          isDark: isDark,
          accentGold: accentGold,
          title: 'المدة المستهدفة بالأيام:',
          valueText: daysLabel,
          value: _targetDays.toDouble(),
          min: 1,
          max: 180,
          divisions: 179,
          onChanged: (val) => setState(() => _targetDays = val.round()),
          minLabel: 'يوم واحد',
          maxLabel: '6 أشهر (180 يوماً)',
          infoText: _targetDays == 1
              ? 'ختمة مكثفة في يوم واحد: قراءة المصحف كاملاً (604 صفحة)'
              : 'المطلوب قراءة $pagesPerDay صفحة يومياً لإتمام الختمة في الموعد',
        );

      case KhatmaPlanType.freeReading:
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : const Color(0xFFF7FAF7),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: accentGold,
                size: 15.sp,
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: Text(
                  'مسار مفتوح بدون ضغوط، تقدم حسب استطاعتك وتتبع صفحاتك وأوسمتك وسلسلة التزامك.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9.5.sp,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildSliderControls({
    required bool isDark,
    required Color accentGold,
    required String title,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String minLabel,
    required String maxLabel,
    required String infoText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10.5.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: accentGold.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Text(
                valueText,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.bold,
                  color: accentGold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accentGold,
            inactiveTrackColor: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            thumbColor: accentGold,
            overlayColor: accentGold.withValues(alpha: 0.2),
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: 6.r,
              elevation: 2,
            ),
            trackHeight: 3.h,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              onChanged(val);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                minLabel,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 9.sp,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Text(
                maxLabel,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 9.sp,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : const Color(0xFFF7FAF7),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: accentGold,
                size: 13.sp,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  infoText,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9.5.sp,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
