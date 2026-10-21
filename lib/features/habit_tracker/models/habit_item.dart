import 'package:flutter/material.dart';
import 'habit_category.dart';

/// ==============================================================================
/// نموذج العبادة الفردية في سجل العبادات اليومي
/// ==============================================================================
class HabitItem {
  /// المعرّف الفريد للعبادة (مثل: fajr, sunan_rawatib, azkar_sabah)
  final String id;

  /// اسم العبادة
  final String title;

  /// وصف مختصر أو فضل العبادة (بدون أي إيموجي)
  final String subtitle;

  /// تصنيف العبادة
  final HabitCategory category;

  /// الأيقونة التعبيرية الفكتورية للعبادة
  final IconData icon;

  /// هل العبادة فريضة أساسية لا يمكن حذفها من الجدول؟ (مثل الصلوات الخمس)
  final bool isMandatory;

  /// هل العبادة مفعّلة في جدول المستخدم اليومي؟
  final bool isEnabled;

  /// هل العبادة تظهر ديناميكياً حسب اليوم؟ (مثل سورة الكهف يوم الجمعة، وصيام النوافل)
  final bool isDynamic;

  /// مسار الانتقال الاختياري داخل التطبيق (مثل فتح شاشة الأذكار أو المصحف)
  final String? route;

  /// معاملات إضافية للمسار إن وجدت
  final dynamic routeArguments;

  const HabitItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    this.isMandatory = false,
    this.isEnabled = true,
    this.isDynamic = false,
    this.route,
    this.routeArguments,
  });

  HabitItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    HabitCategory? category,
    IconData? icon,
    bool? isMandatory,
    bool? isEnabled,
    bool? isDynamic,
    String? route,
    dynamic routeArguments,
  }) {
    return HabitItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      isMandatory: isMandatory ?? this.isMandatory,
      isEnabled: isEnabled ?? this.isEnabled,
      isDynamic: isDynamic ?? this.isDynamic,
      route: route ?? this.route,
      routeArguments: routeArguments ?? this.routeArguments,
    );
  }

  /// القائمة الكاملة الشاملة للعبادات الافتراضية
  static List<HabitItem> getDefaultHabits() {
    return const [
      // --- الصلوات المفروضة الخمس (فرائض لا تحذف) ---
      HabitItem(
        id: 'fajr',
        title: 'صلاة الفجر',
        subtitle: 'في وقتها مع الجماعة أو فور الأذان',
        category: HabitCategory.prayers,
        icon: Icons.wb_twilight_rounded,
        isMandatory: true,
        isEnabled: true,
      ),
      HabitItem(
        id: 'dhuhr',
        title: 'صلاة الظهر',
        subtitle: 'أربع ركعات في وقتها',
        category: HabitCategory.prayers,
        icon: Icons.wb_sunny_rounded,
        isMandatory: true,
        isEnabled: true,
      ),
      HabitItem(
        id: 'asr',
        title: 'صلاة العصر',
        subtitle: 'الصلاة الوسطى',
        category: HabitCategory.prayers,
        icon: Icons.wb_sunny_outlined,
        isMandatory: true,
        isEnabled: true,
      ),
      HabitItem(
        id: 'maghrib',
        title: 'صلاة المغرب',
        subtitle: 'ثلاث ركعات مع غروب الشمس',
        category: HabitCategory.prayers,
        icon: Icons.nights_stay_outlined,
        isMandatory: true,
        isEnabled: true,
      ),
      HabitItem(
        id: 'isha',
        title: 'صلاة العشاء',
        subtitle: 'ختام الصلوات المفروضة',
        category: HabitCategory.prayers,
        icon: Icons.bedtime_outlined,
        isMandatory: true,
        isEnabled: true,
      ),

      // --- السنن والرواتب ---
      HabitItem(
        id: 'sunan_rawatib',
        title: 'السنن الرواتب',
        subtitle: '١٢ ركعة في اليوم والليلة، يُبنى لصاحبها بيت في الجنة',
        category: HabitCategory.sunan,
        icon: Icons.stars_rounded,
        isEnabled: true,
      ),
      HabitItem(
        id: 'duha_prayer',
        title: 'صلاة الضحى',
        subtitle: 'صلاة الأوّابين، تجزئ عن صدقة مفاصل الجسد',
        category: HabitCategory.sunan,
        icon: Icons.wb_sunny_rounded,
        isEnabled: true,
      ),
      HabitItem(
        id: 'witr_qiyam',
        title: 'قيام الليل والوتر',
        subtitle: 'شرف المؤمن ودأب الصالحين قبل الفجر',
        category: HabitCategory.sunan,
        icon: Icons.dark_mode_outlined,
        isEnabled: true,
      ),

      // --- الأذكار والأوراد القرآنية ---
      HabitItem(
        id: 'azkar_sabah',
        title: 'أذكار الصباح',
        subtitle: 'حصن المسلم من الفجر حتى شروق الشمس',
        category: HabitCategory.azkarAndQuran,
        icon: Icons.light_mode_outlined,
        isEnabled: true,
        route: '/zkar-details',
        routeArguments: 'أذكار الصباح',
      ),
      HabitItem(
        id: 'azkar_masaa',
        title: 'أذكار المساء',
        subtitle: 'حفظ وسكينة من العصر حتى غروب الشمس',
        category: HabitCategory.azkarAndQuran,
        icon: Icons.nightlight_round,
        isEnabled: true,
        route: '/zkar-details',
        routeArguments: 'أذكار المساء',
      ),
      HabitItem(
        id: 'azkar_sleep',
        title: 'أذكار النوم',
        subtitle: 'آية الكرسي وخواتيم البقرة والمعوذات',
        category: HabitCategory.azkarAndQuran,
        icon: Icons.bed_rounded,
        isEnabled: true,
        route: '/zkar-details',
        routeArguments: 'أذكار النوم',
      ),
      HabitItem(
        id: 'quran_wird',
        title: 'الورد القرآني اليومي',
        subtitle: 'قراءة حزب أو جزء من كتاب الله بتدبر',
        category: HabitCategory.azkarAndQuran,
        icon: Icons.menu_book_rounded,
        isEnabled: true,
        route: '/quran',
      ),
      HabitItem(
        id: 'daily_istighfar',
        title: 'الاستغفار والصلاة على النبي',
        subtitle: 'مئة مرة على الأقل طهارة للقلب وبركة للرزق',
        category: HabitCategory.azkarAndQuran,
        icon: Icons.all_inclusive_rounded,
        isEnabled: true,
        route: '/tasbeeh',
      ),

      // --- العبادات الخاصة والموسمية (ديناميكية) ---
      HabitItem(
        id: 'surah_kahf',
        title: 'سورة الكهف',
        subtitle: 'نور ما بين الجمعتين (سنة يوم الجمعة)',
        category: HabitCategory.special,
        icon: Icons.auto_stories_rounded,
        isDynamic: true,
        isEnabled: true,
        route: '/surah-details',
      ),
      HabitItem(
        id: 'fasting_sunnah',
        title: 'صيام التطوع',
        subtitle: 'صيام الإثنين أو الخميس أو الأيام البيض',
        category: HabitCategory.special,
        icon: Icons.today_rounded,
        isDynamic: true,
        isEnabled: true,
      ),
    ];
  }
}
