import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:tarteel/core/theme/app_theme.dart';

/// tarteelAppBar
///
/// A flexible, production-ready AppBar designed for the tarteel app. Features:
/// - Works with light/dark themes defined in `AppTheme`/`AppColors`.
/// - Optional built-in bottom search bar (Arabic-friendly by default).
/// - Accepts custom `leading`, `actions`, or a full `title` widget.
/// - Implements `PreferredSizeWidget` so it can be used directly as `appBar:`.
///
class tarteelAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// A custom title widget. If provided, `titleText` is ignored.
  final Widget? titleWidget;

  /// A short title string. Used when `titleWidget` is null.
  final String? titleText;

  /// Optional leading widget (e.g., back button).
  final Widget? leading;

  /// Optional action widgets (icons, menus, etc.).
  final List<Widget>? actions;

  /// Whether title should be centered (default true for Arabic apps).
  final bool centerTitle;

  /// Optional background color; falls back to theme-aware surface color.
  final Color? backgroundColor;

  /// Optional shape for the app bar. By default it's a rounded bottom radius.
  final ShapeBorder? shape;

  /// Optional custom bottom. If provided, it takes precedence over `showSearch`.
  final PreferredSizeWidget? bottom;

  /// If true and `bottom` is null, shows a built-in search field in the bottom area.
  final bool showSearch;

  /// Controller for the built-in search field (if used).
  final TextEditingController? searchController;

  /// Called on each search text change.
  final ValueChanged<String>? onSearchChanged;

  /// Optional callback for verse search. If provided, a dedicated button appears next to search.
  final VoidCallback? onVerseSearchPressed;

  /// Hint text for the search field.
  final String? searchHint;

  /// Optional style for the title text.
  final TextStyle? titleTextStyle;

  /// Text alignment for the search field (use TextAlign.right for Arabic).
  final TextAlign searchTextAlign;

  /// Height of the built-in bottom area (default matches sample: 70).
  final double bottomHeight;

  /// Elevation of the bar.
  final double elevation;
  final double toolbarHeight;

  const tarteelAppBar({
    super.key,
    this.titleWidget,
    this.titleText,
    this.leading,
    this.actions,
    this.titleTextStyle,
    this.centerTitle = true,
    this.backgroundColor,
    this.shape,
    this.bottom,
    this.showSearch = false,
    this.searchController,
    this.onSearchChanged,
    this.onVerseSearchPressed,
    this.searchHint,
    this.searchTextAlign = TextAlign.right,
    this.bottomHeight = 70,
    this.elevation = 0,
    this.toolbarHeight = 70,
  });

  PreferredSizeWidget? get _effectiveBottom {
    if (bottom != null) return bottom;
    if (!showSearch) return null;

    return PreferredSize(
      preferredSize: Size.fromHeight(bottomHeight),
      child: Padding(
        padding: EdgeInsets.only(left: 10, top: 0, right: 10, bottom: 15),
        // fromLTRB(16, 0, 16, 12)
        child: _buildSearchContainer(),
      ),
    );
  }

  Widget _buildSearchContainer() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final fillColor =
            backgroundColor ??
            (isDark ? AppColors.darkSurface : AppColors.lightSurface);
        final prefixColor = isDark ? AppColors.goldAccent : AppColors.primary;
        final hintStyle = TextStyle(
          color: isDark
              ? AppColors.darkSecondaryText
              : AppColors.lightSecondaryText,
        );

        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextField(
                  controller: searchController,
                  textAlign: searchTextAlign,
                  onChanged: onSearchChanged,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: searchHint ?? 'ابحث...',
                    hintStyle: hintStyle,
                    prefixIcon: Icon(Icons.search, color: prefixColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 16.w,
                    ),
                  ),
                ),
              ),
            ),
            if (onVerseSearchPressed != null) ...[
              SizedBox(width: 8.w),
              Material(
                color: fillColor,
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  onTap: onVerseSearchPressed,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: prefixColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.manage_search_rounded,
                      color: prefixColor,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize {
    final double bottomPart = _effectiveBottom?.preferredSize.height ?? 0;
    return Size.fromHeight(toolbarHeight + bottomPart);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Widget? effectiveLeading =
        leading ??
        (Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null);

    return AppBar(
      title: Padding(
        padding: EdgeInsets.only(top: 20.h),
        child: Text(
          titleText!,
          style:
              (theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge)
                  ?.merge(titleTextStyle)
                  .copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
        ),
      ),

      leading: Padding(
        padding: EdgeInsets.only(top: 22.h),
        child: effectiveLeading,
      ),
      actions: actions?.map((action) => Padding(
                    padding: EdgeInsets.only(top: 20.h),
                    child: action,
                  ))
              .toList(),
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(showSearch ? 0 : 5.r),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/img/top_bar.png', fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.primary.withOpacity(0.70),
                    const Color.fromARGB(255, 93, 122, 31).withOpacity(0.30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(showSearch ? 20.r : 8.r),
        ),
      ),
      bottom: _effectiveBottom,
      iconTheme:
          Theme.of(context).appBarTheme.iconTheme ??
          IconThemeData(color: isDark ? AppColors.goldAccent : Colors.white),
      automaticallyImplyLeading: leading == null ? true : false,
    );
  }
}
