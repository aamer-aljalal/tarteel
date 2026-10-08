import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:tarteel/features/azkar/model/zekr_category.dart';
import 'package:tarteel/Routes/AppRoutes.dart';
import 'package:tarteel/features/home/HomePage.dart';
import 'package:tarteel/features/azkar/AzkarCategories.dart';
import 'package:tarteel/features/azkar/zkar_details.dart';
import 'package:tarteel/features/Hadith/HadithScreen.dart';
import 'package:tarteel/features/Qibla/QiblaScreen.dart';
import 'package:tarteel/features/Settings/Settings.dart';
import 'package:tarteel/features/adhan/views/adhan_muezzin_screen.dart';
import 'package:tarteel/features/quran/views/SurahListPage.dart';
import 'package:tarteel/features/Tasbeeh/TasbeehScreen.dart';
import 'package:tarteel/features/Dashbord/Stats.dart';
import 'package:tarteel/features/names_of_allah/views/names_of_allah_screen.dart';
import 'package:tarteel/features/bookmarks/views/bookmarks_page.dart';
import 'package:tarteel/features/hisn_almuslim/hisn_categories_screen.dart';
import 'package:tarteel/features/hisn_almuslim/hisn_details_screen.dart';
import 'package:tarteel/features/hisn_almuslim/model/hisn_category.dart';
import 'package:tarteel/features/quran/views/khatma_planner_screen.dart';
import 'package:tarteel/features/prophets_stories/views/prophets_list_screen.dart';
import 'package:tarteel/features/splash/splash_screen.dart';

class RouteGenerator {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      // ========================= الرئيسية =========================

      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
        
      case AppRoutes.homePage:
        return MaterialPageRoute(builder: (_) => const HomePage());

      // ========================= القرآن =========================

      case AppRoutes.quran:
        return MaterialPageRoute(builder: (_) => const SurahListPage());

      // ========================= قصص الأنبياء =========================

      case AppRoutes.prophetsStories:
        return MaterialPageRoute(builder: (_) => const ProphetsListScreen());

      // ========================= الأذكار =========================

      case AppRoutes.azkarCategories:
        return MaterialPageRoute(builder: (_) => const AzkarCategoriesScreen());

      case AppRoutes.zkarDetails:
        final category = settings.arguments as ZekrCategory;
        return MaterialPageRoute(
          builder: (_) => AzkarDetailsScreen(category: category),
        );

      // ========================= التسبيح =========================

      case AppRoutes.tasbeeh:
        return MaterialPageRoute(builder: (_) => const TasbeehScreen());

      // case AppRoutes.tasbeeh:
      //   return MaterialPageRoute(builder: (_) => const TasbeehApp());
      // ========================= الأحاديث =========================

      case AppRoutes.hadith:
        return MaterialPageRoute(builder: (_) => const HadithScreen());

      // ========================= أسماء الله الحسنى =========================

      case AppRoutes.namesOfAllah:
        return MaterialPageRoute(builder: (_) => const NamesOfAllahScreen());

      // ========================= القبلة =========================

      case AppRoutes.qibla:
        return MaterialPageRoute(builder: (_) => const QiblaScreen());

      // ========================= الإعدادات =========================

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case AppRoutes.adhanMuezzin:
        return MaterialPageRoute(builder: (_) => const AdhanMuezzinScreen());

      // ========================= الإحصائيات =========================

      case AppRoutes.stats:
        return MaterialPageRoute(builder: (_) => const StatsScreen());

      case AppRoutes.khatmaPlanner:
        return MaterialPageRoute(builder: (_) => const KhatmaPlannerScreen());

      // ========================= المحفوظات =========================

      case AppRoutes.bookmarks:
        return MaterialPageRoute(builder: (_) => const BookmarksPage());

      // ========================= حصن المسلم =========================

      case AppRoutes.hisnCategories:
        return MaterialPageRoute(builder: (_) => const HisnCategoriesScreen());

      case AppRoutes.hisnDetails:
        final category = settings.arguments as HisnCategory;
        return MaterialPageRoute(
          builder: (_) => HisnDetailsScreen(category: category),
        );

      // ========================= صفحة غير موجودة =========================

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text(
                'Page Not Found',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
    }
  }
}
