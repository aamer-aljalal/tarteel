/// وصف الملف:
/// هذا الملف يحتوي على عنصر `AccessListGrid` وهو عبارة عن شبكة عرض (Grid) مخصصة ومتجاوبة
/// لعرض خيارات الوصول السريع للأقسام المختلفة في التطبيق (مثل القرآن، حصن المسلم، الأذكار، إلخ).
///
/// عمل الملف:
/// - استقبال قائمة من موديلات `AccessListModel` التي تحتوي على الأيقونة والعنوان ومسار الصفحة المحددة.
/// - بناء وتنسيق العناصر بشكل شبكي يتناسب مع أحجام الشاشات المختلفة ودعم المظهرين (النهاري والليلي).
/// - تشغيل حركة دخول متحركة ومتدرجة لكل عنصر بشكل تصاعدي (Staggered Entrance Animation)
///   مع حماية التطبيق من الانهيار عند وجود عدد كبير من العناصر عن طريق تحديد حد أقصى لتأخير الأنيميشن.
library;

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/theme/app_radius.dart';

/// نمط عرض القائمة: إما شبكة مربعات (الافتراضي) أو مستطيلات تأخذ كامل عرض الصف
enum AccessListDisplayMode {
  grid, // مربعات (الوضع الافتراضي)
  rectangle, // مستطيل يأخذ الصف بالكامل
}

class AccessListGrid extends StatelessWidget {
  final List<AccessListModel> actions;
  final AnimationController? controller;

  /// نمط العرض: مربعات (الافتراضي) أو مستطيل
  final AccessListDisplayMode displayMode;

  /// باراميتر اختياري وسريع لتحديد الشكل المستطيل مباشرة (isRectangle: true)
  final bool? isRectangle;

  /// حالة تحميل البيانات: عند تفعيلها وقائمة العناصر فارغة يتم عرض CircularProgressIndicator
  final bool isLoading;

  /// اتجاه النص والعرض (الافتراضي: TextDirection.rtl من اليمين لليسار)
  final TextDirection textDirection;

  /// الهوامش الداخلية (الافتراضي: 20 من الجوانب و 20 من الأعلى والأسفل)
  final EdgeInsetsGeometry? padding;

  /// إمكانية التمرير: افتراضياً مفعلة تلقائياً (SingleChildScrollView) ما لم يكن المكون داخل ScrollView خارجي
  final bool? isScrollable;

  /// فيزياء التمرير (الافتراضي: BouncingScrollPhysics)
  final ScrollPhysics physics;

  /// دالة نقر مخصصة (إن لم تُمرر، يتم الانتقال تلقائياً إلى مسار item.route)
  final void Function(AccessListModel item)? onItemTap;

  /// عنوان العنصر المحدد حالياً لإبرازه وتمييزه (مثل القسم النشط في القائمة السفلية)
  final String? selectedTitle;

  /// دالة مخصصة للتحقق من تحديد العنصر
  final bool Function(AccessListModel item)? isSelected;

  const AccessListGrid({
    super.key,
    required this.actions,
    this.controller,
    this.displayMode = AccessListDisplayMode.grid,
    this.isRectangle,
    this.isLoading = false,
    this.textDirection = TextDirection.rtl,
    this.padding,
    this.isScrollable,
    this.physics = const BouncingScrollPhysics(),
    this.onItemTap,
    this.selectedTitle,
    this.isSelected,
  });

  /// التحقق مما إذا كان العرض المطلوب هو الشكل المستطيل
  bool get _isRectangleMode =>
      isRectangle ?? (displayMode == AccessListDisplayMode.rectangle);

  bool _checkIsSelected(AccessListModel item) {
    if (isSelected != null) return isSelected!(item);
    if (selectedTitle != null) return item.title == selectedTitle;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);

    // الهوامش الافتراضية: 20 من الجوانب و 20 من الأعلى والأسفل (أو ما يمرره المبرمج)
    final effectivePadding =
        padding ?? EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 20.0.h);

    Widget content;

    // حالة التحميل: عندما تكون البيانات قيد الجلب والقائمة فارغة
    if (isLoading && actions.isEmpty) {
      content = Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Center(
          child: CircularProgressIndicator(
            color: brightness == Theme.of(context).brightness
                ? AppColors.goldAccent
                : AppColors.primary,
          ),
        ),
      );
    } else if (_isRectangleMode) {
      // 1. العرض المستطيل (يأخذ الصف بالكامل ويعرض الأيقونة والعنوان والتفاصيل إن وجدت)
      content = ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (context, index) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final item = actions[index];

          final itemWidget = GestureDetector(
            onTap: () {
              if (onItemTap != null) {
                onItemTap!(item);
              } else {
                Navigator.pushNamed(
                  context,
                  item.route,
                  arguments: item.arguments,
                );
              }
            },
            child: _buildRectangleCard(
              context,
              item,
              brightness,
              isSelected: _checkIsSelected(item),
            ),
          );

          if (controller == null) {
            return itemWidget;
          }

          final animationDelay = ((index % 9) * 0.04).clamp(0.0, 0.4);
          final animation = CurvedAnimation(
            parent: controller!,
            curve: Interval(animationDelay, 1.0, curve: Curves.easeOutCubic),
          );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.6),
                end: Offset.zero,
              ).animate(animation),
              child: itemWidget,
            ),
          );
        },
      );
    } else {
      // 2. العرض الشبكي الافتراضي (مربعات متناسقة 100% كما هي دون أي تغيير)
      content = GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),

        itemCount: actions.length,
        itemBuilder: (context, index) {
          final item = actions[index];

          final itemWidget = GestureDetector(
            onTap: () {
              if (onItemTap != null) {
                onItemTap!(item);
              } else {
                Navigator.pushNamed(
                  context,
                  item.route,
                  arguments: item.arguments,
                );
              }
            },
            child: _buildItemCard(
              context,
              item,
              brightness,
              isSelected: _checkIsSelected(item),
            ),
          );

          if (controller == null) {
            return itemWidget;
          }

          // تحسين الأداء للقوائم الطويلة (مثل حصن المسلم 130 باباً):
          // نقصر تأخير الأنيميشن على أول 9 عناصر فقط لكي تظهر الشاشة فوراً دون انتظار تراكم التأخير
          final animationDelay = ((index % 9) * 0.04).clamp(0.0, 0.4);
          final animation = CurvedAnimation(
            parent: controller!,
            curve: Interval(animationDelay, 1.0, curve: Curves.easeOutCubic),
          );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.6),
                end: Offset.zero,
              ).animate(animation),
              child: itemWidget,
            ),
          );
        },
      );
    }

    // تحديد ما إذا كان التمرير يجب أن يكون مفعّلاً في المكون
    final bool hasAncestorScrollable = Scrollable.maybeOf(context) != null;
    final bool shouldScroll = isScrollable ?? (!hasAncestorScrollable);

    final Widget body = shouldScroll
        ? SingleChildScrollView(
            physics: physics,
            padding: effectivePadding,
            child: content,
          )
        : Padding(padding: effectivePadding, child: content);

    // تطبيق اتجاه العرض (RTL افتراضياً)
    return Directionality(textDirection: textDirection, child: body);
  }

  Widget _buildItemCard(
    BuildContext context,
    AccessListModel item,
    Brightness brightness, {
    bool isSelected = false,
  }) {
    final isDark = brightness == Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? AppColors.goldAccent
              : (isDark ? AppColors.primary : AppColors.lightSecondaryText),
          width: isSelected ? 2.5.w : 2.w,
        ),
        color: isSelected
            ? AppColors.goldAccent.withValues(alpha: isDark ? 0.22 : 0.12)
            : (isDark
                  ? Colors.black.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.80)),
        borderRadius: BorderRadius.circular(AppRadius.small),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.goldAccent.withValues(alpha: 0.25)
                : AppColors.lightSecondaryText.withValues(alpha: 0.2),
            blurRadius: isSelected ? 8 : 5,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.goldAccent),
              color: isSelected
                  ? AppColors.goldAccent.withValues(alpha: 0.25)
                  : (isDark
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : AppColors.primary.withValues(alpha: 0.22)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 20.sp,
              color: isSelected ? AppColors.goldAccent : AppColors.greenBorder,
            ),
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 7.w),
              child: AutoSizeText(
                item.title,
                maxLines: 2,
                minFontSize: 9,
                maxFontSize: 15,
                stepGranularity: 0.5,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14.sp,
                  color: isSelected
                      ? (isDark ? AppColors.goldAccent : AppColors.primary)
                      : (isDark ? AppColors.goldAccent : AppColors.black),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontFamily: 'Amiri',
                ),
              ),
            ),
          ),
          SizedBox(height: 5.h),
        ],
      ),
    );
  }

  /// بناء العنصر عندما يكون بالشكل المستطيل (يأخذ عرض الصف كاملاً مع الأيقونة والعنوان والتفاصيل)
  Widget _buildRectangleCard(
    BuildContext context,
    AccessListModel item,
    Brightness brightness, {
    bool isSelected = false,
  }) {
    final isDark = brightness == Theme.of(context).brightness;
    final bool hasDetails =
        item.details != null && item.details!.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? AppColors.goldAccent
              : (isDark ? AppColors.primary : AppColors.lightSecondaryText),
          width: isSelected ? 2.5.w : 2.w,
        ),
        color: isSelected
            ? AppColors.goldAccent.withValues(alpha: isDark ? 0.22 : 0.12)
            : (isDark
                  ? Colors.black.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.80)),
        borderRadius: BorderRadius.circular(AppRadius.small),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.goldAccent.withValues(alpha: 0.25)
                : AppColors.lightSecondaryText.withValues(alpha: 0.2),
            blurRadius: isSelected ? 8 : 5,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.goldAccent),
              color: isSelected
                  ? AppColors.goldAccent.withValues(alpha: 0.25)
                  : (isDark
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : AppColors.primary.withValues(alpha: 0.22)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 22.sp,
              color: isSelected ? AppColors.goldAccent : AppColors.greenBorder,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15.sp,
                    color: isSelected
                        ? (isDark ? AppColors.goldAccent : AppColors.primary)
                        : (isDark ? AppColors.goldAccent : AppColors.black),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    fontFamily: 'Amiri',
                  ),
                ),
                if (hasDetails) ...[
                  SizedBox(height: 4.h),
                  Text(
                    item.details!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12.sp,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.lightSecondaryText,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Icon(
            isSelected
                ? Icons.check_circle_rounded
                : Icons.arrow_forward_ios_rounded,
            size: isSelected ? 18.sp : 14.sp,
            color: isSelected
                ? AppColors.goldAccent
                : (isDark
                      ? AppColors.goldAccent.withValues(alpha: 0.6)
                      : AppColors.lightSecondaryText.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
