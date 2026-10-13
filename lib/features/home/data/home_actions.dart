import 'package:flutter/material.dart';

import 'package:tarteel/Model/AccessListModel.dart';

import 'package:tarteel/routes/AppRoutes.dart';

class HomeActions {
  // ========================= الوصول السريع =========================

  static List<AccessListModel> quickActionsList = [
    AccessListModel(
      icon: Icons.menu_book_outlined,
      route: AppRoutes.quran,
      title: 'القرآن',
    ),

    AccessListModel(
      icon: Icons.bookmark_outline,
      route: AppRoutes.azkarCategories,
      title: 'الأذكار',
    ),

    AccessListModel(
      icon: Icons.auto_stories_outlined,
      route: AppRoutes.hisnCategories,
      title: 'حصن المسلم',
    ),

    AccessListModel(
      icon: Icons.format_quote_outlined,
      route: AppRoutes.hadith,
      title: 'الأحاديث',
    ),
    AccessListModel(
      icon: Icons.timer_outlined,
      route: AppRoutes.tasbeeh,
      title: 'التسبيح',
    ),
    AccessListModel(
      icon: Icons.auto_awesome_outlined,
      route: AppRoutes.namesOfAllah,
      title: 'الأسماء',
    ),
    AccessListModel(
      icon: Icons.import_contacts_outlined,
      route: AppRoutes.prophetsStories,
      title: 'قصص الأنبياء',
    ),
    AccessListModel(
      icon: Icons.record_voice_over_outlined,
      route: AppRoutes.adhanMuezzin,
      title: 'المؤذن',
    ),
    AccessListModel(
      icon: Icons.explore_outlined,
      route: AppRoutes.qibla,
      title: 'البوصلة',
    ),

    // AccessListModel(
    //   icon: Icons.stars_rounded,
    //   route: AppRoutes.namesOfProphet,
    //   title: 'أسماء النبي ﷺ',
    // ),
    
    AccessListModel(
      icon: Icons.favorite_border,
      route: AppRoutes.bookmarks,
      title: 'المفضلة',
    ),
    AccessListModel(
      icon: Icons.analytics_outlined,
      route: AppRoutes.stats,
      title: 'الإحصائيات',
    ),

    AccessListModel(
      icon: Icons.settings_outlined,
      route: AppRoutes.settings,
      title: 'الإعدادات',
    ),
  ];
}
