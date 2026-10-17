import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/dialogs/app_confirm_dialog.dart';

/// [BottomSheetItemAction]
/// تعريف لزر إجراء مسبق التصميم يظهر داخل عنصر القائمة (تعديل، حذف، نسخ، إلخ)
class BottomSheetItemAction {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String? tooltip;
  final bool isDestructive;
  final String? confirmTitle;
  final String? confirmMessage;

  const BottomSheetItemAction({
    required this.icon,
    required this.onTap,
    this.color,
    this.tooltip,
    this.isDestructive = false,
    this.confirmTitle,
    this.confirmMessage,
  });

  /// إنشاء زر حذف جاهز مع نافذة تأكيد تلقائية
  factory BottomSheetItemAction.delete({
    required VoidCallback onDelete,
    String? tooltip = 'حذف',
    String? confirmTitle = 'تأكيد الحذف',
    String? confirmMessage = 'هل أنت متأكد من الحذف؟',
  }) {
    return BottomSheetItemAction(
      icon: Icons.delete_outline_rounded,
      onTap: onDelete,
      color: Colors.red.shade700,
      tooltip: tooltip,
      isDestructive: true,
      confirmTitle: confirmTitle,
      confirmMessage: confirmMessage,
    );
  }

  /// إنشاء زر تعديل جاهز التصميم
  factory BottomSheetItemAction.edit({
    required VoidCallback onEdit,
    String? tooltip = 'تعديل',
  }) {
    return BottomSheetItemAction(
      icon: Icons.edit_outlined,
      onTap: onEdit,
      color: Colors.blue.shade700,
      tooltip: tooltip,
    );
  }
}

/// [BottomSheetItem]
/// نموذج بيانات موحد وجاهز لعناصر القوائم السفلية دون كتابة أي ويدجت أو أزرار يدوية
class BottomSheetItem {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final bool isSelected;
  final VoidCallback? onTap;
  final List<BottomSheetItemAction> actions;
  final Widget? leading;
  final Widget? trailing;

  const BottomSheetItem({
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.isSelected = false,
    this.onTap,
    this.actions = const [],
    this.leading,
    this.trailing,
  });
}

/// [AppModalBottomSheet]
/// مكون سفلي احترافي عام وموحد وعالي المرونة (UI & UX متميز)
/// يدعم نمط المصفوفات الجاهزة ([items])، ونمط القوائم المخصصة ([itemBuilder])،
/// ونمط النماذج والمحتوى المخصص ([child])، والأزرار المثبتة في الأسفل ([bottomWidget]).
class AppModalBottomSheet extends StatelessWidget {
  /// عنوان النافذة السفلية
  final String title;

  /// وصف أو تنبيه توضيحي اختياري أسفل العنوان
  final String? subtitle;

  /// أيقونة أو ويدجت إضافي في يسار شريط العنوان (مثل زر إضافة، زر إغلاق، إلخ)
  final Widget? trailing;

  /// ويدجت مخصص في يمين العنوان (بديل عن الشريط اللوني الافتراضي)
  final Widget? leading;

  /// نسبة ارتفاع النافذة من الشاشة (مثلاً 0.65 = 65% من الشاشة). إذا كان null يتكيف مع المحتوى
  final double? heightFraction;

  /// محتوى مخصص بالكامل (للنماذج، الإدخال، الحقول، إلخ)
  final Widget? child;

  /// مصفوفة عناصر جاهزة التصميم (الخيار الأسهل والأنظف بدون كتابة أي أزرار أو ويدجت يدوياً)
  final List<BottomSheetItem>? items;

  /// عدد عناصر القائمة (عند استخدام نمط القائمة المخصصة)
  final int? itemCount;

  /// باني عناصر القائمة المخصصة
  final IndexedWidgetBuilder? itemBuilder;

  /// فاصل بين عناصر القائمة
  final IndexedWidgetBuilder? separatorBuilder;

  /// ويدجت يظهر عند خلو القائمة
  final Widget? emptyWidget;

  /// رسالة نصية تظهر عند خلو القائمة
  final String? emptyMessage;

  /// مكون مثبت أسفل النافذة (مثل زر الحفظ أو أزرار التأكيد)
  final Widget? bottomWidget;

  /// هل يظهر مؤشر السحب الرمادي في الأعلى
  final bool showDragHandle;

  /// هل يظهر الشريط اللوني الرأسي بجانب العنوان
  final bool showPrimaryBar;

  /// هل يتم تغليف الـ child في SingleChildScrollView تلقائياً
  /// (اجعلها false إذا كان الـ child يحتوي على ListView أو Expanded خاص به)
  final bool wrapWithScrollView;

  /// حشوة داخلية للمحتوى
  final EdgeInsetsGeometry? contentPadding;

  const AppModalBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.heightFraction = 0.65,
    this.child,
    this.items,
    this.itemCount,
    this.itemBuilder,
    this.separatorBuilder,
    this.emptyWidget,
    this.emptyMessage = 'لا توجد بيانات حالياً',
    this.bottomWidget,
    this.showDragHandle = true,
    this.showPrimaryBar = true,
    this.wrapWithScrollView = true,
    this.contentPadding,
  });

  /// دالة مساعدة سريعة لفتح الشيت السفلية من أي مكان في التطبيق بسطر واحد وبأفضل إعدادات
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? trailing,
    Widget? leading,
    double? heightFraction = 0.65,
    Widget? child,
    List<BottomSheetItem>? items,
    int? itemCount,
    IndexedWidgetBuilder? itemBuilder,
    IndexedWidgetBuilder? separatorBuilder,
    Widget? emptyWidget,
    String? emptyMessage,
    Widget? bottomWidget,
    bool showDragHandle = true,
    bool showPrimaryBar = true,
    bool isDismissible = true,
    bool enableDrag = true,
    bool wrapWithScrollView = true,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => AppModalBottomSheet(
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        leading: leading,
        heightFraction: heightFraction,
        items: items,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: separatorBuilder,
        emptyWidget: emptyWidget,
        emptyMessage: emptyMessage,
        bottomWidget: bottomWidget,
        showDragHandle: showDragHandle,
        showPrimaryBar: showPrimaryBar,
        wrapWithScrollView: wrapWithScrollView,
        contentPadding: contentPadding,
        child: child,
      ),
    );
  }

  /// دالة مساعدة سريعة لإظهار نافذة تأكيد (حذف، إلغاء، خروج، إلخ) بتصميم موحد
  static Future<bool> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    Color? confirmColor,
    IconData? icon,
    bool isDestructive = false,
  }) {
    return AppConfirmDialog.show(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
      icon: icon,
      isDestructive: isDestructive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    // حساب الارتفاع الثابت أو المتجاوب
    final double? fixedHeight = heightFraction != null
        ? (mediaQuery.size.height * heightFraction!) +
              (keyboardHeight > 0 ? keyboardHeight * 0.5 : 0)
        : null;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Container(
        height: fixedHeight,
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.92),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: heightFraction == null
                ? MainAxisSize.min
                : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. مقبض السحب (Drag Handle)
              if (showDragHandle)
                Center(
                  child: Container(
                    width: 38.w,
                    height: 4.5.h,
                    margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),

              // 2. شريط العنوان التفاعلي
              Padding(
                padding: EdgeInsets.only(
                  top: showDragHandle ? 4.h : 16.h,
                  left: 16.w,
                  right: 16.w,
                  bottom: 8.h,
                ),
                child: Row(
                  children: [
                    // الشريط اللوني المميز للعنوان
                    if (leading != null)
                      leading!
                    else if (showPrimaryBar) ...[
                      Container(
                        width: 4.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],

                    // نص العنوان
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),

                    // الإجراء الجانبي (زر الإضافة، زر الإغلاق...)
                    if (trailing != null) trailing!,
                  ],
                ),
              ),

              // 3. التنبيه أو الوصف الفرعي (اختياري)
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 4.h,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.12 : 0.06,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: isDark
                              ? AppColors.goldAccent
                              : AppColors.primary,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : AppColors.primary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // فاصل خفيف
              Divider(
                height: 12.h,
                thickness: 0.8,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade200,
              ),

              // 4. المحتوى الرئيسي (سواءً قائمة أو محتوى مخصص)
              if (heightFraction != null)
                Expanded(
                  child: Padding(
                    padding: contentPadding ??
                        EdgeInsets.symmetric(horizontal: 16.w),
                    child: _buildBody(context, isDark),
                  ),
                )
              else
                Padding(
                  padding:
                      contentPadding ?? EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildBody(context, isDark),
                ),

              // 5. الويدجت المثبت في الأسفل (أزرار الحفظ أو الإجراءات)
              if (bottomWidget != null) ...[
                Container(
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    top: 10.h,
                    bottom: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.04,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: bottomWidget!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    // 1. إذا تم تمرير child مباشر (مثل النماذج)
    if (child != null) {
      if (wrapWithScrollView) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: 16.h),
          child: child!,
        );
      }
      return child!;
    }

    // 2. إذا تم تمرير مصفوفة عناصر جاهزة (items)
    if (items != null) {
      if (items!.isEmpty) {
        return _buildEmptyState();
      }
      return ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(top: 4.h, bottom: 16.h),
        itemCount: items!.length,
        separatorBuilder: (ctx, i) => SizedBox(height: 10.h),
        itemBuilder: (ctx, i) => _buildItemCard(ctx, items![i], isDark),
      );
    }

    // 3. إذا كانت القائمة المخصصة فارغة
    final effectiveCount = itemCount ?? 0;
    if (effectiveCount == 0) {
      return _buildEmptyState();
    }

    // 4. بناء القائمة المخصصة (itemBuilder)
    if (separatorBuilder != null) {
      return ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(top: 4.h, bottom: 16.h),
        itemCount: effectiveCount,
        separatorBuilder: separatorBuilder!,
        itemBuilder: itemBuilder!,
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: 4.h, bottom: 16.h),
      itemCount: effectiveCount,
      itemBuilder: itemBuilder!,
    );
  }

  Widget _buildEmptyState() {
    if (emptyWidget != null) return emptyWidget!;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 40.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 12.h),
            Text(
              emptyMessage ?? 'لا توجد بيانات حالياً',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    BottomSheetItem item,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: item.isSelected
            ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06)
            : (isDark ? const Color(0xFF1E2621) : Colors.white),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: item.isSelected
              ? AppColors.primary.withValues(alpha: 0.5)
              : (isDark ? Colors.white10 : Colors.grey.shade200),
          width: item.isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        onTap: item.onTap,
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isSelected ? FontWeight.bold : FontWeight.w600,
            color: item.isSelected
                ? AppColors.primary
                : (isDark ? Colors.white : Colors.black87),
            fontSize: 14.5.sp,
          ),
          textAlign: TextAlign.right,
        ),
        subtitle:
            item.subtitleWidget ??
            (item.subtitle != null
                ? Text(
                    item.subtitle!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.right,
                  )
                : null),
        leading:
            item.leading ??
            (item.actions.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: item.actions
                        .map((action) => _buildActionButton(context, action))
                        .toList(),
                  )
                : null),
        trailing: item.trailing,
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    BottomSheetItemAction action,
  ) {
    return IconButton(
      icon: Icon(action.icon, size: 20.sp, color: action.color),
      tooltip: action.tooltip,
      onPressed: () async {
        if (action.isDestructive) {
          final confirm = await AppConfirmDialog.show(
            context,
            title: action.confirmTitle ?? 'تأكيد الحذف',
            message: action.confirmMessage ?? 'هل أنت متأكد من الحذف؟',
            confirmText: 'حذف',
            isDestructive: true,
            icon: action.icon,
          );
          if (confirm) {
            action.onTap();
          }
        } else {
          action.onTap();
        }
      },
    );
  }
}
