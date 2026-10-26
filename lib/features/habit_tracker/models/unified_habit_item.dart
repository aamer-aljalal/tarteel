import 'package:flutter/material.dart';

/// ==============================================================================
/// نوع عنصر العبادة اليومية
/// ==============================================================================
enum UnifiedHabitType {
  prayerFard,       // فريضة
  prayerSunnah,     // سنة مؤكدة / مستحبة
  azkar,            // أذكار الصباح والمساء وبعد الصلاة والنوم
  quran,            // ورد القرآن / سورة الكهف / خطة الختمة
  tasbeeh,          // ورد التسبيح والاستغفار
  fasting,          // صيام النوافل (الإثنين والخميس والبيض)
  qiyam,            // قيام الليل والشفع والوتر
}

/// ==============================================================================
/// نموذج العبادة الموحدة في الجدول اليومي الذكي
/// ==============================================================================
class UnifiedHabitItem {
  final String id;
  final String title;
  final String subtitle;
  final String timeLabel;
  final String badgeText;
  final IconData icon;
  final UnifiedHabitType type;
  final bool isMandatory;
  final String? actionText;
  final String? route;
  final dynamic routeArguments;
  final int sortOrder;

  const UnifiedHabitItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.badgeText,
    required this.icon,
    required this.type,
    this.isMandatory = false,
    this.actionText,
    this.route,
    this.routeArguments,
    required this.sortOrder,
  });
}
