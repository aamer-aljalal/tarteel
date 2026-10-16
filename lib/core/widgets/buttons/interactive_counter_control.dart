import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/dialogs/app_confirm_dialog.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_reader_cubit.dart';

/// [CounterSideAction]
/// تعريف لزر جانبي جاهز ومصمم باحترافية ليوضع على يمين أو يسار العداد التفاعلي.
class CounterSideAction {
  /// أيقونة الزر
  final IconData icon;

  /// عنوان أو نص الزر (يظهر أسفل الأيقونة بتصميم منسق)
  final String? label;

  /// الدالة المستدعاة عند الضغط
  final VoidCallback? onTap;

  /// اللون الرئيسي للأيقونة والنص
  final Color? color;

  /// لون خلفية الدائرة (اختياري)
  final Color? backgroundColor;

  /// نص التلميح
  final String? tooltip;

  const CounterSideAction({
    required this.icon,
    this.label,
    this.onTap,
    this.color,
    this.backgroundColor,
    this.tooltip,
  });
}

/// [InteractiveCounterControl]
/// مكون تفاعلي عام، مرن، وقابل لإعادة الاستخدام لإدارة العدادات وحلقات التقدم
/// (أذكار، أدعية، تسبيح، أو أي شاشة تتطلب عداد تفاعلي مع إمكانيات تحكم).
///
/// المميزات:
/// 1. زر دائري تفاعلي مركزي مع مؤشر تقدم دائري (Progress Ring) وتأثير ارتداد ناعم (Scale Animation).
/// 2. أزرار جانبية جاهزة التصميم ([rightSideAction] و [leftSideAction]) دون الحاجة لإعادة كتابة تصميم الأزرار.
/// 3. أزرار تنقل مرنة (السابق والتالي) مع ضبط الاتجاه بدقة:
///    - الزر على اليمين: يتقدم للتالي ([onNext]).
///    - الزر على اليسار: يرجع للسابق ([onPrevious]).
/// 4. فتحات ويدجت مخصصة ([leftAction] و [rightAction]) لأي عناصر يدوية بالكامل.
/// 5. منطقة سفلية لتلميح الاستخدام وزر إعادة التعيين أو أي محتوى مخصص عبر ([bottomAction]).
/// 6. تكيف كامل مع الوضع الليلي والنهاري وتصميم تطبيق ترتيل.
class InteractiveCounterControl extends StatefulWidget {
  /// العدد الحالي المنجز (اختياري: إن لم يُمرر يتم جلبه تلقائياً من الكيوبت)
  final int? count;

  /// العدد الإجمالي المستهدف (اختياري: إن لم يُمرر يتم جلبه تلقائياً من الكيوبت)
  final int? totalRepeat;

  /// نسبة التقدم من 0.0 إلى 1.0 (اختياري: تُحسب تلقائياً من الكيوبت أو العداد)
  final double? progress;

  /// إجراء عند النقر على الزر الدائري المركزي (اختياري: إن لم يُمرر يُنفذ دالة الكيوبت تلقائياً)
  final VoidCallback? onCounterTap;

  /// وحدة التحكم بصفحات العرض للتنقل التلقائي والسلس (اختياري)
  final PageController? pageController;

  /// هل ينتقل تلقائياً للذكر التالي عند بلوغ العدد المطلوب (الافتراضي: true)
  final bool autoNextOnComplete;

  /// هل يسمح بالزيادة الفائضة فوق الهدف إذا عاد المستخدم إليه (الافتراضي: false - حالة التجميد الذكي)
  final bool allowOvercount;

  /// إجراء يُنفذ عند اكتمال كافة أذكار هذا القسم بالكامل (اختياري)
  final VoidCallback? onAllCompleted;

  /// إجراء اختياري يُنفذ عند بلوغ الهدف المحدد للمرة الأولى (مثل فتح قائمة الأذكار في شاشة التسبيح)
  final VoidCallback? onTargetReached;

  /// إجراء إعادة التعيين
  final VoidCallback? onReset;

  /// هل يظهر زر إعادة التعيين
  final bool showResetButton;

  /// نص زر إعادة التعيين
  final String resetLabel;

  /// لون زر إعادة التعيين
  final Color resetColor;

  /// أيقونة زر إعادة التعيين
  final IconData resetIcon;

  /// هل تتطلب عملية إعادة التعيين نافذة تأكيد للمستخدم
  final bool requireResetConfirmation;

  /// عنوان نافذة تأكيد إعادة التعيين
  final String? resetConfirmTitle;

  /// نص رسالة تأكيد إعادة التعيين
  final String? resetConfirmMessage;

  /// نص زر التأكيد داخل النافذة
  final String resetConfirmActionText;

  /// نص زر الإلغاء داخل النافذة
  final String resetCancelActionText;

  /// هل يظهر نص التلميح التوجيهي
  final bool showHint;

  /// نص التلميح التوجيهي
  final String hintText;

  /// إجراء الانتقال للعنصر التالي (الزر على اليمين)
  final VoidCallback? onNext;

  /// إجراء الانتقال للعنصر السابق (الزر على اليسار)
  final VoidCallback? onPrevious;

  /// هل يوجد عنصر تالٍ (لتفعيل/تعطيل زر التالي)
  final bool hasNext;

  /// هل يوجد عنصر سابق (لتفعيل/تعطيل زر السابق)
  final bool hasPrevious;

  /// هل تظهر أزرار التنقل (السابق والتالي)
  final bool showNavigationButtons;

  /// أيقونة زر التالي (اليمين)
  final IconData nextIcon;

  /// أيقونة زر السابق (اليسار)
  final IconData previousIcon;

  /// زر جانبي جاهز التصميم على الجانب الأيمن (مثل: زر قائمة الأذكار)
  final CounterSideAction? rightSideAction;

  /// زر جانبي جاهز التصميم على الجانب الأيسر (مثل: زر إضافة ذكر)
  final CounterSideAction? leftSideAction;

  /// زر إضافي مخصص في الزاوية اليمنى (الركن الأيمن مثل قائمة الانتقال السريع للأقسام)
  final CounterSideAction? cornerAction;

  /// ويدجت مخصص للزاوية اليمنى
  final Widget? cornerWidget;

  /// زر إضافي مخصص في الزاوية اليسرى
  final CounterSideAction? leftCornerAction;

  /// ويدجت مخصص للزاوية اليسرى
  final Widget? leftCornerWidget;

  /// مكون ويدجت مخصص للجانب الأيمن
  final Widget? rightAction;

  /// مكون ويدجت مخصص للجانب الأيسر
  final Widget? leftAction;

  /// دعم للأسماء البديلة
  final Widget? leadingAction;
  final Widget? trailingAction;

  /// مكون سفلي مخصص بالكامل (يستبدل منطقة إعادة التعيين والتلميح)
  final Widget? bottomAction;

  /// ويدجت مخصص يوضع داخل الدائرة المركزية بديلاً عن الأيقونة ورقم العداد الافتراضي
  final Widget? centerChild;

  /// قطر زر التفاعل الدائري
  final double? size;

  /// سمك حلقة مؤشر التقدم
  final double strokeWidth;

  /// اللون الرئيسي لمؤشر التقدم والنص
  final Color? progressColor;

  /// لون مسار التقدم غير المكتمل
  final Color? progressBackgroundColor;

  /// لون خلفية الزر الدائري (يتكيف مع الثيم إذا كان null)
  final Color? buttonBackgroundColor;

  /// أيقونة اللمس في وسط الزر
  final IconData centerIcon;

  /// هل تظهر أيقونة اللمس
  final bool showCenterIcon;

  /// حجم خط رقم العداد
  final double? countFontSize;

  /// تنسيق نص رقم العداد المخصص
  final TextStyle? countTextStyle;

  /// هل يتم عرض حلقة مؤشر التقدم الدائري (افتراضياً true)
  final bool showProgressRing;

  /// مكون ويدجت مخصص يوضع حول الزر أو بدلاً من مؤشر التقدم (مثل أنميشن المسبحة)
  final Widget? customProgressRing;

  /// مقياس تصغير الزر عند الضغط
  final double pressedScale;

  /// مدة تأثير الضغط
  final Duration scaleDuration;

  /// هل يتم تفعيل صوت النقر عند الضغط على الزر تلقائياً
  final bool enableSound;

  /// مسار ملف الصوت المراد تشغيله (افتراضياً نقرة المسبحة)
  final String? soundAsset;

  /// مستوى حجم الصوت من 0.0 إلى 1.0 (افتراضياً 0.25 لصوت هادئ ومريح وغير مزعج)
  final double soundVolume;

  /// هل يتم تفعيل الاهتزاز عند الضغط
  final bool enableHaptic;

  const InteractiveCounterControl({
    super.key,
    this.count,
    this.totalRepeat,
    this.progress,
    this.onCounterTap,
    this.pageController,
    this.autoNextOnComplete = true,
    this.allowOvercount = false,
    this.onAllCompleted,
    this.onTargetReached,
    this.onReset,
    this.showResetButton = true,
    this.resetLabel = 'بدء من جديد / إعادة تعيين',
    this.resetColor = Colors.redAccent,
    this.resetIcon = Icons.refresh_rounded,
    this.requireResetConfirmation = true,
    this.resetConfirmTitle,
    this.resetConfirmMessage,
    this.resetConfirmActionText = 'إعادة تعيين',
    this.resetCancelActionText = 'إلغاء',
    this.showHint = true,
    this.hintText = 'اضغط على الزر للتكرار والاحتساب',
    this.onNext,
    this.onPrevious,
    this.hasNext = true,
    this.hasPrevious = true,
    this.showNavigationButtons = true,
    this.nextIcon = Icons.arrow_forward_ios_rounded,
    this.previousIcon = Icons.arrow_back_ios_new_rounded,
    this.rightSideAction,
    this.leftSideAction,
    this.cornerAction,
    this.cornerWidget,
    this.leftCornerAction,
    this.leftCornerWidget,
    this.rightAction,
    this.leftAction,
    this.leadingAction,
    this.trailingAction,
    this.bottomAction,
    this.centerChild,
    this.size,
    this.strokeWidth = 8.0,
    this.progressColor,
    this.progressBackgroundColor,
    this.buttonBackgroundColor,
    this.centerIcon = Icons.touch_app,
    this.showCenterIcon = true,
    this.countFontSize,
    this.countTextStyle,
    this.showProgressRing = true,
    this.customProgressRing,
    this.pressedScale = 0.92,
    this.scaleDuration = const Duration(milliseconds: 100),
    this.enableSound = false,
    this.soundAsset = 'assets/audio/tasbeeh/bead_click.wav',
    this.soundVolume = 0.25,
    this.enableHaptic = true,
  });

  /// دالة مساعدة عامة لإظهار نافذة تأكيد إعادة التعيين من أي مكان في التطبيق (مثل الـ AppBar)
  static Future<bool> showResetConfirmation(
    BuildContext context, {
    String? title,
    String? message,
    String confirmText = 'إعادة تعيين',
    String cancelText = 'إلغاء',
    Color confirmColor = Colors.redAccent,
  }) {
    return AppConfirmDialog.show(
      context,
      title: title ?? 'تأكيد إعادة التعيين',
      message: message ?? 'هل تريد إعادة تعيين العداد والبدء من جديد؟',
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
      icon: Icons.refresh_rounded,
    );
  }

  @override
  State<InteractiveCounterControl> createState() =>
      _InteractiveCounterControlState();
}

class _InteractiveCounterControlState extends State<InteractiveCounterControl> {
  double _buttonScale = 1.0;
  AudioPlayer? _audioPlayer;
  bool _targetReachedHandled = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  ReaderCubitContract? get _cubit =>
      widget.count == null ? findReaderCubit(context) : null;

  int get _effectiveCount => widget.count ?? _cubit?.currentCount ?? 0;
  int? get _effectiveTotalRepeat =>
      widget.totalRepeat ?? _cubit?.currentTargetRepeat;

  bool get _effectiveHasNext =>
      widget.onNext != null ? widget.hasNext : (_cubit?.hasNext ?? widget.hasNext);
  bool get _effectiveHasPrevious => widget.onPrevious != null
      ? widget.hasPrevious
      : (_cubit?.hasPrevious ?? widget.hasPrevious);

  @override
  void didUpdateWidget(covariant InteractiveCounterControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableSound != oldWidget.enableSound ||
        widget.soundAsset != oldWidget.soundAsset) {
      _initAudio();
    } else if (widget.soundVolume != oldWidget.soundVolume) {
      _audioPlayer
          ?.setVolume(widget.soundVolume.clamp(0.0, 1.0))
          .catchError((_) {});
    }

    final currentCount = widget.count ?? 0;
    final totalRepeat = widget.totalRepeat ?? 0;
    if (currentCount < totalRepeat ||
        widget.totalRepeat != oldWidget.totalRepeat) {
      _targetReachedHandled = false;
    }
  }

  Future<void> _initAudio() async {
    if (!widget.enableSound) {
      _audioPlayer?.dispose();
      _audioPlayer = null;
      return;
    }

    try {
      _audioPlayer ??= AudioPlayer();
      if (widget.soundAsset != null) {
        await _audioPlayer!.setAsset(widget.soundAsset!);
      }
      await _audioPlayer!.setVolume(widget.soundVolume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  void _playSound() {
    if (!widget.enableSound) return;
    try {
      if (_audioPlayer != null) {
        _audioPlayer!
            .seek(Duration.zero)
            .then((_) => _audioPlayer!.play())
            .catchError((_) {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final hasCustomReset = widget.onReset != null;
    final cubit = _cubit;
    if (!hasCustomReset && cubit == null) return;

    if (!widget.requireResetConfirmation || _effectiveCount == 0) {
      if (hasCustomReset) {
        widget.onReset!();
      } else {
        cubit?.resetCurrentItem();
      }
      return;
    }

    final confirmed = await InteractiveCounterControl.showResetConfirmation(
      context,
      title: widget.resetConfirmTitle,
      message: widget.resetConfirmMessage,
      confirmText: widget.resetConfirmActionText,
      cancelText: widget.resetCancelActionText,
      confirmColor: widget.resetColor,
    );

    if (confirmed) {
      if (hasCustomReset) {
        widget.onReset!();
      } else {
        cubit?.resetCurrentItem();
      }
    }
  }

  void _handleNext() {
    if (widget.onNext != null) {
      widget.onNext!();
    } else if (widget.pageController != null &&
        widget.pageController!.hasClients) {
      widget.pageController!.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_cubit != null) {
      _cubit!.nextItem();
    }
  }

  void _handlePrevious() {
    if (widget.onPrevious != null) {
      widget.onPrevious!();
    } else if (widget.pageController != null &&
        widget.pageController!.hasClients) {
      widget.pageController!.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_cubit != null) {
      _cubit!.previousItem();
    }
  }

  void _handleTap() {
    // 1. تشغيل الاهتزاز المدمج في المكون تلقائياً (دعم شامل لكافة أنواع الهواتف وإصدارات أندرويد)
    if (widget.enableHaptic) {
      HapticFeedback.vibrate();
      HapticFeedback.heavyImpact();
    }

    // 2. تشغيل الصوت المدمج في المكون تلقائياً مع التحكم بالحجم
    _playSound();

    // 3. تأثير الانكماش اللحظي إن كان مفعلاً
    if (widget.pressedScale != 1.0) {
      setState(() {
        _buttonScale = widget.pressedScale;
      });

      Future.delayed(widget.scaleDuration, () {
        if (mounted) {
          setState(() {
            _buttonScale = 1.0;
          });
        }
      });
    }

    if (widget.onCounterTap != null) {
      widget.onCounterTap!();
    } else if (_cubit != null) {
      _cubit!.incrementCounter(
        allowOvercount: widget.allowOvercount,
        autoNextOnComplete: widget.autoNextOnComplete,
        onAutoNext: () {
          if (widget.pageController != null &&
              widget.pageController!.hasClients) {
            widget.pageController!.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        onAllCompleted: widget.onAllCompleted,
      );
    }

    final curCount = _effectiveCount;
    final totalRep = _effectiveTotalRepeat;
    if (widget.onTargetReached != null && totalRep != null && totalRep > 0) {
      if ((curCount + 1) >= totalRep && !_targetReachedHandled) {
        _targetReachedHandled = true;
        widget.onTargetReached!();
      }
    }
  }

  double get _calculatedProgress {
    if (widget.progress != null) {
      return widget.progress!.clamp(0.0, 1.0);
    }
    final cubit = _cubit;
    if (widget.count == null && cubit != null) {
      return cubit.currentProgress.clamp(0.0, 1.0);
    }
    final total = _effectiveTotalRepeat;
    if (total != null && total > 0) {
      return (_effectiveCount / total).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  Widget _buildSideActionWidget(
    CounterSideAction action,
    bool isDark, {
    double? width,
    double? height,
    double? iconSize,
  }) {
    final effectiveColor =
        action.color ?? (isDark ? AppColors.goldAccent : AppColors.goldAccent);
    // action.color ?? AppColors.goldAccent;
    final effectiveBg =
        action.backgroundColor ??
        effectiveColor.withValues(alpha: isDark ? 0.16 : 0.08);

    final w = width ?? 54.w;
    final h = height ?? 54.h;
    final icSize = iconSize ?? 26.sp;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Tooltip(
          message: action.tooltip ?? action.label ?? '',
          child: Material(
            color: effectiveBg,
            shape: const CircleBorder(),
            elevation: isDark ? 0 : 2,
            shadowColor: effectiveColor.withValues(alpha: 0.15),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                action.onTap?.call();
              },
              borderRadius: BorderRadius.circular(100.r),
              splashColor: effectiveColor.withValues(alpha: 0.2),
              child: Container(
                width: w,
                height: h,
                alignment: Alignment.center,
                child: Icon(action.icon, color: effectiveColor, size: icSize),
              ),
            ),
          ),
        ),
        if (action.label != null && action.label!.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Text(
            action.label!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.bold,
              color: effectiveColor,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectivePrimaryColor = widget.progressColor ?? AppColors.primary;
    final effectiveProgressBg =
        widget.progressBackgroundColor ??
        (isDark ? Colors.grey.shade800 : Colors.grey.shade200);
    final effectiveButtonBg =
        widget.buttonBackgroundColor ??
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    final double effectiveSize = widget.size ?? 120.w;
    final double effectiveCountFontSize = widget.countFontSize ?? 35.sp;

    // المكونات الجانبية:
    // الجانب الأيسر (السابق / رجوع للخلف أو زر الإجراء الأيسر)
    final effectiveLeftAction =
        widget.leftAction ??
        (widget.leftSideAction != null
            ? _buildSideActionWidget(widget.leftSideAction!, isDark)
            : widget.leadingAction ??
                  (widget.showNavigationButtons
                      ? IconButton(
                          onPressed: _effectiveHasPrevious
                              ? _handlePrevious
                              : null,
                          icon: Icon(
                            widget.previousIcon,
                            size: 30.sp,
                            color: _effectiveHasPrevious
                                ? effectivePrimaryColor
                                : (isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade400),
                          ),
                        )
                      : null));

    // الجانب الأيمن (التالي / تقدم للأمام أو زر الإجراء الأيمن)
    final effectiveRightAction =
        widget.rightAction ??
        (widget.rightSideAction != null
            ? _buildSideActionWidget(widget.rightSideAction!, isDark)
            : widget.trailingAction ??
                  (widget.showNavigationButtons
                      ? IconButton(
                          onPressed: _effectiveHasNext ? _handleNext : null,
                          icon: Icon(
                            widget.nextIcon,
                            size: 30.sp,
                            color: _effectiveHasNext
                                ? effectivePrimaryColor
                                : (isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade400),
                          ),
                        )
                      : null));

    // الإجراءات الإضافية (زر الأقسام وزر الرئيسية جوار أزرار التنقل)
    final effectiveCornerAction =
        widget.cornerWidget ??
        (widget.cornerAction != null
            ? _buildSideActionWidget(
                widget.cornerAction!,
                isDark,
                width: 40.w,
                height: 40.h,
                iconSize: 20.sp,
              )
            : null);

    final effectiveLeftCornerAction =
        widget.leftCornerWidget ??
        (widget.leftCornerAction != null
            ? _buildSideActionWidget(
                widget.leftCornerAction!,
                isDark,
                width: 40.w,
                height: 40.h,
                iconSize: 20.sp,
              )
            : null);

    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // المجموعة الأولى (اليمين في RTL: زر الأقسام ثم زر التالي)
    final firstGroup = isRtl
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (effectiveCornerAction != null) effectiveCornerAction,
              if (effectiveCornerAction != null && effectiveRightAction != null)
                SizedBox(width: 6.w),
              if (effectiveRightAction != null) effectiveRightAction,
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (effectiveLeftCornerAction != null) effectiveLeftCornerAction,
              if (effectiveLeftCornerAction != null &&
                  effectiveLeftAction != null)
                SizedBox(width: 6.w),
              if (effectiveLeftAction != null) effectiveLeftAction,
            ],
          );

    // المجموعة الثانية (اليسار في RTL: زر السابق ثم زر الرئيسية)
    final secondGroup = isRtl
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (effectiveLeftAction != null) effectiveLeftAction,
              if (effectiveLeftAction != null &&
                  effectiveLeftCornerAction != null)
                SizedBox(width: 6.w),
              if (effectiveLeftCornerAction != null) effectiveLeftCornerAction,
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (effectiveRightAction != null) effectiveRightAction,
              if (effectiveRightAction != null && effectiveCornerAction != null)
                SizedBox(width: 6.w),
              if (effectiveCornerAction != null) effectiveCornerAction,
            ],
          );

    final controlRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // المجموعة الجانبية الأولى
        firstGroup,

        SizedBox(width: 10.w),

        // زر التفاعل الدائري المركزي
        GestureDetector(
          onTap: _handleTap,
          child: AnimatedScale(
            scale: _buttonScale,
            duration: widget.scaleDuration,
            curve: Curves.easeOutBack,
            child: SizedBox(
              width: effectiveSize,
              height: effectiveSize,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // خلفية وظلال الزر
                  Container(
                    width: effectiveSize,
                    height: effectiveSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: effectiveButtonBg,
                      boxShadow: [
                        BoxShadow(
                          color: effectivePrimaryColor.withValues(
                            alpha: isDark ? 0.25 : 0.18,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),

                  // مؤشر التقدم الدائري أو المكون المخصص (مثل أنميشن المسبحة)
                  if (widget.customProgressRing != null)
                    IgnorePointer(
                      child: OverflowBox(
                        maxWidth: double.infinity,
                        maxHeight: double.infinity,
                        child: widget.customProgressRing!,
                      ),
                    )
                  else if (widget.showProgressRing)
                    CustomPaint(
                      size: Size(effectiveSize, effectiveSize),
                      painter: CircularCounterProgressPainter(
                        progress: _calculatedProgress,
                        strokeWidth: widget.strokeWidth,
                        backgroundColor: effectiveProgressBg,
                        progressColor: effectivePrimaryColor,
                      ),
                    ),

                  // محتوى الزر الداخلي
                  widget.centerChild ??
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.showCenterIcon) ...[
                            Icon(
                              widget.centerIcon,
                              size: 22.sp,
                              color: effectivePrimaryColor,
                            ),
                            SizedBox(height: 6.h),
                          ],
                          Text(
                            '$_effectiveCount',
                            style:
                                widget.countTextStyle ??
                                TextStyle(
                                  fontSize: effectiveCountFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: effectivePrimaryColor,
                                  fontFamily: 'Cairo',
                                ),
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(width: 15.w),

        // المجموعة الجانبية الثانية
        secondGroup,
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // صف أزرار التفاعل الموحد بالكامل
        controlRow,

        // المنطقة السفلية (التلميح وزر إعادة التعيين إن وُجدا)
        if (widget.bottomAction != null) ...[
          SizedBox(height: 8.h),
          widget.bottomAction!,
        ] else ...[
          if (widget.showHint && widget.hintText.isNotEmpty) ...[],
          if (widget.showResetButton && widget.onReset != null) ...[
            SizedBox(height: 4.h),
            TextButton.icon(
              onPressed: _handleReset,
              icon: Icon(
                widget.resetIcon,
                color: widget.resetColor,
                size: 12.sp,
              ),
              label: Text(
                widget.resetLabel,
                style: TextStyle(
                  fontSize: 8.sp,
                  color: widget.resetColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// [CircularCounterProgressPainter]
/// راسم مخصص لرسم إطار التقدم الدائري للعداد بسلاسة تامة.
class CircularCounterProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  CircularCounterProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // دائرة الخلفية غير المكتملة
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // قوس التقدم المكتمل
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CircularCounterProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}

/// اسم بديل للتوافق
typedef DhikrCounterControl = InteractiveCounterControl;
