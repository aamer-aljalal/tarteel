import 'package:flutter/material.dart';

enum MilestoneType {
  quarter, // ربع القرآن (صفحة 151 - سورة الأنعام)
  half, // نصف القرآن (صفحة 302 - سورة الكهف)
  threeQuarters, // ثلاثة أرباع القرآن (صفحة 453 - سورة يس)
  complete, // ختم القرآن كاملاً (صفحة 604)
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

  factory KhatmaBadgeModel.fromJson(Map<String, dynamic> json, IconData icon) {
    return KhatmaBadgeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      targetPage: json['targetPage'] as int,
      milestoneType: MilestoneType.values.firstWhere(
        (m) => m.name == json['milestoneType'],
        orElse: () => MilestoneType.quarter,
      ),
      icon: icon,
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
