import 'package:flutter/material.dart';

enum MilestoneType {
  quarter, // ربع القرآن (صفحة 151 - سورة الأنعام)
  half, // نصف القرآن (صفحة 302 - سورة الكهف)
  threeQuarters, // ثلاثة أرباع القرآن (صفحة 453 - سورة يس)
  complete, // ختم القرآن كاملاً (صفحة 604)
}

/// فئة بيانات تعريفية مخصصة لكل رتبة من رتب الأوسمة
class MilestoneBadgeStyle {
  final String tierTitle;
  final String tierSubtitle;
  final String quote;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Color> cardGradient;
  final List<Color> emblemGradient;
  final Color glowColor;
  final Color badgeBg;
  final Color chipBg;
  final IconData icon;

  const MilestoneBadgeStyle({
    required this.tierTitle,
    required this.tierSubtitle,
    required this.quote,
    required this.primaryColor,
    required this.secondaryColor,
    required this.cardGradient,
    required this.emblemGradient,
    required this.glowColor,
    required this.badgeBg,
    required this.chipBg,
    required this.icon,
  });
}

class KhatmaBadgeModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int targetPage;
  final MilestoneType milestoneType;
  final IconData icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const KhatmaBadgeModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.targetPage,
    required this.milestoneType,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  MilestoneBadgeStyle get style => styleForType(milestoneType);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'targetPage': targetPage,
      'milestoneType': milestoneType.name,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  static MilestoneBadgeStyle styleForType(MilestoneType type) {
    switch (type) {
      case MilestoneType.quarter:
        return const MilestoneBadgeStyle(
          tierTitle: 'الرتبة البرونزية',
          tierSubtitle: 'نور البدايات • سورة الأنعام',
          quote: '« خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ »',
          primaryColor: Color(0xFFD48B46),
          secondaryColor: Color(0xFF8A4F1D),
          cardGradient: [Color(0xFF142B20), Color(0xFF091711)],
          emblemGradient: [Color(0xFFE5A162), Color(0xFF8A4F1D)],
          glowColor: Color(0x55D48B46),
          badgeBg: Color(0xFF18221B),
          chipBg: Color(0x33D48B46),
          icon: Icons.menu_book_rounded,
        );
      case MilestoneType.half:
        return const MilestoneBadgeStyle(
          tierTitle: 'الرتبة الفضية',
          tierSubtitle: 'نور الانتصاف • سورة الكهف',
          quote: '« مَنْ قَرَأَ سُورَةَ الْكَهْفِ كَانَتْ لَهُ نُوراً يَوْمَ الْقِيَامَةِ »',
          primaryColor: Color(0xFFCDE1EE),
          secondaryColor: Color(0xFF67899F),
          cardGradient: [Color(0xFF0F2636), Color(0xFF07141E)],
          emblemGradient: [Color(0xFFEAF5FC), Color(0xFF6B8FA7)],
          glowColor: Color(0x55A8CEE8),
          badgeBg: Color(0xFF0F202C),
          chipBg: Color(0x33CDE1EE),
          icon: Icons.brightness_medium_rounded,
        );
      case MilestoneType.threeQuarters:
        return const MilestoneBadgeStyle(
          tierTitle: 'الرتبة الذهبية',
          tierSubtitle: 'شرف الارتقاء • سورة يس',
          quote: '« إِنَّ لِكُلِّ شَيْءٍ قَلْباً، وَقَلْبُ الْقُرْآنِ يس »',
          primaryColor: Color(0xFFFFD13B),
          secondaryColor: Color(0xFFB57C14),
          cardGradient: [Color(0xFF261E0E), Color(0xFF130E05)],
          emblemGradient: [Color(0xFFFFE07A), Color(0xFFB57C14)],
          glowColor: Color(0x55FFD13B),
          badgeBg: Color(0xFF1F170A),
          chipBg: Color(0x33FFD13B),
          icon: Icons.auto_awesome_rounded,
        );
      case MilestoneType.complete:
        return const MilestoneBadgeStyle(
          tierTitle: 'التاج الملكي الألماسي',
          tierSubtitle: 'ذروة الإنجاز • ختام المصحف الشريف',
          quote: '« يُقَالُ لِصَاحِبِ الْقُرْآنِ: اقْرَأْ وَارْتَقِ وَرَتِّلْ كَمَا كُنْتَ تُرَتِّلُ فِي الدُّنْيَا، فَإِنَّ مَنْزِلَتَكَ عِنْدَ آخِرِ آيَةٍ تَقْرَؤُهَا »',
          primaryColor: Color(0xFFFEE180),
          secondaryColor: Color(0xFF10B981),
          cardGradient: [Color(0xFF0D3325), Color(0xFF04150E)],
          emblemGradient: [Color(0xFFFFF7CF), Color(0xFFE2B755), Color(0xFF9E7728)],
          glowColor: Color(0x66FEE180),
          badgeBg: Color(0xFF08241A),
          chipBg: Color(0x33FEE180),
          icon: Icons.workspace_premium_rounded,
        );
    }
  }

  static IconData iconForType(MilestoneType type) => styleForType(type).icon;

  factory KhatmaBadgeModel.fromJson(Map<String, dynamic> json, [IconData? icon]) {
    final milestoneType = MilestoneType.values.firstWhere(
      (m) => m.name == json['milestoneType'],
      orElse: () => MilestoneType.quarter,
    );
    return KhatmaBadgeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      targetPage: json['targetPage'] as int,
      milestoneType: milestoneType,
      icon: icon ?? iconForType(milestoneType),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  KhatmaBadgeModel copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return KhatmaBadgeModel(
      id: id,
      title: title,
      subtitle: subtitle,
      description: description,
      targetPage: targetPage,
      milestoneType: milestoneType,
      icon: icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  /// قائمة الأوسمة والمحطات الأساسية الأربعة
  static List<KhatmaBadgeModel> defaultBadges() {
    return const [
      KhatmaBadgeModel(
        id: 'milestone_quarter',
        title: 'وسام ربع القرآن الكريم',
        subtitle: 'بلوغ الصفحة 151',
        description: 'هنيئاً لك إتمام ربع كتاب الله تعالى والوصول إلى سورة الأنعام المباركة.',
        targetPage: 151,
        milestoneType: MilestoneType.quarter,
        icon: Icons.menu_book_rounded,
      ),
      KhatmaBadgeModel(
        id: 'milestone_half',
        title: 'وسام نصف القرآن الكريم',
        subtitle: 'بلوغ الصفحة 302',
        description: 'ما شاء الله، بلغت منتصف كتاب الله العظيم عند سورة الكهف الشريفة.',
        targetPage: 302,
        milestoneType: MilestoneType.half,
        icon: Icons.star_half_rounded,
      ),
      KhatmaBadgeModel(
        id: 'milestone_three_quarters',
        title: 'وسام ثلاثة أرباع القرآن الكريم',
        subtitle: 'بلوغ الصفحة 453',
        description: 'بوركت خطاك، شارفت على ختام المصحف وبلغت قلب القرآن سورة يس.',
        targetPage: 453,
        milestoneType: MilestoneType.threeQuarters,
        icon: Icons.auto_awesome_rounded,
      ),
      KhatmaBadgeModel(
        id: 'milestone_complete',
        title: 'تاج الختمة المباركة',
        subtitle: 'إتمام المصحف الشريف كاملاً (604 صفحة)',
        description: 'الحمد لله الذي بنعمته تتم الصالحات، أتممت قراءة القرآن الكريم كاملاً.',
        targetPage: 604,
        milestoneType: MilestoneType.complete,
        icon: Icons.workspace_premium_rounded,
      ),
    ];
  }
}
