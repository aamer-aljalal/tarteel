import 'package:flutter/material.dart';
import 'package:tarteel/Routes/AppRoutes.dart';
import 'package:tarteel/Routes/RouteGenerator.dart';
import 'package:tarteel/core/database/hive_database.dart';
import 'package:tarteel/core/services/adhan_notification_service.dart';
import 'package:tarteel/core/services/general_notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/hisn_almuslim/services/hisn_service.dart';

import 'package:provider/provider.dart';
import 'package:tarteel/core/providers/prayer_provider.dart';
import 'package:tarteel/core/services/adhan_player_service.dart';
import 'package:tarteel/core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  await Hive.initFlutter();

  await HiveDatabase.init();
  await AdhanNotificationService.initialize();
  await GeneralNotificationService.scheduleAllEnabledNotifications();

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  // Kick off Quran and Hisn text preloading asynchronously after all core plugins are ready
  Future.microtask(() {
    QuranService.preloadQuran();
    HisnService.loadHisnAsActions();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PrayerProvider()..initializeData(),
        ),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const tarteel(),
    ),
  );
}

class tarteel extends StatelessWidget {
  const tarteel({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  Widget build(BuildContext context) {
    // Read the ThemeProvider using tarteel's own context (which is directly below MultiProvider)
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return ScreenUtilInit(
      designSize: const Size(
        375,
        812,
      ), // Default design size, can be adjusted according to your UI design (Figma/AdobeXD)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (ctx, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,

          builder: (context, widget) {
            return MediaQuery(
              // نثبت نسبة تكبير الخط (Text Scale) لتكون 1.0 أو قريبة منها
              // لمنع إعدادات خط الهاتف (النظام) من تدمير وتكبير التصميم بشكل عشوائي
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: ScrollConfiguration(
                behavior: MyBehavior(),
                child: AdhanOverlayWrapper(child: widget!),
              ),
            );
          },

          // Light Theme
          theme: AppTheme.light,

          // Dark Theme
          darkTheme: AppTheme.dark,

          // System Theme
          themeMode: themeMode,

          initialRoute: AppRoutes.splash,
          onGenerateRoute: RouteGenerator.generate,
          navigatorObservers: [routeObserver],
        );
      },
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
