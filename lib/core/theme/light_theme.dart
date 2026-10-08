import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Light theme for tarteel
///
/// Professional, minimal and calm visual language tuned for long reading
ThemeData buildLightTheme() {
  final ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    // Use surface/onSurface for modern ColorScheme (background/onBackground deprecated)
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightPrimaryText,
    // Define error colors explicitly
    error: const Color(0xFFB00020),
    onError: AppColors.white,
  );

  final base = ThemeData.light();

  return base.copyWith(
    // cardColor: AppColors.lightSecondaryText,
    // cardColor: AppColors.white,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.white,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      elevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.lightPrimaryText,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: AppColors.primary),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      shadowColor: AppColors.subtleShadow,
      margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
    ),

    // Text
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: AppColors.lightPrimaryText,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.lightPrimaryText,
        fontSize: 16.sp,
      ),
      bodyMedium: TextStyle(
        color: AppColors.lightSecondaryText,
        fontSize: 14.sp,
      ),
      labelLarge: TextStyle(
        color: AppColors.lightPrimaryText,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(color: AppColors.lightPrimaryText),
      titleSmall: TextStyle(color: AppColors.lightSecondaryText),
      displaySmall: TextStyle(color: AppColors.lightPrimaryText),
    ),

    // Elevated buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.primary),
        foregroundColor: WidgetStateProperty.all(AppColors.white),
        elevation: WidgetStateProperty.all(2),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
        ),
      ),
    ),

    // Outlined buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.primary),
        side: WidgetStateProperty.all(
          BorderSide(color: AppColors.primary.withOpacity(0.14)),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5.w),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFB00020)),
      ),
      labelStyle: TextStyle(color: AppColors.lightSecondaryText),
      hintStyle: TextStyle(color: AppColors.lightSecondaryText),
    ),

    // Bottom navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.lightSecondaryText,
      elevation: 6,
      type: BottomNavigationBarType.fixed,
    ),

    // Divider
    dividerColor: AppColors.lightBorder,

    // Icons
    iconTheme: const IconThemeData(color: AppColors.primary),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 4,
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.lightBorder;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withOpacity(0.22);
        }
        return AppColors.lightBorder.withOpacity(0.22);
      }),
    ),

    // SnackBars
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primary,
      contentTextStyle: TextStyle(color: AppColors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),

    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightSurface,
      titleTextStyle: TextStyle(
        color: AppColors.lightPrimaryText,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: AppColors.lightPrimaryText,
        fontSize: 14.sp,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
    ),
  );
}

final ThemeData lightTheme = buildLightTheme();
