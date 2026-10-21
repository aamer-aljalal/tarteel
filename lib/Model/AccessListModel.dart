/// ==============================================================================
///  وصف الملف: AccessListModel.dart
/// ==============================================================================
/// هذا الملف هو نموذج البيانات (Data Model) الخاص بعناصر وأزرار شبكة الوصول السريع
/// في الصفحة الرئيسية للتطبيق (مثل: القرآن، الأذكار، حصن المسلم، التسبيح، إلخ).
///
///  التحسينات والوظائف الجديدة المضافة في هذا التحديث:
/// 1. إمكانية التحويل من وإلى JSON (دعم السيرفر وجيت هب والتخزين المحلي).
/// 2. خاصية (Icon Mapper) الذكية: تحويل اسم الأيقونة النصي (مثل "quiz" أو "quran")
///    إلى أيقونة فلاتر المقابلة لها برمجياً (Icons.menu_book).
/// 3. إضافة حقل معرّف اختياري (id) وحالة التفعيل (isEnabled) لسهولة إظهار أو إخفاء الزر.
/// 4. الحفاظ على التوافق التام 100% مع الأكواد الحالية للتطبيق دون كسر أي مكان.
/// ==============================================================================
library;

import 'package:flutter/material.dart';

class AccessListModel {
  /// معرّف فريد للزر (مثل: "quran", "azkar", "islamic_quiz")
  final String? id;

  /// عنوان الزر الظاهر للمستخدم (مثل: "القرآن", "المسابقات")
  final String title;

  /// مسار الانتقال للصفحة عند الضغط (مثل: AppRoutes.quran أو "/islamic-quiz")
  final String route;

  /// أيقونة الزر في فلاتر
  final IconData icon;

  /// اسم الأيقونة النصي (يُستخدم عند الاستلام من JSON أو جيت هب)
  final String? iconName;

  /// هل الزر مفعّل وظاهر للمستخدم (الافتراضي: true)
  final bool isEnabled;

  /// شارة إضافية تظهر فوق الزر اختيارياً (مثل: "جديد")
  final String? badge;

  /// بيانات ومعاملات إضافية يمكن تمريرها مع المسار
  final dynamic arguments;

  /// تفاصيل أو وصف إضافي يظهر تحت العنوان عند العرض المستطيل
  final String? subtitle;

  /// اسم بديل للحصول على تفاصيل العنوان
  String? get details => subtitle;

  const AccessListModel({
    this.id,
    required this.title,
    required this.route,
    required this.icon,
    this.iconName,
    this.isEnabled = true,
    this.badge,
    this.arguments,
    String? subtitle,
    String? details,
  }) : subtitle = subtitle ?? details;

  // ============================================================================
  //  التحويل من JSON إلى كائن AccessListModel (عند الجلب من جيت هب أو التخزين)
  // ============================================================================
  factory AccessListModel.fromJson(Map<String, dynamic> json) {
    // قراءة اسم الأيقونة كنص، ثم تحويلها إلى أيقونة فلاتر الفعلية
    final iconString = json['icon'] as String? ?? 'help';
    final resolvedIcon = _getIconDataFromName(iconString);

    return AccessListModel(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      route: json['route'] as String? ?? '',
      icon: resolvedIcon,
      iconName: iconString,
      isEnabled: json['isEnabled'] as bool? ?? true,
      badge: json['badge'] as String?,
      arguments: json['arguments'],
      subtitle: json['subtitle'] as String? ?? json['details'] as String? ?? json['description'] as String?,
    );
  }

  // ============================================================================
  //  التحويل من كائن AccessListModel إلى خريطة JSON (لأغراض الحفظ المحلي والتخزين)
  // ============================================================================
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'route': route,
      'icon': iconName ?? _guessIconName(icon),
      'isEnabled': isEnabled,
      if (badge != null) 'badge': badge,
      if (arguments != null) 'arguments': arguments,
      if (subtitle != null) 'subtitle': subtitle,
    };
  }

  // ============================================================================
  //  القاموس الذكي للأيقونات: يحول النص القادم من جيت هب إلى أيقونة فلاتر حقيقية
  // ============================================================================
  static IconData _getIconDataFromName(String name) {
    switch (name.toLowerCase().trim()) {
      // القرآن الكريم
      case 'quran':
      case 'menu_book':
      case 'book':
        return Icons.menu_book_outlined;

      // الأذكار
      case 'azkar':
      case 'bookmark':
        return Icons.bookmark_outline;

      // حصن المسلم
      case 'hisn':
      case 'auto_stories':
        return Icons.auto_stories_outlined;

      // الأحاديث النبوية
      case 'hadith':
      case 'format_quote':
        return Icons.format_quote_outlined;

      // التسبيح والمسبحة
      case 'tasbeeh':
      case 'timer':
        return Icons.timer_outlined;

      // أسماء الله الحسنى
      case 'names_of_allah':
      case 'auto_awesome':
      case 'stars':
        return Icons.auto_awesome_outlined;

      // قصص الأنبياء
      case 'prophets':
      case 'import_contacts':
        return Icons.import_contacts_outlined;

      // الأذان والمؤذن
      case 'adhan':
      case 'muezzin':
      case 'record_voice_over':
        return Icons.record_voice_over_outlined;

      // القبلة والبوصلة
      case 'qibla':
      case 'compass':
      case 'explore':
        return Icons.explore_outlined;

      // المفضلة
      case 'favorite':
      case 'bookmarks':
        return Icons.favorite_border;

      // الإحصائيات
      case 'stats':
      case 'analytics':
        return Icons.analytics_outlined;

      // الإعدادات
      case 'settings':
        return Icons.settings_outlined;

      //  الميزات الجديدة (المسابقات والتحديات، تعليم الصلاة)
      case 'quiz':
      case 'competition':
      case 'question':
        return Icons.quiz_outlined;

      case 'prayer_guide':
      case 'prayer':
      case 'mosque':
        return Icons.mosque_outlined;

      // يوميات المسلم وسجل العبادات
      case 'habit_tracker':
      case 'habits':
      case 'tracker':
      case 'daily_worship':
        return Icons.task_alt_rounded;

      // الأيقونة الافتراضية إذا لم يتم التعرف على الاسم
      default:
        return Icons.widgets_outlined;
    }
  }

  // ============================================================================
  //  دالة مساعدة لتخمين الاسم النصي عند تحويل الكائن الحالي إلى JSON
  // ============================================================================
  static String _guessIconName(IconData icon) {
    if (icon == Icons.menu_book_outlined) return 'quran';
    if (icon == Icons.bookmark_outline) return 'azkar';
    if (icon == Icons.auto_stories_outlined) return 'hisn';
    if (icon == Icons.format_quote_outlined) return 'hadith';
    if (icon == Icons.timer_outlined) return 'tasbeeh';
    if (icon == Icons.auto_awesome_outlined) return 'names_of_allah';
    if (icon == Icons.import_contacts_outlined) return 'prophets';
    if (icon == Icons.record_voice_over_outlined) return 'adhan';
    if (icon == Icons.explore_outlined) return 'qibla';
    if (icon == Icons.favorite_border) return 'bookmarks';
    if (icon == Icons.analytics_outlined) return 'stats';
    if (icon == Icons.settings_outlined) return 'settings';
    if (icon == Icons.quiz_outlined) return 'quiz';
    return 'widgets';
  }
}
