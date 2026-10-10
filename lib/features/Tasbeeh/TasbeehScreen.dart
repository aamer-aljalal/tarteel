import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tarteel/features/Tasbeeh/models/dhikr_model.dart';
import 'package:tarteel/features/Tasbeeh/services/tasbeeh_notification_service.dart';
import 'package:tarteel/core/widgets/Text/Responsive_text.dart';

import 'package:tarteel/core/services/stats_service.dart';
import 'package:tarteel/core/widgets/buttons/interactive_counter_control.dart';
import 'package:tarteel/core/widgets/bottom_sheets/app_modal_bottom_sheet.dart';

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen>
    with SingleTickerProviderStateMixin {
  late Box<DhikrModel> dhikrBox;

  String _currentZekr = 'سبحان الله';
  int _currentCount = 0;
  int _target = 100;

  double _buttonScale = 1.0;

  @override
  void initState() {
    super.initState();
    dhikrBox = Hive.box<DhikrModel>('dhikrBox');
    _initializeDhikr();
  }

  Future<void> _initializeDhikr() async {
    await _addDefaultAzkar();
    _loadFirstDhikr();
  }

  Future<void> _addDefaultAzkar() async {
    if (dhikrBox.isNotEmpty) return;

    final defaultAzkar = [
      DhikrModel(
        text: 'استغفر الله',
        targetCount: 100,
        currentCount: 0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        isReminderEnabled: false,
      ),
      DhikrModel(
        text: 'سبحان الله',
        targetCount: 100,
        currentCount: 0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        isReminderEnabled: true,
      ),
      DhikrModel(
        text: 'سبحان الله وبحمده سبحان الله العظيم',
        targetCount: 100,
        currentCount: 0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        isReminderEnabled: false,
      ),
      DhikrModel(
        text: 'سبحان الله والحمد لله ولا إله إلا الله والله أكبر',
        targetCount: 100,
        currentCount: 0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        isReminderEnabled: false,
      ),
    ];

    await dhikrBox.addAll(defaultAzkar);
  }

  void _loadFirstDhikr() {
    if (dhikrBox.isEmpty) {
      setState(() {
        _currentZekr = '';
        _currentCount = 0;
        _target = 0;
      });
      return;
    }

    final firstDhikr = dhikrBox.values.first;

    setState(() {
      _currentZekr = firstDhikr.text;
      _currentCount = firstDhikr.currentCount;
      _target = firstDhikr.targetCount;
    });
  }

  Future<void> _onCounterTap() async {
    if (dhikrBox.isEmpty || _currentZekr.isEmpty) return;

    setState(() {
      _buttonScale = 0.9;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _buttonScale = 1.0;
        });
      }
    });

    final selectedDhikr = dhikrBox.values.firstWhere(
      (dhikr) => dhikr.text == _currentZekr,
      orElse: () => dhikrBox.values.first,
    );

    // Record stats
    await StatsService.recordAction('tasbeeh');

    setState(() {
      _currentCount++;
      if (_currentCount >= _target) {
        _currentCount = 0;
        HapticFeedback.vibrate();
        _showDummyMessage('تقبل الله طاعتك! تم الوصول للهدف');
      } else {
        HapticFeedback.mediumImpact();
      }
    });

    selectedDhikr.currentCount = _currentCount;
    selectedDhikr.lastUpdated = DateTime.now();
    await selectedDhikr.save();
  }

  Future<void> _resetCounter() async {
    if (dhikrBox.isEmpty || _currentZekr.isEmpty) return;

    final selectedDhikr = dhikrBox.values.firstWhere(
      (dhikr) => dhikr.text == _currentZekr,
      orElse: () => dhikrBox.values.first,
    );

    setState(() {
      _currentCount = 0;
    });

    selectedDhikr.currentCount = 0;
    selectedDhikr.lastUpdated = DateTime.now();
    await selectedDhikr.save();

    HapticFeedback.mediumImpact();
    _showDummyMessage('تم إعادة تعيين العداد');
  }

  void _showAddZekrDialog() => _showDhikrFormDialog();

  void _showEditZekrDialog(DhikrModel dhikr) =>
      _showDhikrFormDialog(dhikr: dhikr);

  void _showDhikrFormDialog({DhikrModel? dhikr}) {
    final bool isEdit = dhikr != null;
    final TextEditingController textController = TextEditingController(
      text: isEdit ? dhikr.text : '',
    );
    final TextEditingController targetController = TextEditingController(
      text: isEdit ? dhikr.targetCount.toString() : '33',
    );
    bool isReminderEnabled = isEdit ? dhikr.isReminderEnabled : false;
    TimeOfDay reminderTime = isEdit
        ? TimeOfDay(hour: dhikr.reminderHour, minute: dhikr.reminderMinute)
        : const TimeOfDay(hour: 9, minute: 0);

    AppModalBottomSheet.show(
      context: context,
      title: isEdit ? 'تعديل الذكر' : 'إضافة ذكر جديد',

      heightFraction: 0.72,
      trailing: isEdit
          ? IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade600,
                size: 22.sp,
              ),
              tooltip: 'حذف الذكر',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('حذف الذكر', textAlign: TextAlign.right),
                    content: Text(
                      'هل أنت متأكد من حذف "${dhikr.text}"؟',
                      textAlign: TextAlign.right,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await TasbeehNotificationService.cancelReminder(dhikr);
                  await dhikr.delete();
                  if (mounted) {
                    Navigator.pop(context);
                    _loadFirstDhikr();
                    _showDummyMessage('تم حذف الذكر بنجاح');
                  }
                }
              },
            )
          : null,
      bottomWidget: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text(
                'إلغاء',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () async {
                final text = textController.text.trim();
                if (text.isEmpty) {
                  _showDummyMessage('يرجى إدخال نص الذكر');
                  return;
                }

                final target = int.tryParse(targetController.text) ?? 33;

                if (isEdit) {
                  final bool isActiveSelected = _currentZekr == dhikr.text;
                  dhikr.text = text;
                  dhikr.targetCount = target;
                  dhikr.isReminderEnabled = isReminderEnabled;
                  dhikr.reminderHour = reminderTime.hour;
                  dhikr.reminderMinute = reminderTime.minute;
                  dhikr.lastUpdated = DateTime.now();

                  await dhikr.save();
                  await TasbeehNotificationService.scheduleReminder(dhikr);

                  if (mounted) {
                    Navigator.pop(context);
                    if (isActiveSelected) {
                      setState(() {
                        _currentZekr = dhikr.text;
                        _target = dhikr.targetCount;
                        _currentCount = dhikr.currentCount;
                      });
                    }
                  }
                  _showDummyMessage('تم تعديل الذكر بنجاح');
                } else {
                  final newDhikr = DhikrModel(
                    text: text,
                    targetCount: target,
                    currentCount: 0,
                    createdAt: DateTime.now(),
                    lastUpdated: DateTime.now(),
                    isReminderEnabled: isReminderEnabled,
                    reminderHour: reminderTime.hour,
                    reminderMinute: reminderTime.minute,
                  );

                  await dhikrBox.add(newDhikr);
                  await TasbeehNotificationService.scheduleReminder(newDhikr);

                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {
                      _currentZekr = newDhikr.text;
                      _target = newDhikr.targetCount;
                      _currentCount = 0;
                    });
                  }
                  _showDummyMessage('تمت إضافة الذكر بنجاح');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Text(
                isEdit ? 'حفظ التعديلات' : 'إضافة الذكر',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      child: StatefulBuilder(
        builder: (context, setModalState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: textController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'نص الذكر / الدعاء',
                hintText: 'مثال: سبحان الله وبحمده...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
              textAlign: TextAlign.right,
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: targetController,
              decoration: InputDecoration(
                labelText: 'العدد المستهدف',
                hintText: '33',
                prefixIcon: const Icon(Icons.flag_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'تفعيل التذكير اليومي',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'إرسال إشعار تنبيه يومي في وقت محدد',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    value: isReminderEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setModalState(() {
                        isReminderEnabled = val;
                      });
                    },
                  ),
                  if (isReminderEnabled) ...[
                    const Divider(height: 1),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: reminderTime,
                            );
                            if (picked != null) {
                              setModalState(() {
                                reminderTime = picked;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16.sp,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  reminderTime.format(context),
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          'وقت التذكير اليومي:',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
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
    );
  }

  void _showZekrSelector() {
    AppModalBottomSheet.show(
      context: context,
      title: 'قائمة الأذكار والتسبيحات',
      // subtitle: 'اختر ذكراً للتسبيح أو اضغط لتعديله',
      heightFraction: 0.75,
      trailing: IconButton(
        icon: Icon(
          Icons.add_circle_outline_rounded,
          color: AppColors.primary,
          size: 26.sp,
        ),
        tooltip: 'إضافة ذكر جديد',
        onPressed: () {
          Navigator.pop(context);
          _showAddZekrDialog();
        },
      ),
      itemCount: dhikrBox.length,
      emptyMessage: 'لا توجد أذكار حالياً، يمكنك إضافة ذكرك الأول الآن',
      itemBuilder: (context, index) {
        final dhikr = dhikrBox.getAt(index);
        if (dhikr == null) return const SizedBox.shrink();

        final isSelected = _currentZekr == dhikr.text;

        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.06)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 4.h,
            ),
            onTap: () {
              setState(() {
                _currentZekr = dhikr.text;
                _target = dhikr.targetCount;
                _currentCount = dhikr.currentCount;
              });
              Navigator.pop(context);
            },
            title: Text(
              dhikr.text,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primary : null,
                fontSize: 15.sp,
              ),
              textAlign: TextAlign.right,
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (dhikr.isReminderEnabled) ...[
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 13.sp,
                    color: AppColors.goldAccent,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${dhikr.reminderHour.toString().padLeft(2, '0')}:${dhikr.reminderMinute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.goldAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10.w),
                ],
                Text(
                  'الهدف: ${dhikr.targetCount}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'الحالي: ${dhikr.currentCount}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18.sp,
                    color: Colors.blue.shade700,
                  ),
                  tooltip: 'تعديل',
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditZekrDialog(dhikr);
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18.sp,
                    color: Colors.red.shade700,
                  ),
                  tooltip: 'حذف',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text(
                          'حذف الذكر',
                          textAlign: TextAlign.right,
                        ),
                        content: Text(
                          'هل أنت متأكد من حذف "${dhikr.text}"؟',
                          textAlign: TextAlign.right,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('إلغاء'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('حذف'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await TasbeehNotificationService.cancelReminder(dhikr);
                      await dhikr.delete();
                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadFirstDhikr();
                        _showDummyMessage('تم حذف الذكر');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDummyMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  double get _progress => _target > 0 ? (_currentCount / _target) : 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isEmpty = dhikrBox.isEmpty || _currentZekr.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: tarteelAppBar(
        titleText: 'التسبيح',
        toolbarHeight: 90,

        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddZekrDialog,
            tooltip: 'إضافة ذكر جديد',
          ),
        ],
      ),
      body: isEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.spa_outlined,
                        size: 80.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'لا توجد أذكار أو أدعية حالياً',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'قم بإنشاء دعائك أو تسبيحك الخاص للبدء بالذكر وتلقي التذكيرات اليومية الفخمة.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),
                    ElevatedButton.icon(
                      onPressed: _showAddZekrDialog,
                      icon: Icon(Icons.add_rounded, size: 20.sp),
                      label: Text(
                        'أنشئ دعاءك الخاص',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 14.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: Column(
                children: [
                  // Current Zekr Display
                  Container(
                    width: double.infinity,
                    height: 130.h,
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 16.w,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.subtleShadow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: ResponsiveText(
                        content: _currentZekr,
                        fontSize: 24,
                        maxFontSize: 28,
                        minFontSize: 12,
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                        height: 1.8,
                        textAlign: TextAlign.center,
                        maxLines: 8,
                        color: isDark
                            ? AppColors.goldAccent
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),

                  // Main Counter Circle
                  GestureDetector(
                    onTap: _onCounterTap,
                    child: AnimatedScale(
                      scale: _buttonScale,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        width: 220.w,
                        height: 220.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            center: Alignment.center,
                            radius: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$_currentCount',
                            style: TextStyle(
                              fontSize: 56.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),

                  // العداد التفاعلي مع أزرار الإجراءات الجانبية وإعادة التعيين
                  InteractiveCounterControl(
                    count: _currentCount,
                    totalRepeat: _target,
                    progress: _progress,
                    onCounterTap: _onCounterTap,
                    showNavigationButtons: false,
                    // الزر الأيمن: إظهار قائمة الأذكار
                    rightSideAction: CounterSideAction(
                      icon: Icons.list_rounded,
                      label: 'قائمة الأذكار',
                      onTap: _showZekrSelector,
                      color: Colors.blue.shade700,
                    ),
                    // الزر الأيسر: إضافة دعاء / ذكر جديد
                    leftSideAction: CounterSideAction(
                      icon: Icons.add_rounded,
                      label: 'إضافة ذكر',
                      onTap: _showAddZekrDialog,
                      color: AppColors.primary,
                    ),
                    // زر إعادة التعيين في الأسفل
                    showResetButton: true,
                    onReset: _resetCounter,
                    resetLabel: 'إعادة تعيين العداد',
                    resetConfirmTitle: 'تأكيد تصفير العداد',
                    resetConfirmMessage:
                        'هل تريد إعادة تعيين عداد التسبيح الحالي والبدء من جديد؟',
                    hintText: 'اضغط للتسبيح واحتساب الأجر',
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
    );
  }
}
