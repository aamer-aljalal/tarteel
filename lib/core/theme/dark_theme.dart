import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Dark theme for tarteel
///
/// AMOLED-friendly, calm and minimal dark visuals tuned for comfortable night reading.
ThemeData buildDarkTheme() {
  final ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.darkSurface,
    secondary: AppColors.secondary,
    onSecondary: AppColors.darkSurface,
    // Prefer surface/onSurface for modern ColorScheme
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkPrimaryText,
    error: const Color(0xFFCF6679),
    onError: AppColors.darkSurface,
  );

  final base = ThemeData.dark();

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.darkBackground,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      elevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.darkPrimaryText,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: AppColors.goldAccent),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      shadowColor: AppColors.subtleShadow,
      margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
    ),

    // Text
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: AppColors.darkPrimaryText,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: AppColors.darkPrimaryText, fontSize: 16.sp),
      bodyMedium: TextStyle(color: AppColors.darkSecondaryText, fontSize: 14.sp),
      labelLarge: TextStyle(
        color: AppColors.darkPrimaryText,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(color: AppColors.darkPrimaryText),
      titleSmall: TextStyle(color: AppColors.darkSecondaryText),
      displaySmall: TextStyle(color: AppColors.darkPrimaryText),
    ),

    // Elevated buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.primary),
        foregroundColor: WidgetStateProperty.all(AppColors.darkSurface),
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
          BorderSide(color: AppColors.darkBorder.withOpacity(0.18)),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.goldAccent, width: 1.5.w),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFCF6679)),
      ),
      labelStyle: TextStyle(color: AppColors.darkSecondaryText),
      hintStyle: TextStyle(color: AppColors.darkSecondaryText),
    ),

    // Bottom navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.goldAccent,
      unselectedItemColor: AppColors.darkSecondaryText,
      elevation: 6,
      type: BottomNavigationBarType.fixed,
    ),

    // Divider
    dividerColor: AppColors.darkBorder,

    // Icons
    iconTheme: const IconThemeData(color: AppColors.goldAccent),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.goldAccent,
      foregroundColor: AppColors.darkSurface,
      elevation: 4,
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.goldAccent;
        }
        return AppColors.darkBorder;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.goldAccent.withOpacity(0.22);
        }
        return AppColors.darkBorder.withOpacity(0.22);
      }),
    ),

    // SnackBars
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface,
      contentTextStyle: TextStyle(color: AppColors.darkPrimaryText),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),

    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      titleTextStyle: TextStyle(
        color: AppColors.darkPrimaryText,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: AppColors.darkPrimaryText,
        fontSize: 14.sp,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
    ),
  );
}

final ThemeData darkTheme = buildDarkTheme();
