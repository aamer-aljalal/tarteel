import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tarteel/features/Tasbeeh/models/dhikr_model.dart';
import 'package:tarteel/features/Tasbeeh/services/tasbeeh_notification_service.dart';

import 'package:tarteel/core/services/stats_service.dart';
import 'package:tarteel/core/widgets/buttons/interactive_counter_control.dart';
import 'package:tarteel/core/widgets/bottom_sheets/app_modal_bottom_sheet.dart';
import 'package:tarteel/core/widgets/dialogs/app_confirm_dialog.dart';
import 'package:tarteel/core/widgets/cards/interactive_content_card.dart';

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen>
    with SingleTickerProviderStateMixin {
  late Box<DhikrModel> dhikrBox;
  late final AnimationController _misbahaController;

  bool _isSoundEnabled = true;
  bool _isHapticEnabled = true;

  String _currentZekr = 'سبحان الله والحمد لله ولا إله إلا الله والله أكبر';
  int _currentCount = 0;
  int _target = 100;
  double _activeFontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _misbahaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    dhikrBox = Hive.box<DhikrModel>('dhikrBox');
    _loadPreferences();
    _initializeDhikr();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isSoundEnabled = prefs.getBool('tasbeeh_sound_enabled') ?? true;
        _isHapticEnabled = prefs.getBool('tasbeeh_haptic_enabled') ?? true;
      });
    }
  }

  Future<void> _toggleSound() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSoundEnabled = !_isSoundEnabled;
    });
    await prefs.setBool('tasbeeh_sound_enabled', _isSoundEnabled);
    if (_isHapticEnabled) {
      HapticFeedback.lightImpact();
    }
    _showDummyMessage(
      _isSoundEnabled ? 'تم تفعيل صوت نقرة المسبحة' : 'تم كتم صوت المسبحة',
    );
  }

  Future<void> _toggleHaptic() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isHapticEnabled = !_isHapticEnabled;
    });
    await prefs.setBool('tasbeeh_haptic_enabled', _isHapticEnabled);
    if (_isHapticEnabled) {
      HapticFeedback.mediumImpact();
    }
    _showDummyMessage(
      _isHapticEnabled ? 'تم تفعيل الاهتزاز التفاعلي' : 'تم تعطيل الاهتزاز',
    );
  }

  @override
  void dispose() {
    _misbahaController.dispose();
    super.dispose();
  }

  Future<void> _initializeDhikr() async {
    await _addDefaultAzkar();
    _loadFirstDhikr();
  }

  Future<void> _addDefaultAzkar() async {
    if (dhikrBox.isNotEmpty) return;

    final defaultAzkar = [
      DhikrModel(
        text: 'سبحان الله والحمد لله ولا إله إلا الله والله أكبر',
        targetCount: 100,
        currentCount: 0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        isReminderEnabled: false,
      ),
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

    final selectedDhikr = dhikrBox.values.firstWhere(
      (dhikr) => dhikr.text == _currentZekr,
      orElse: () => dhikrBox.values.first,
    );

    // Record stats
    await StatsService.recordAction('tasbeeh');

    // تشغيل أنميشن المسبحة لتدور وتتفاعل مع الضغطة
    _misbahaController.forward(from: 0.0);

    setState(() {
      _currentCount++;
      if (_currentCount >= _target) {
        _currentCount = 0;
        if (_isHapticEnabled) HapticFeedback.vibrate();
        _showDummyMessage('تقبل الله طاعتك! تم الوصول للهدف');
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
                final confirm = await AppConfirmDialog.show(
                  context,
                  title: 'حذف الذكر',
                  message: 'هل أنت متأكد من حذف "${dhikr.text}"؟',
                  confirmText: 'حذف',
                  isDestructive: true,
                  icon: Icons.delete_outline_rounded,
                );
                if (confirm) {
                  await TasbeehNotificationService.cancelReminder(dhikr);
                  await dhikr.delete();
                  if (!mounted) return;
                  // Navigator.pop(context);
                  _loadFirstDhikr();
                  _showDummyMessage('تم حذف الذكر بنجاح');
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
                hintText: '100',
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
      heightFraction: 0.75,

      emptyMessage: 'لا توجد أذكار حالياً، يمكنك إضافة ذكرك الأول الآن',
      items: dhikrBox.values.map((dhikr) {
        final isSelected = _currentZekr == dhikr.text;

        return BottomSheetItem(
          title: dhikr.text,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _currentZekr = dhikr.text;
              _target = dhikr.targetCount;
              _currentCount = dhikr.currentCount;
            });
            Navigator.pop(context);
          },
          subtitleWidget: Row(
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
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
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
          actions: [
            BottomSheetItemAction.edit(
              onEdit: () {
                Navigator.pop(context);
                _showEditZekrDialog(dhikr);
              },
            ),
            BottomSheetItemAction.delete(
              confirmTitle: 'حذف الذكر',
              confirmMessage: 'هل أنت متأكد من حذف "${dhikr.text}"؟',
              onDelete: () async {
                await TasbeehNotificationService.cancelReminder(dhikr);
                await dhikr.delete();
                if (mounted) {
                  Navigator.pop(context);
                  _loadFirstDhikr();
                  _showDummyMessage('تم حذف الذكر');
                }
              },
            ),
          ],
        );
      }).toList(),
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
    final bool isEmpty = dhikrBox.isEmpty || _currentZekr.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: tarteelAppBar(titleText: 'التسبيح', toolbarHeight: 90),
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
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                children: [
                  // بطاقة الذكر التفاعلية الموحدة
                  Expanded(
                    child: InteractiveContentCard(
                      content: _currentZekr,
                      fontSize: _activeFontSize,
                      onZoomIn: () {
                        if (_activeFontSize < 35.0) {
                          setState(() {
                            _activeFontSize += 2.0;
                          });
                          HapticFeedback.lightImpact();
                        }
                      },
                      onZoomOut: () {
                        if (_activeFontSize > 12.0) {
                          setState(() {
                            _activeFontSize -= 2.0;
                          });
                          HapticFeedback.lightImpact();
                        }
                      },
                      showZoomControls: true,
                      showFavorite: false,
                      showShare: false,
                      showCopy: true,
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: _currentZekr));
                        HapticFeedback.mediumImpact();
                        _showDummyMessage('تم نسخ الذكر بنجاح');
                      },
                      counterBadgeText: 'الهدف : $_currentCount / $_target',
                      showCounterBadge: true,
                      showIndexLabel: false,
                      headerTrailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: _isSoundEnabled
                                ? 'كتم صوت نقرة المسبحة'
                                : 'تفعيل صوت نقرة المسبحة',
                            child: InkWell(
                              onTap: _toggleSound,
                              borderRadius: BorderRadius.circular(12.r),
                              child: Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: _isSoundEnabled
                                      ? AppColors.primary.withValues(
                                          alpha: 0.12,
                                        )
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  _isSoundEnabled
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_off_rounded,
                                  size: 19.sp,
                                  color: _isSoundEnabled
                                      ? AppColors.primary
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                        ],
                      ),
                      customActions: [
                        CardAction(
                          icon: Icons.edit_outlined,
                          tooltip: 'تعديل الذكر',
                          color: Colors.amber.shade800,
                          onTap: () {
                            final currentDhikr = dhikrBox.values.firstWhere(
                              (d) => d.text == _currentZekr,
                              orElse: () => dhikrBox.values.first,
                            );
                            _showEditZekrDialog(currentDhikr);
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // العداد التفاعلي مع أزرار الإجراءات الجانبية وإعادة التعيين
                  InteractiveCounterControl(
                    count: _currentCount,
                    totalRepeat: _target,
                    progress: _progress,
                    onCounterTap: _onCounterTap,
                    showProgressRing: false,
                    size: 115.w,
                    countFontSize: 34.sp,
                    pressedScale: 1.0,
                    enableSound: _isSoundEnabled,
                    soundAsset: 'assets/audio/tasbeeh/tasbeeh_velvet.wav',
                    soundVolume: 0.05,
                    enableHaptic: _isHapticEnabled,
                    customProgressRing: SizedBox(
                      width: 170.w,
                      height: 170.w,
                      child: Lottie.asset(
                        'assets/animation/tasbih/misbaha_tasbeeh.json',
                        controller: _misbahaController,
                        fit: BoxFit.contain,
                      ),
                    ),
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
