import 'package:flutter/material.dart';

/// ==============================================================================
/// عنصر العبادة الفردي داخل محطة الصلاة (سنة قبلية، فريضة، سنة بعدية، أذكار)
/// ==============================================================================
class PrayerStationItem {
  final String id;
  final String title;
  final String rakahs;
  final String detail;
  final IconData icon;
  final bool isMandatory;
  final String? route;
  final dynamic routeArguments;

  const PrayerStationItem({
    required this.id,
    required this.title,
    required this.rakahs,
    required this.detail,
    required this.icon,
    this.isMandatory = false,
    this.route,
    this.routeArguments,
  });
}

/// ==============================================================================
/// نموذج محطة الصلاة والوقت (الفجر، الضحى، الظهر، العصر، المغرب، العشاء، قيام الليل)
/// ==============================================================================
class PrayerStationModel {
  final String id;
  final String title;
  final String shortName;
  final IconData icon;
  final String approximateTime;
  final String virtueHadith;
  final List<PrayerStationItem> items;

  const PrayerStationModel({
    required this.id,
    required this.title,
    required this.shortName,
    required this.icon,
    required this.approximateTime,
    required this.virtueHadith,
    required this.items,
  });

  /// حساب عدد العناصر المكتملة في هذه المحطة
  int getCompletedCount(Set<String> completedIds) {
    return items.where((it) => completedIds.contains(it.id)).length;
  }

  /// هل اكتملت جميع عناصر المحطة؟
  bool isFullyCompleted(Set<String> completedIds) {
    if (items.isEmpty) return false;
    return getCompletedCount(completedIds) == items.length;
  }

  /// القائمة الكاملة لمحطات اليوم مع تفصيل السنن والفرائض فقهياً
  static List<PrayerStationModel> getDefaultStations() {
    return const [
      // 1. محطة الفجر
      PrayerStationModel(
        id: 'fajr',
        title: 'صلاة الفجر',
        shortName: 'الفجر',
        icon: Icons.wb_twilight_rounded,
        approximateTime: '٠٥:٠٠ ص',
        virtueHadith: 'قال رسول الله ﷺ: «رَكْعَتَا الْفَجْرِ خَيْرٌ مِنَ الدُّنْيَا وَمَا فِيهَا».',
        items: [
          PrayerStationItem(
            id: 'fajr_sunnah',
            title: 'سنة الفجر القبلية',
            rakahs: 'ركعتان',
            detail: 'سنة مؤكدة رغب فيها النبي ﷺ قبل صلاة الفجر',
            icon: Icons.stars_rounded,
          ),
          PrayerStationItem(
            id: 'fajr_fard',
            title: 'فريضة الفجر',
            rakahs: 'ركعتان',
            detail: 'في وقتها مع الجماعة أو فور الأذان',
            icon: Icons.wb_twilight_rounded,
            isMandatory: true,
          ),
          PrayerStationItem(
            id: 'fajr_azkar_after',
            title: 'أذكار ما بعد الصلاة',
            rakahs: 'استغفار وتسبيح',
            detail: 'الاستغفار ٣ مرات، آية الكرسي، والتسبيح ٣٣',
            icon: Icons.all_inclusive_rounded,
            route: '/zkar-details',
            routeArguments: 'أذكار بعد السلام من الصلاة',
          ),
          PrayerStationItem(
            id: 'fajr_azkar_sabah',
            title: 'أذكار الصباح',
            rakahs: 'حصن المسلم',
            detail: 'حفظ وسكينة من طلوع الفجر حتى شروق الشمس',
            icon: Icons.light_mode_outlined,
            route: '/zkar-details',
            routeArguments: 'أذكار الصباح',
          ),
        ],
      ),

      // 2. محطة الضحى
      PrayerStationModel(
        id: 'duha',
        title: 'صلاة الضحى',
        shortName: 'الضحى',
        icon: Icons.wb_sunny_rounded,
        approximateTime: '٠٨:٠٠ ص',
        virtueHadith: 'صلاة الأوّابين، وتجزئ عن صدقة ثلاثمائة وستين مفصلاً في جسد الإنسان.',
        items: [
          PrayerStationItem(
            id: 'duha_prayer',
            title: 'صلاة الضحى',
            rakahs: 'ركعتان إلى ٨ ركعات',
            detail: 'وقتها من بعد شروق الشمس بربع ساعة حتى قبيل الظهر',
            icon: Icons.wb_sunny_rounded,
          ),
        ],
      ),

      // 3. محطة الظهر
      PrayerStationModel(
        id: 'dhuhr',
        title: 'صلاة الظهر',
        shortName: 'الظهر',
        icon: Icons.wb_sunny_outlined,
        approximateTime: '١٢:١٥ م',
        virtueHadith: 'قال رسول الله ﷺ: «مَنْ حَافَظَ عَلَى أَرْبَعِ رَكَعَاتٍ قَبْلَ الظُّهْرِ وَأَرْبَعٍ بَعْدَهَا حَرَّمَهُ اللَّهُ عَلَى النَّارِ».',
        items: [
          PrayerStationItem(
            id: 'dhuhr_sunnah_before',
            title: 'سنة الظهر القبلية',
            rakahs: '٤ ركعات',
            detail: 'ركعتان ثم ركعتان بعد أذان الظهر وقبل الفريضة',
            icon: Icons.stars_rounded,
          ),
          PrayerStationItem(
            id: 'dhuhr_fard',
            title: 'فريضة الظهر',
            rakahs: '٤ ركعات',
            detail: 'أداء صلاة الظهر المفروضة في وقتها',
            icon: Icons.wb_sunny_outlined,
            isMandatory: true,
          ),
          PrayerStationItem(
            id: 'dhuhr_sunnah_after',
            title: 'سنة الظهر البعدية',
            rakahs: 'ركعتان',
            detail: 'سنة مؤكدة بعد الانتهاء من فريضة الظهر',
            icon: Icons.stars_rounded,
          ),
          PrayerStationItem(
            id: 'dhuhr_azkar',
            title: 'أذكار ما بعد الصلاة',
            rakahs: 'استغفار وتسبيح',
            detail: 'الاستغفار ٣ مرات، آية الكرسي، والتسبيح والتحميد والتكبير ٣٣',
            icon: Icons.all_inclusive_rounded,
            route: '/zkar-details',
            routeArguments: 'أذكار بعد السلام من الصلاة',
          ),
        ],
      ),

      // 4. محطة العصر
      PrayerStationModel(
        id: 'asr',
        title: 'صلاة العصر',
        shortName: 'العصر',
        icon: Icons.filter_drama_rounded,
        approximateTime: '٠٣:٣٠ م',
        virtueHadith: 'قال رسول الله ﷺ: «رَحِمَ اللَّهُ امْرَأً صَلَّى قَبْلَ الْعَصْرِ أَرْبَعًا».',
        items: [
          PrayerStationItem(
            id: 'asr_sunnah_before',
            title: 'سنة العصر القبلية',
            rakahs: '٤ ركعات (مستحبة)',
            detail: 'ركعتان ثم ركعتان قبل صلاة العصر لنيل دعوة النبي ﷺ',
            icon: Icons.stars_rounded,
          ),
          PrayerStationItem(
            id: 'asr_fard',
            title: 'فريضة العصر',
            rakahs: '٤ ركعات',
            detail: 'الصلاة الوسطى التي أكد الله على تعظيمها',
            icon: Icons.filter_drama_rounded,
            isMandatory: true,
          ),
          PrayerStationItem(
            id: 'asr_azkar',
            title: 'أذكار ما بعد الصلاة',
            rakahs: 'استغفار وتسبيح',
            detail: 'الاستغفار ٣ مرات وآية الكرسي والأذكار المسنونة',
            icon: Icons.all_inclusive_rounded,
            route: '/zkar-details',
            routeArguments: 'أذكار بعد السلام من الصلاة',
          ),
          PrayerStationItem(
            id: 'asr_azkar_masaa',
            title: 'أذكار المساء',
            rakahs: 'حصن المسلم',
            detail: 'حفظ وسكينة تبدأ من بعد العصر حتى غروب الشمس',
            icon: Icons.nightlight_round,
            route: '/zkar-details',
            routeArguments: 'أذكار المساء',
          ),
        ],
      ),

      // 5. محطة المغرب
      PrayerStationModel(
        id: 'maghrib',
        title: 'صلاة المغرب',
        shortName: 'المغرب',
        icon: Icons.nights_stay_outlined,
        approximateTime: '٠٦:٠٠ م',
        virtueHadith: 'صلاة ختام النهار، وسنتها البعدية ركعتان كان النبي ﷺ لا يتركهما في حضر ولا سفر.',
        items: [
          PrayerStationItem(
            id: 'maghrib_fard',
            title: 'فريضة المغرب',
            rakahs: '٣ ركعات',
            detail: 'ثلاث ركعات مع غروب الشمس في أول وقتها',
            icon: Icons.nights_stay_outlined,
            isMandatory: true,
          ),
          PrayerStationItem(
            id: 'maghrib_sunnah_after',
            title: 'سنة المغرب البعدية',
            rakahs: 'ركعتان',
            detail: 'سنة مؤكدة ركعتان بعد الانتهاء من صلاة المغرب',
            icon: Icons.stars_rounded,
          ),
          PrayerStationItem(
            id: 'maghrib_azkar',
            title: 'أذكار ما بعد الصلاة',
            rakahs: 'استغفار وتسبيح',
            detail: 'الاستغفار وآية الكرسي والتسبيح ٣٣',
            icon: Icons.all_inclusive_rounded,
            route: '/zkar-details',
            routeArguments: 'أذكار بعد السلام من الصلاة',
          ),
        ],
      ),

      // 6. محطة العشاء
      PrayerStationModel(
        id: 'isha',
        title: 'صلاة العشاء',
        shortName: 'العشاء',
        icon: Icons.bedtime_outlined,
        approximateTime: '٠٧:٣٠ م',
        virtueHadith: 'قال رسول الله ﷺ: «مَنْ صَلَّى الْعِشَاءَ فِي جَمَاعَةٍ فَكَأَنَّمَا قَامَ نِصْفَ اللَّيْلِ».',
        items: [
          PrayerStationItem(
            id: 'isha_fard',
            title: 'فريضة العشاء',
            rakahs: '٤ ركعات',
            detail: 'ختام الصلوات المفروضة الخمس في اليوم والليلة',
            icon: Icons.bedtime_outlined,
            isMandatory: true,
          ),
          PrayerStationItem(
            id: 'isha_sunnah_after',
            title: 'سنة العشاء البعدية',
            rakahs: 'ركعتان',
            detail: 'سنة مؤكدة ركعتان بعد فريضة العشاء',
            icon: Icons.stars_rounded,
          ),
          PrayerStationItem(
            id: 'isha_azkar',
            title: 'أذكار ما بعد الصلاة',
            rakahs: 'استغفار وتسبيح',
            detail: 'الاستغفار وآية الكرسي والتسبيح ٣٣',
            icon: Icons.all_inclusive_rounded,
            route: '/zkar-details',
            routeArguments: 'أذكار بعد السلام من الصلاة',
          ),
        ],
      ),

      // 7. محطة قيام الليل والوتر
      PrayerStationModel(
        id: 'qiyam',
        title: 'قيام الليل والوتر',
        shortName: 'قيام الليل',
        icon: Icons.dark_mode_outlined,
        approximateTime: '١٠:٠٠ م',
        virtueHadith: 'قال رسول الله ﷺ: «أَفْضَلُ الصَّلَاةِ بَعْدَ الصَّلَاةِ الْمَكْتُوبَةِ الصَّلَاةُ فِي جَوْفِ اللَّيْلِ».',
        items: [
          PrayerStationItem(
            id: 'qiyam_prayer',
            title: 'قيام الليل والتهجد',
            rakahs: 'ركعتان فأكثر',
            detail: 'ركعتان ركعتان في جوف الليل والثلث الأخير',
            icon: Icons.dark_mode_outlined,
          ),
          PrayerStationItem(
            id: 'witr_prayer',
            title: 'صلاة الشفع والوتر',
            rakahs: 'ركعة أو ٣ ركعات',
            detail: 'اجعلوا آخر صلاتكم بالليل وتراً',
            icon: Icons.stars_rounded,
          ),
          PrayerStationItem(
            id: 'azkar_sleep',
            title: 'أذكار النوم وسورة الملك',
            rakahs: 'حصن المسلم',
            detail: 'آية الكرسي وخواتيم البقرة والمعوذات وسورة الملك المنجية',
            icon: Icons.bed_rounded,
            route: '/zkar-details',
            routeArguments: 'أذكار النوم',
          ),
        ],
      ),
    ];
  }
}
