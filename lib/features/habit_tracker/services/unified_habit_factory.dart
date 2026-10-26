import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:tarteel/Routes/AppRoutes.dart';
import '../models/unified_habit_item.dart';
import '../services/habit_calendar_helper.dart';

/// ==============================================================================
/// مولّد قائمة العبادات اليومية الموحدة والمتسلسلة زمنياً
/// ==============================================================================
class UnifiedHabitFactory {
  UnifiedHabitFactory._();

  static List<UnifiedHabitItem> buildDailyList({
    required DateTime date,
    PrayerTimes? prayerTimes,
  }) {
    final isFriday = HabitCalendarHelper.isFriday(date);
    final fastingReason = HabitCalendarHelper.getFastingReason(date);

    String formatTime(DateTime dt) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'م' : 'ص';
      return HabitCalendarHelper.toArabicNumbers('$hour:$minute $period');
    }

    final fajrTime = prayerTimes != null ? formatTime(prayerTimes.fajr) : '٠٥:٠٠ ص';
    final duhaTime = prayerTimes != null 
        ? formatTime(prayerTimes.sunrise.add(const Duration(minutes: 20))) 
        : '٠٧:٣٠ ص';
    final dhuhrTime = prayerTimes != null ? formatTime(prayerTimes.dhuhr) : '١٢:١٥ م';
    final asrTime = prayerTimes != null ? formatTime(prayerTimes.asr) : '٠٣:٣٠ م';
    final maghribTime = prayerTimes != null ? formatTime(prayerTimes.maghrib) : '٠٦:٠٠ م';
    final ishaTime = prayerTimes != null ? formatTime(prayerTimes.isha) : '٠٧:٣٠ م';

    final List<UnifiedHabitItem> list = [];
    int order = 1;

    // 1. صيام نافلة إن وجد (الإثنين والخميس والأيام البيض)
    if (fastingReason != null) {
      list.add(
        UnifiedHabitItem(
          id: 'fasting_today',
          title: 'صيام اليوم',
          subtitle: fastingReason,
          timeLabel: 'من الفجر للمغرب',
          badgeText: 'نافلة',
          icon: Icons.brightness_medium_rounded,
          type: UnifiedHabitType.fasting,
          sortOrder: order++,
        ),
      );
    }

    // 2. سنة الفجر القبلية
    list.add(
      UnifiedHabitItem(
        id: 'fajr_sunnah',
        title: 'سنة الفجر القبلية',
        subtitle: 'ركعتان قبل الفريضة، خير من الدنيا وما فيها',
        timeLabel: fajrTime,
        badgeText: 'ركعتان',
        icon: Icons.stars_rounded,
        type: UnifiedHabitType.prayerSunnah,
        sortOrder: order++,
      ),
    );

    // 3. فريضة الفجر
    list.add(
      UnifiedHabitItem(
        id: 'fajr_fard',
        title: 'صلاة الفجر',
        subtitle: 'في وقتها مع الجماعة أو فور الأذان',
        timeLabel: fajrTime,
        badgeText: 'ركعتان',
        icon: Icons.wb_twilight_rounded,
        type: UnifiedHabitType.prayerFard,
        isMandatory: true,
        sortOrder: order++,
      ),
    );

    // 4. أذكار ما بعد صلاة الفجر
    list.add(
      UnifiedHabitItem(
        id: 'fajr_azkar_after',
        title: 'أذكار ما بعد صلاة الفجر',
        subtitle: 'الاستغفار ثلاثاً وآية الكرسي والتسبيح ٣٣',
        timeLabel: fajrTime,
        badgeText: 'استغفار وتسبيح',
        icon: Icons.all_inclusive_rounded,
        type: UnifiedHabitType.azkar,
        actionText: 'قراءة الأذكار',
        route: AppRoutes.zkarDetails,
        routeArguments: 'أذكار بعد السلام من الصلاة',
        sortOrder: order++,
      ),
    );

    // 5. أذكار الصباح
    list.add(
      UnifiedHabitItem(
        id: 'azkar_sabah',
        title: 'أذكار الصباح',
        subtitle: 'حصن المسلم والسكينة لافتتاح اليوم المبارك',
        timeLabel: 'بعد الفجر',
        badgeText: 'حصن المسلم',
        icon: Icons.light_mode_outlined,
        type: UnifiedHabitType.azkar,
        actionText: 'قراءة الأذكار',
        route: AppRoutes.zkarDetails,
        routeArguments: 'أذكار الصباح',
        sortOrder: order++,
      ),
    );

    // 6. صلاة الضحى
    list.add(
      UnifiedHabitItem(
        id: 'duha_prayer',
        title: 'صلاة الضحى',
        subtitle: 'صلاة الأوّابين وتجزئ عن صدقة ٣٦٠ مفصلاً',
        timeLabel: duhaTime,
        badgeText: 'ركعتان فأكثر',
        icon: Icons.wb_sunny_rounded,
        type: UnifiedHabitType.prayerSunnah,
        sortOrder: order++,
      ),
    );

    // 7. سورة الكهف (يوم الجمعة فقط)
    if (isFriday) {
      list.add(
        UnifiedHabitItem(
          id: 'quran_kahf',
          title: 'سورة الكهف',
          subtitle: 'نور ما بين الجمعتين وبركة وسكينة',
          timeLabel: 'يوم الجمعة',
          badgeText: 'سورة الكهف',
          icon: Icons.menu_book_rounded,
          type: UnifiedHabitType.quran,
          actionText: 'قراءة السورة',
          route: AppRoutes.surahDetails,
          routeArguments: 18,
          sortOrder: order++,
        ),
      );
    }

    // 8. ورد التسبيح والاستغفار اليومي
    list.add(
      UnifiedHabitItem(
        id: 'daily_tasbeeh',
        title: 'ورد التسبيح والاستغفار',
        subtitle: '١٠٠ تسبيحة واستغفار في المسبحة الإلكترونية',
        timeLabel: 'الصباح / النهار',
        badgeText: '١٠٠ مرة',
        icon: Icons.touch_app_outlined,
        type: UnifiedHabitType.tasbeeh,
        actionText: 'فتح المسبحة',
        route: AppRoutes.tasbeeh,
        sortOrder: order++,
      ),
    );

    // 9. سنة الظهر القبلية
    list.add(
      UnifiedHabitItem(
        id: 'dhuhr_sunnah_before',
        title: 'سنة الظهر القبلية',
        subtitle: 'أربع ركعات ركعتين ركعتين قبل فريضة الظهر',
        timeLabel: dhuhrTime,
        badgeText: '٤ ركعات',
        icon: Icons.stars_rounded,
        type: UnifiedHabitType.prayerSunnah,
        sortOrder: order++,
      ),
    );

    // 10. فريضة الظهر
    list.add(
      UnifiedHabitItem(
        id: 'dhuhr_fard',
        title: 'صلاة الظهر',
        subtitle: 'أداء صلاة الظهر المفروضة في وقتها',
        timeLabel: dhuhrTime,
        badgeText: '٤ ركعات',
        icon: Icons.wb_sunny_outlined,
        type: UnifiedHabitType.prayerFard,
        isMandatory: true,
        sortOrder: order++,
      ),
    );

    // 11. سنة الظهر البعدية
    list.add(
      UnifiedHabitItem(
        id: 'dhuhr_sunnah_after',
        title: 'سنة الظهر البعدية',
        subtitle: 'سنة مؤكدة ركعتان بعد الانتهاء من الظهر',
        timeLabel: dhuhrTime,
        badgeText: 'ركعتان',
        icon: Icons.stars_rounded,
        type: UnifiedHabitType.prayerSunnah,
        sortOrder: order++,
      ),
    );

    // 12. أذكار ما بعد صلاة الظهر
    list.add(
      UnifiedHabitItem(
        id: 'dhuhr_azkar_after',
        title: 'أذكار ما بعد صلاة الظهر',
        subtitle: 'الاستغفار ثلاثاً وآية الكرسي والتسبيح ٣٣',
        timeLabel: dhuhrTime,
        badgeText: 'استغفار وتسبيح',
        icon: Icons.all_inclusive_rounded,
        type: UnifiedHabitType.azkar,
        actionText: 'قراءة الأذكار',
        route: AppRoutes.zkarDetails,
        routeArguments: 'أذكار بعد السلام من الصلاة',
        sortOrder: order++,
      ),
    );

    // 13. ورد قراءة القرآن (خطة الختمة)
    list.add(
      UnifiedHabitItem(
        id: 'quran_wird',
        title: 'ورد قراءة القرآن الكريم',
        subtitle: 'متابعة خطة الختمة اليومية وجزء التلاوة',
        timeLabel: 'أوقات النهار',
        badgeText: 'المصحف',
        icon: Icons.auto_stories_rounded,
        type: UnifiedHabitType.quran,
        actionText: 'فتح المصحف',
        route: AppRoutes.quran,
        sortOrder: order++,
      ),
    );

    // 14. سنة العصر القبلية (مستحبة)
    list.add(
      UnifiedHabitItem(
        id: 'asr_sunnah_before',
        title: 'سنة العصر القبلية',
        subtitle: 'أربع ركعات مستحبة لنيل دعوة النبي ﷺ بالرحمة',
        timeLabel: asrTime,
        badgeText: '٤ ركعات',
        icon: Icons.stars_rounded,
        type: UnifiedHabitType.prayerSunnah,
        sortOrder: order++,
      ),
    );

    // 15. فريضة العصر
    list.add(
      UnifiedHabitItem(
        id: 'asr_fard',
        title: 'صلاة العصر',
        subtitle: 'الصلاة الوسطى والحرص عليها في وقتها',
        timeLabel: asrTime,
        badgeText: '٤ ركعات',
        icon: Icons.filter_drama_rounded,
        type: UnifiedHabitType.prayerFard,
        isMandatory: true,
        sortOrder: order++,
      ),
    );

    // 16. أذكار ما بعد صلاة العصر
    list.add(
      UnifiedHabitItem(
        id: 'asr_azkar_after',
        title: 'أذكار ما بعد صلاة العصر',
        subtitle: 'الاستغفار ثلاثاً وآية الكرسي والأذكار المسنونة',
        timeLabel: asrTime,
        badgeText: 'استغفار وتسبيح',
        icon: Icons.all_inclusive_rounded,
        type: UnifiedHabitType.azkar,
        actionText: 'قراءة الأذكار',
        route: AppRoutes.zkarDetails,
        routeArguments: 'أذكار بعد السلام من الصلاة',
        sortOrder: order++,
      ),
    );

    // 17. أذكار المساء
    list.add(
      UnifiedHabitItem(
        id: 'azkar_masaa',
        title: 'أذكار المساء',
        subtitle: 'حصن المسلم وسكينة النفس من العصر حتى الغروب',
        timeLabel: 'بعد العصر',
        badgeText: 'حصن المسلم',
        icon: Icons.nightlight_round,
        type: UnifiedHabitType.azkar,
        actionText: 'قراءة الأذكار',
        route: AppRoutes.zkarDetails,
        routeArguments: 'أذكار المساء',
        sortOrder: order++,
      ),
    );

    // 18. فريضة المغرب
    list.add(
      UnifiedHabitItem(
        id: 'maghrib_fard',
        title: 'صلاة المغرب',
        subtitle: 'ثلاث ركعات مع غروب الشمس في أول وقتها',
        timeLabel: maghribTime,
        badgeText: '٣ ركعات',
        icon: Icons.nights_stay_outlined,
        type: UnifiedHabitType.prayerFard,
        isMandatory: true,
        sortOrder: order++,
      ),
    );

    // 19. سنة المغرب البعدية
    list.add(
      UnifiedHabitItem(
        id: 'maghrib_sunnah_after',
        title: 'سنة المغرب البعدية',
        subtitle: 'سنة مؤكدة ركعتان بعد الانتهاء من المغرب',
        timeLabel: maghribTime,
        badgeText: 'ركعتان',
        icon: Icons.stars_rounded,
        type: UnifiedHabitType.prayerSunnah,
        sortOrder: order++,
      ),
    );

    // 20. أذكار ما بعد صلاة المغرب
    list.add(
      UnifiedHabitItem(
        id: 'maghrib_azkar_after',
        title: 'أذكار ما بعد صلاة المغرب',
        subtitle: 'الاستغفار وآية الكرسي والتسبيح ٣٣',
        timeLabel: maghribTime,
        badgeText: 'استغفار وتسبيح',
        icon: Icons.all_inclusive_rounded,
        type: UnifiedHabitType.azkar,
        actionText: 'قراءة الأذكار',
        route: AppRoutes.zkarDetails,
        routeArguments: 'أذكار بعد السلام من الصلاة',
        sortOrder: order++,
      ),
    );

    // 21. فريضة العشاء
    list.add(
      UnifiedHabitItem(
        id: 'isha_fard',
        title: 'صلاة العشاء',
        subtitle: 'ختام الصلوات المفروضة الخمس في اليوم والليلة',
        timeLabel: ishaTime,
        badgeText: '٤ ركعات',
        icon: Icons.bedtime_outlined,
        type: UnifiedHabitType.prayerFard,
        isMandatory: true,
        sortOrder: order++,
      ),
    );

    // 22. سنة العشاء البعدية
    list.add(
      UnifiedHabitItem(
        id: 'isha_sunnah_after',
        title: 'سنة العشاء البعدية',
        subtitle: 'سنة مؤكدة ركعتان بعد فريضة العشاء',
        timeLabel: ishaTime,
        badgeText: 'ركعتان',
        icon: Icons.stars_rounded,
        type: UnifiedHabitType.prayerSunnah,
        sortOrder: order++,
      ),
    );

    // 23. أذكار ما بعد صلاة العشاء
    list.add(
      UnifiedHabitItem(
        id: 'isha_azkar_after',
        title: 'أذكار ما بعد صلاة العشاء',
        subtitle: 'الاستغفار وآية الكرسي والتسبيح ٣٣',
        timeLabel: ishaTime,
        badgeText: 'استغفار وتسبيح',
        icon: Icons.all_inclusive_rounded,
        type: UnifiedHabitType.azkar,
        actionText: 'قراءة الأذكار',
        route: AppRoutes.zkarDetails,
        routeArguments: 'أذكار بعد السلام من الصلاة',
        sortOrder: order++,
      ),
    );

    // 24. قيام الليل والتهجد
    list.add(
      UnifiedHabitItem(
        id: 'qiyam_prayer',
        title: 'قيام الليل والتهجد',
        subtitle: 'ركعتان فأكثر في جوف الليل والثلث الأخير',
        timeLabel: 'ليل',
        badgeText: 'ركعتان فأكثر',
        icon: Icons.dark_mode_outlined,
        type: UnifiedHabitType.qiyam,
        sortOrder: order++,
      ),
    );

    // 25. صلاة الشفع والوتر
    list.add(
      UnifiedHabitItem(
        id: 'witr_prayer',
        title: 'صلاة الشفع والوتر',
        subtitle: 'اجعلوا آخر صلاتكم بالليل وتراً',
        timeLabel: 'قبل النوم',
        badgeText: 'ركعة أو ٣',
        icon: Icons.stars_rounded,
        type: UnifiedHabitType.qiyam,
        sortOrder: order++,
      ),
    );

    // 26. أذكار النوم وسورة الملك
    list.add(
      UnifiedHabitItem(
        id: 'azkar_sleep',
        title: 'أذكار النوم وسورة الملك',
        subtitle: 'حصن المسلم وسورة الملك المنجية من عذاب القبر',
        timeLabel: 'عند النوم',
        badgeText: 'حصن المسلم',
        icon: Icons.bed_rounded,
        type: UnifiedHabitType.azkar,
        actionText: 'قراءة الأذكار',
        route: AppRoutes.zkarDetails,
        routeArguments: 'أذكار النوم',
        sortOrder: order++,
      ),
    );

    return list;
  }
}
