import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tarteel/core/services/favorites_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/Text/Responsive_text.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_reader_cubit.dart';

/// [CardAction]
/// تعريف إجراء أو زر مخصص جاهز التصميم يوضع في شريط الإجراءات السفلي لـ [InteractiveContentCard].
class CardAction {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String tooltip;

  const CardAction({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.tooltip,
  });
}

/// [InteractiveContentCard]
/// بطاقة محتوى عامة، مرنة، واحترافية لعرض الأذكار، الأدعية، أسماء الله الحسنى،
/// الأحاديث، أو أي نصوص إسلامية تفاعلية.
class InteractiveContentCard extends StatefulWidget {
  /// النص الرئيسي المراد عرضه
  final String content;

  /// عنوان شارة الترتيب (مثل: "الذكر 1"، "الدعاء 3"، "الاسم 5")
  final String? indexLabel;

  /// هل تظهر شارة الترتيب في الأعلى
  final bool showIndexLabel;

  /// حجم خط النص الأقصى الحالي (اختياري: إن لم يُمرر يتم جلبه تلقائياً من الكيوبت)
  final double? fontSize;

  /// خطوة تكبير/تصغير الخط (افتراضياً 2.0)
  final double fontStep;

  /// الحد الأدنى لحجم الخط
  final double minFontSize;

  /// الحد الأقصى لحجم الخط
  final double maxFontSize;

  /// حدث عند تكبير الخط
  final VoidCallback? onZoomIn;

  /// حدث عند تصغير الخط
  final VoidCallback? onZoomOut;

  /// هل تظهر أزرار التكبير والتصغير
  final bool showZoomControls;

  /// حالة المفضلة (اختياري، إن لم تُمرر يفحص المكون المفضلة تلقائياً من الذاكرة)
  final bool? isFavorite;

  /// حدث التبديل عند الضغط على زر المفضلة (اختياري، إن لم يُمرر يحفظ تلقائياً في المفضلة)
  final VoidCallback? onFavoriteToggle;

  /// نوع المفضلة (مثل 'azkar' أو 'hisn' - افتراضياً 'azkar' لربطها بصفحة المحفوظات)
  final String favoriteType;

  /// المعرف الفريد للذكر في المفضلة (اختياري، إن لم يُمرر يعتمد على النص تلقائياً)
  final String? favoriteKey;

  /// عنوان القسم في المفضلة
  final String? favoriteTitle;

  /// هل يظهر زر المفضلة
  final bool showFavorite;

  /// فضل الذكر أو شرحه أو معناه (اختياري)
  final String? description;

  /// المصدر أو التخريج (اختياري)
  final String? reference;

  /// حدث النسخ المخصص (إذا كان null، يقوم بنسخ النص تلقائياً)
  final VoidCallback? onCopy;

  /// هل يظهر زر النسخ
  final bool showCopy;

  /// حدث المشاركة المخصص (إذا كان null، يقوم بالمشاركة تلقائياً)
  final VoidCallback? onShare;

  /// هل يظهر زر المشاركة
  final bool showShare;

  /// نص شارة التكرار أو الهدف (مثل: "التكرار : 3 / 33")
  final String? counterBadgeText;

  /// هل تظهر شارة التكرار
  final bool showCounterBadge;

  /// قائمة أزرار مخصصة تمرر كبيانات فقط [CardAction] ويتم تصميمها آلياً بنفس مظهر المكون
  final List<CardAction>? customActions;

  /// قائمة أزرار ويدجت إضافية حرة في الشريط السفلي
  final List<Widget>? extraActions;

  /// إضافة محتوى مخصص بالكامل (مثل صورة أو أنميشن) يعرض بدلاً من النص أو مع النص
  final Widget? customBody;

  /// مكون إضافي يوضع في شريط الرأس بجانب أدوات التكبير (مثل أزرار التحكم بالصوت والاهتزاز)
  final Widget? headerTrailing;

  /// حشوة داخلية مخصصة
  final EdgeInsetsGeometry? padding;

  /// حشوة خارجية مخصصة
  final EdgeInsetsGeometry? margin;

  /// ارتفاع محدد للبطاقة (اختياري)
  final double? height;

  /// هل تتمدد البطاقة لملء المساحة المتاحة
  final bool? isExpanded;

  const InteractiveContentCard({
    super.key,
    required this.content,
    this.indexLabel,
    this.showIndexLabel = true,
    this.fontSize,
    this.fontStep = 2.0,
    this.minFontSize = 12.0,
    this.maxFontSize = 36.0,
    this.onZoomIn,
    this.onZoomOut,
    this.showZoomControls = true,
    this.isFavorite,
    this.onFavoriteToggle,
    this.favoriteType = 'azkar',
    this.favoriteKey,
    this.favoriteTitle,
    this.showFavorite = true,
    this.description,
    this.reference,
    this.onCopy,
    this.showCopy = true,
    this.onShare,
    this.showShare = true,
    this.counterBadgeText,
    this.showCounterBadge = true,
    this.customActions,
    this.extraActions,
    this.customBody,
    this.headerTrailing,
    this.padding,
    this.margin,
    this.height,
    this.isExpanded,
  });

  @override
  State<InteractiveContentCard> createState() => _InteractiveContentCardState();
}

class _InteractiveContentCardState extends State<InteractiveContentCard> {
  bool _isFavorite = false;

  ReaderCubitContract? get _cubit => findReaderCubit(context);

  double get _effectiveFontSize =>
      widget.fontSize ?? _cubit?.fontSize ?? 20.0;

  String? get _effectiveCounterBadgeText {
    if (widget.counterBadgeText != null) return widget.counterBadgeText;
    final cubit = _cubit;
    if (cubit != null && cubit.currentTargetRepeat > 0) {
      return 'التكرار  : ${cubit.currentCount} / ${cubit.currentTargetRepeat}';
    }
    return null;
  }

  String? get _effectiveFavoriteTitle =>
      widget.favoriteTitle ?? _cubit?.title;

  void _handleZoomIn() {
    if (widget.onZoomIn != null) {
      widget.onZoomIn!();
    } else {
      _cubit?.zoomIn();
    }
  }

  void _handleZoomOut() {
    if (widget.onZoomOut != null) {
      widget.onZoomOut!();
    } else {
      _cubit?.zoomOut();
    }
  }

  String get _effectiveKey =>
      widget.favoriteKey ?? widget.content.trim().hashCode.toString();

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  @override
  void didUpdateWidget(covariant InteractiveContentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.favoriteKey != widget.favoriteKey ||
        oldWidget.isFavorite != widget.isFavorite) {
      _checkFavorite();
    }
  }

  Future<void> _checkFavorite() async {
    if (widget.isFavorite != null) {
      setState(() => _isFavorite = widget.isFavorite!);
      return;
    }

    final fav = await FavoritesService.isFavorite(
      type: widget.favoriteType,
      key: _effectiveKey,
    );
    if (mounted) {
      setState(() => _isFavorite = fav);
    }
  }

  Future<void> _handleFavoriteToggle() async {
    HapticFeedback.lightImpact();
    if (widget.onFavoriteToggle != null) {
      widget.onFavoriteToggle!();
      return;
    }

    final added = await FavoritesService.toggleFavorite(
      type: widget.favoriteType,
      key: _effectiveKey,
      content: widget.content,
      title: _effectiveFavoriteTitle ?? widget.indexLabel,
      description: widget.description,
      reference: widget.reference,
    );

    if (mounted) {
      setState(() => _isFavorite = added);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added
                ? 'تمت إضافة الذكر إلى المحفوظات'
                : 'تمت إزالة الذكر من المحفوظات',
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget contentBody = Directionality(
      textDirection: TextDirection.rtl,
      child: Scrollbar(
        thumbVisibility: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // SizedBox(height: 5.h),
              if (widget.customBody != null) widget.customBody!,
              if (widget.content.isNotEmpty)
                ResponsiveText(
                  content: widget.content,
                  fontSize: _effectiveFontSize,
                  maxFontSize: widget.maxFontSize,
                  minFontSize: widget.minFontSize,
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  height: 2.2,
                  textAlign: TextAlign.center,
                  maxLines: null,
                  overflow: TextOverflow.visible,
                  textDirection: TextDirection.rtl,
                  color: isDark ? Colors.white : const Color(0xFF2E5C2E),
                ),

              // فضل الذكر / الشرح (إن وجد)
              if (widget.description != null &&
                  widget.description!.trim().isNotEmpty) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.15),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    widget.description!,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
              ],

              // المصدر / التخريج (إن وجد)
              if (widget.reference != null &&
                  widget.reference!.trim().isNotEmpty) ...[
                SizedBox(height: 12.h),
                Text(
                  'المصدر: ${widget.reference!}',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                    // fontFamily: 'Cairo',
                  ),
                ),
              ],
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // إذا كان هناك قيود ارتفاع محددة أو تم طلب isExpanded صراحة
        final bool shouldExpand =
            widget.isExpanded ??
            (constraints.maxHeight != double.infinity && widget.height == null);

        return Container(
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2621) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.subtleShadow,
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.grey.shade900
                  : AppColors.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Padding(
            padding:
                widget.padding ??
                EdgeInsets.only(
                  top: 10.h,
                  bottom: 10.h,
                  left: 15.w,
                  right: 15.w,
                ),
            child: Column(
              mainAxisSize: shouldExpand ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. شريط الرأس: الفهرس + المفضلة + أدوات التكبير
                _buildHeader(context, isDark),

                // 2. منطقة عرض النص
                if (shouldExpand)
                  Expanded(child: contentBody)
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 280.h),
                    child: contentBody,
                  ),

                SizedBox(height: 12.h),

                // 3. شريط الإجراءات السفلي (النسخ، المشاركة، شارة التكرار)
                _buildFooterActions(context, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final hasHeaderElements =
        (widget.showIndexLabel && widget.indexLabel != null) ||
        widget.showZoomControls ||
        widget.headerTrailing != null;

    if (!hasHeaderElements) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // شارة الفهرس أو الترتيب
        if (widget.showIndexLabel && widget.indexLabel != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              widget.indexLabel!,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
          )
        else
          const SizedBox.shrink(),

        // الجانب الأيسر للرأس: أدوات التحكم المخصصة + أدوات التكبير والتصغير
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.headerTrailing != null) ...[
              widget.headerTrailing!,
              if (widget.showZoomControls) SizedBox(width: 8.w),
            ],
            if (widget.showZoomControls)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    _buildZoomButton(
                      Icons.zoom_in_rounded,
                      _handleZoomIn,
                      'تكبير الخط',
                    ),
                    Container(
                      width: 1.w,
                      height: 20.h,
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    _buildZoomButton(
                      Icons.zoom_out_rounded,
                      _handleZoomOut,
                      'تصغير الخط',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback? onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            HapticFeedback.lightImpact();
            onTap();
          }
        },
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          child: Icon(icon, size: 22.sp, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context, bool isDark) {
    final badgeText = _effectiveCounterBadgeText;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          // الجانب الأيسر الثابت دائماً: أزرار النسخ والمشاركة والمفضلة والإجراءات المخصصة
          if (widget.showCopy)
            _buildActionButton(
              icon: Icons.copy_rounded,
              onTap: () {
                if (widget.onCopy != null) {
                  widget.onCopy!();
                } else {
                  _defaultCopy(context);
                }
              },
              color: Colors.blue.shade700,
              tooltip: 'نسخ النص',
            ),
          if (widget.showCopy &&
              (widget.showShare ||
                  widget.showFavorite ||
                  (widget.extraActions != null &&
                      widget.extraActions!.isNotEmpty)))
            SizedBox(width: 8.w),
          if (widget.showShare)
            _buildActionButton(
              icon: Icons.share_rounded,
              onTap: () {
                if (widget.onShare != null) {
                  widget.onShare!();
                } else {
                  _defaultShare(context);
                }
              },
              color: AppColors.primary,
              tooltip: 'مشاركة',
            ),
          if (widget.showShare &&
              (widget.showFavorite ||
                  (widget.extraActions != null &&
                      widget.extraActions!.isNotEmpty)))
            SizedBox(width: 8.w),
          if (widget.showFavorite)
            _buildActionButton(
              icon: _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              onTap: _handleFavoriteToggle,
              color: _isFavorite ? Colors.redAccent : Colors.grey.shade600,
              tooltip: _isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
            ),
          // أزرار مخصصة ممررة كمصفوفة بيانات CardAction
          if (widget.customActions != null)
            for (final action in widget.customActions!) ...[
              if (widget.showCopy ||
                  widget.showShare ||
                  widget.showFavorite ||
                  widget.customActions!.indexOf(action) > 0)
                SizedBox(width: 8.w),
              _buildActionButton(
                icon: action.icon,
                onTap: action.onTap,
                color: action.color,
                tooltip: action.tooltip,
              ),
            ],

          if (widget.extraActions != null) ...[
            if (widget.showCopy ||
                widget.showShare ||
                widget.showFavorite ||
                (widget.customActions != null &&
                    widget.customActions!.isNotEmpty))
              SizedBox(width: 8.w),
            ...widget.extraActions!,
          ],

          const Spacer(),

          // الجانب الأيمن: شارة التكرار (إن وجدت)
          if (widget.showCounterBadge && badgeText != null && badgeText.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(40.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
      ),
    );
  }

  void _defaultCopy(BuildContext context) {
    final buffer = StringBuffer(widget.content);
    if (widget.description != null && widget.description!.trim().isNotEmpty) {
      buffer.write('\n\nفضل الذكر: ${widget.description!.trim()}');
    }
    if (widget.reference != null && widget.reference!.trim().isNotEmpty) {
      buffer.write('\nالمصدر: ${widget.reference!.trim()}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم النسخ بنجاح',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _defaultShare(BuildContext context) {
    final buffer = StringBuffer(widget.content);
    if (widget.description != null && widget.description!.trim().isNotEmpty) {
      buffer.write('\n\nفضل الذكر: ${widget.description!.trim()}');
    }
    if (widget.reference != null && widget.reference!.trim().isNotEmpty) {
      buffer.write('\nالمصدر: ${widget.reference!.trim()}');
    }
    buffer.write('\n\nتمت المشاركة من تطبيق ترتيل');

    HapticFeedback.lightImpact();
    Share.share(buffer.toString());
  }
}
