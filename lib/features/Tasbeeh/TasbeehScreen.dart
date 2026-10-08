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
        text: 'سبحان الله',
        targetCount: 100,
        currentCount: 0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        isReminderEnabled: false,
      ),
      DhikrModel(
        text: 'الحمد لله',
        targetCount: 100,
        currentCount: 0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        isReminderEnabled: false,
      ),
      DhikrModel(
        text: 'الله أكبر',
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
        _showDummyMessage('تقبل الله طاعتك! تم الوصول للهدف 🎉');
      } else {
        HapticFeedback.lightImpact();
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

  void _showAddZekrDialog() {
    final TextEditingController textController = TextEditingController();
    final TextEditingController targetController = TextEditingController(
      text: '33',
    );
    bool isReminderEnabled = false;
    TimeOfDay reminderTime = const TimeOfDay(hour: 9, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 16.h,
            left: 20.w,
            right: 20.w,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                Text(
                  'إضافة ذكر أو دعاء جديد',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: textController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'نص الذكر / الدعاء',
                    hintText: 'مثال: اللهم بك أصبحنا وبك أمسينا...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: targetController,
                  decoration: InputDecoration(
                    labelText: 'العدد المستهدف',
                    hintText: '33',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Switch.adaptive(
                            value: isReminderEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setModalState(() {
                                isReminderEnabled = val;
                              });
                            },
                          ),
                          Row(
                            children: [
                              Text(
                                'تفعيل تذكير يومي',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                Icons.notifications_outlined,
                                color: AppColors.primary,
                                size: 20.sp,
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isReminderEnabled) ...[
                        const Divider(),
                        SizedBox(height: 8.h),
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
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 10.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
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
                                        fontSize: 14.sp,
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
                                fontSize: 13.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final text = textController.text.trim();
                          if (text.isEmpty) return;

                          final newDhikr = DhikrModel(
                            text: text,
                            targetCount:
                                int.tryParse(targetController.text) ?? 33,
                            currentCount: 0,
                            createdAt: DateTime.now(),
                            lastUpdated: DateTime.now(),
                            isReminderEnabled: isReminderEnabled,
                            reminderHour: reminderTime.hour,
                            reminderMinute: reminderTime.minute,
                          );

                          await dhikrBox.add(newDhikr);
                          await TasbeehNotificationService.scheduleReminder(
                            newDhikr,
                          );

                          if (mounted) {
                            Navigator.pop(context);
                            setState(() {
                              _currentZekr = newDhikr.text;
                              _target = newDhikr.targetCount;
                              _currentCount = 0;
                            });
                          }
                          _showDummyMessage('تم حفظ وجدولة الذكر بنجاح');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'حفظ',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditZekrDialog(DhikrModel dhikr) {
    final TextEditingController textController = TextEditingController(
      text: dhikr.text,
    );
    final TextEditingController targetController = TextEditingController(
      text: dhikr.targetCount.toString(),
    );
    bool isReminderEnabled = dhikr.isReminderEnabled;
    TimeOfDay reminderTime = TimeOfDay(
      hour: dhikr.reminderHour,
      minute: dhikr.reminderMinute,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 16.h,
            left: 20.w,
            right: 20.w,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                Text(
                  'تعديل الذكر / الدعاء',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: textController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'نص الذكر / الدعاء',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: targetController,
                  decoration: InputDecoration(
                    labelText: 'العدد المستهدف',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Switch.adaptive(
                            value: isReminderEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setModalState(() {
                                isReminderEnabled = val;
                              });
                            },
                          ),
                          Row(
                            children: [
                              Text(
                                'تفعيل تذكير يومي',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                Icons.notifications_outlined,
                                color: AppColors.primary,
                                size: 20.sp,
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isReminderEnabled) ...[
                        const Divider(),
                        SizedBox(height: 8.h),
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
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 10.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
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
                                        fontSize: 14.sp,
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
                                fontSize: 13.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final text = textController.text.trim();
                          if (text.isEmpty) return;

                          final bool isActiveSelected =
                              _currentZekr == dhikr.text;

                          dhikr.text = text;
                          dhikr.targetCount =
                              int.tryParse(targetController.text) ?? 33;
                          dhikr.isReminderEnabled = isReminderEnabled;
                          dhikr.reminderHour = reminderTime.hour;
                          dhikr.reminderMinute = reminderTime.minute;
                          dhikr.lastUpdated = DateTime.now();

                          await dhikr.save();
                          await TasbeehNotificationService.scheduleReminder(
                            dhikr,
                          );

                          if (mounted) {
                            Navigator.pop(context); // Close sheet
                            if (isActiveSelected) {
                              setState(() {
                                _currentZekr = dhikr.text;
                                _target = dhikr.targetCount;
                                _currentCount = dhikr.currentCount;
                              });
                            }
                          }
                          _showDummyMessage('تم تعديل وجدولة الذكر بنجاح');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'حفظ',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showZekrSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              height: 520.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: AppColors.primary,
                        iconSize: 28.sp,
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddZekrDialog();
                        },
                      ),
                      Text(
                        'قائمة الأذكار والتسبيحات',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: dhikrBox.isEmpty
                        ? const Center(child: Text('لا توجد أذكار حالياً'))
                        : ListView.builder(
                            itemCount: dhikrBox.length,
                            itemBuilder: (context, index) {
                              final dhikr = dhikrBox.getAt(index);
                              if (dhikr == null) {
                                return const SizedBox.shrink();
                              }

                              final isSelected = _currentZekr == dhikr.text;

                              return Container(
                                margin: EdgeInsets.only(bottom: 10.h),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(
                                          alpha: 0.05,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary.withValues(
                                            alpha: 0.3,
                                          )
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 4.h,
                                  ),
                                  title: Text(
                                    dhikr.text,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.primary
                                          : null,
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
                                          size: 14.sp,
                                          color: AppColors.goldAccent,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'تذكير يومي: ${dhikr.reminderHour.toString().padLeft(2, '0')}:${dhikr.reminderMinute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: AppColors.goldAccent,
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
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
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
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('إلغاء'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  child: const Text('حذف'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await TasbeehNotificationService.cancelReminder(
                                              dhikr,
                                            );
                                            await dhikr.delete();

                                            setModalState(() {});
                                            setState(() {});
                                            _showDummyMessage('تم حذف الذكر');

                                            _loadFirstDhikr();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _currentZekr = dhikr.text;
                                      _target = dhikr.targetCount;
                                      _currentCount = dhikr.currentCount;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
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

                  // Progress Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'التقدم',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Text(
                              '$_currentCount / $_target',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: LinearProgressIndicator(
                            value: _progress.clamp(0.0, 1.0),
                            minHeight: 12,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40.h),

                  // Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.refresh_rounded,
                        label: 'إعادة تعيين',
                        color: Colors.red,
                        onPressed: _resetCounter,
                      ),
                      _buildControlButton(
                        icon: Icons.list_rounded,
                        label: 'قائمة الأذكار',
                        color: Colors.blue.shade700,
                        onPressed: _showZekrSelector,
                      ),
                      _buildControlButton(
                        icon: Icons.track_changes_rounded,
                        label: 'الهدف',
                        color: AppColors.primarySoft,
                        onPressed: _onCounterTap,
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        Material(
          elevation: 4,
          shape: const CircleBorder(),
          color: color.withValues(alpha: 0.1),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(100.r),
            splashColor: color.withValues(alpha: 0.15),
            highlightColor: Colors.transparent,
            child: Container(
              width: 70.w,
              height: 70.h,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32.sp),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
