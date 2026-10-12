import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/Text/Responsive_text.dart';

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
///
/// المميزات:
/// 1. رأس البطاقة: شارة الفهرس/الترتيب، أزرار تكبير وتصغير حجم الخط.
/// 2. جسم البطاقة: عرض النص بخط أميري أصيل وتمرير ناعم لمنع أي Overflow،
///    مع دعم صندوق الفضل/الشرح وصندوق المصدر/التخريج.
/// 3. شريط الإجراءات السفلي: أزرار النسخ والمشاركة والمفضلة وشارة التكرار مع إمكانية إضافة أزرار مخصصة عبر قائمة [customActions].
/// 4. التحكم الكامل في إظهار أو إخفاء أي عنصر (`showZoomControls`, `showFavorite`, `showCopy`, `showShare`, `showCounterBadge`).
class InteractiveContentCard extends StatelessWidget {
  /// النص الرئيسي المراد عرضه
  final String content;

  /// عنوان شارة الترتيب (مثل: "الذكر 1"، "الدعاء 3"، "الاسم 5")
  final String? indexLabel;

  /// هل تظهر شارة الترتيب في الأعلى
  final bool showIndexLabel;

  /// حجم خط النص الأقصى الحالي
  final double fontSize;

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

  /// حالة المفضلة (هل العنصر في المفضلة)
  final bool isFavorite;

  /// حدث التبديل عند الضغط على زر المفضلة
  final VoidCallback? onFavoriteToggle;

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

  /// حدث المشاركة المخصص
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

  /// هل تتمدد البطاقة لملء المساحة المتاحة (افتراضياً true للشاشات التي تستخدم Expanded/PageView)
  /// اضبطها على false عندما توضع البطاقة داخل SingleChildScrollView لمنع خطأ RenderBox hasSize
  final bool? isExpanded;

  const InteractiveContentCard({
    super.key,
    required this.content,
    this.indexLabel,
    this.showIndexLabel = true,
    this.fontSize = 20.0,
    this.fontStep = 2.0,
    this.minFontSize = 12.0,
    this.maxFontSize = 36.0,
    this.onZoomIn,
    this.onZoomOut,
    this.showZoomControls = true,
    this.isFavorite = false,
    this.onFavoriteToggle,
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget contentBody = Scrollbar(
      thumbVisibility: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 8.h),
            if (customBody != null) customBody!,
            if (content.isNotEmpty)
              ResponsiveText(
                content: content,
                fontSize: fontSize,
                maxFontSize: maxFontSize,
                minFontSize: minFontSize,
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                height: 2.2,
                textAlign: TextAlign.center,
                maxLines: null,
                overflow: TextOverflow.visible,
                color: isDark ? Colors.white : const Color(0xFF2E5C2E),
              ),

            // فضل الذكر / الشرح (إن وجد)
            if (description != null && description!.trim().isNotEmpty) ...[
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
                  description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
            ],

            // المصدر / التخريج (إن وجد)
            if (reference != null && reference!.trim().isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(
                'المصدر: $reference',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // إذا كان هناك قيود ارتفاع محددة أو تم طلب isExpanded صراحة
        final bool shouldExpand =
            isExpanded ??
            (constraints.maxHeight != double.infinity && height == null);

        return Container(
          height: height,
          margin: margin,
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
                padding ??
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
        (showIndexLabel && indexLabel != null) ||
        showZoomControls ||
        headerTrailing != null;

    if (!hasHeaderElements) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // شارة الفهرس أو الترتيب
        if (showIndexLabel && indexLabel != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              indexLabel!,
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
            if (headerTrailing != null) ...[
              headerTrailing!,
              if (showZoomControls) SizedBox(width: 8.w),
            ],
            if (showZoomControls)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    _buildZoomButton(
                      Icons.zoom_in_rounded,
                      onZoomIn,
                      'تكبير الخط',
                    ),
                    Container(
                      width: 1.w,
                      height: 20.h,
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    _buildZoomButton(
                      Icons.zoom_out_rounded,
                      onZoomOut,
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
    final hasBadge =
        showCounterBadge &&
        counterBadgeText != null &&
        counterBadgeText!.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          // الجانب الأيسر الثابت دائماً: أزرار النسخ والمشاركة والمفضلة والإجراءات المخصصة
          if (showCopy)
            _buildActionButton(
              icon: Icons.copy_rounded,
              onTap: () {
                if (onCopy != null) {
                  onCopy!();
                } else {
                  _defaultCopy(context);
                }
              },
              color: Colors.blue.shade700,
              tooltip: 'نسخ النص',
            ),
          if (showCopy &&
              (showShare ||
                  showFavorite ||
                  (extraActions != null && extraActions!.isNotEmpty)))
            SizedBox(width: 8.w),
          if (showShare)
            _buildActionButton(
              icon: Icons.share_rounded,
              onTap: () {
                if (onShare != null) {
                  onShare!();
                } else {
                  _defaultShare(context);
                }
              },
              color: AppColors.primary,
              tooltip: 'مشاركة',
            ),
          if (showShare &&
              (showFavorite ||
                  (extraActions != null && extraActions!.isNotEmpty)))
            SizedBox(width: 8.w),
          if (showFavorite)
            _buildActionButton(
              icon: isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              onTap: () {
                onFavoriteToggle?.call();
              },
              color: isFavorite ? Colors.redAccent : Colors.grey.shade600,
              tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
            ),
          // أزرار مخصصة ممررة كمصفوفة بيانات CardAction
          if (customActions != null)
            for (final action in customActions!) ...[
              if (showCopy ||
                  showShare ||
                  showFavorite ||
                  customActions!.indexOf(action) > 0)
                SizedBox(width: 8.w),
              _buildActionButton(
                icon: action.icon,
                onTap: action.onTap,
                color: action.color,
                tooltip: action.tooltip,
              ),
            ],

          if (extraActions != null) ...[
            if (showCopy ||
                showShare ||
                showFavorite ||
                (customActions != null && customActions!.isNotEmpty))
              SizedBox(width: 8.w),
            ...extraActions!,
          ],

          const Spacer(),

          // الجانب الأيمن: شارة التكرار (إن وجدت)
          if (hasBadge)
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
                  counterBadgeText!,
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
    final buffer = StringBuffer(content);
    if (description != null && description!.trim().isNotEmpty) {
      buffer.write('\n\nفضل الذكر: ${description!.trim()}');
    }
    if (reference != null && reference!.trim().isNotEmpty) {
      buffer.write('\nالمصدر: ${reference!.trim()}');
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
    final buffer = StringBuffer(content);
    if (description != null && description!.trim().isNotEmpty) {
      buffer.write('\n\nفضل الذكر: ${description!.trim()}');
    }
    if (reference != null && reference!.trim().isNotEmpty) {
      buffer.write('\nالمصدر: ${reference!.trim()}');
    }
    buffer.write('\n\nتمت المشاركة من تطبيق ترتيل');

    HapticFeedback.lightImpact();
    Share.share(buffer.toString());
  }
}
