import 'khatma_badge_model.dart';

enum KhatmaPlanType {
  prayers, // مسار الصلوات الخمس
  dailyPages, // مسار الورد اليومي الثابت بالصفحات
  durationDays, // مسار المدة المحددة بالأيام
  freeReading, // مسار القراءة الحرة بدون وقت
}

class KhatmaPlanModel {
  final String id;
  final String title;
  final KhatmaPlanType type;
  final int targetPagesPerDay;
  final int targetDays;
  final DateTime startDate;
  final DateTime? completedDate;
  final int currentPage; // من 1 إلى 604
  final int pagesReadToday;
  final DateTime? lastReadDate;
  final int reminderHour;
  final int reminderMinute;
  final bool isCompleted;
  final List<KhatmaBadgeModel> badges;

  const KhatmaPlanModel({
    required this.id,
    required this.title,
    required this.type,
    required this.targetPagesPerDay,
    required this.targetDays,
    required this.startDate,
    this.completedDate,
    this.currentPage = 1,
    this.pagesReadToday = 0,
    this.lastReadDate,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.isCompleted = false,
    this.badges = const [],
  });

  static const int totalQuranPages = 604;

  double get progressPercentage {
    if (currentPage <= 1) return 0.0;
    return (currentPage / totalQuranPages).clamp(0.0, 1.0);
  }

  int get remainingPages {
    final remaining = totalQuranPages - currentPage;
    return remaining < 0 ? 0 : remaining;
  }

  int get daysRemaining {
    if (type == KhatmaPlanType.freeReading) return 0;
    final total = targetDays;
    final elapsed = DateTime.now().difference(startDate).inDays;
    final rem = total - elapsed;
    return rem.clamp(0, total);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'targetPagesPerDay': targetPagesPerDay,
      'targetDays': targetDays,
      'startDate': startDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'currentPage': currentPage,
      'pagesReadToday': pagesReadToday,
      'lastReadDate': lastReadDate?.toIso8601String(),
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'isCompleted': isCompleted,
      'badges': badges.map((b) => b.toJson()).toList(),
    };
  }

  factory KhatmaPlanModel.fromJson(Map<String, dynamic> json) {
    final rawBadges = json['badges'] as List<dynamic>?;
    final badgesList = rawBadges != null
        ? rawBadges
            .whereType<Map<String, dynamic>>()
            .map((b) => KhatmaBadgeModel.fromJson(b))
            .toList()
        : KhatmaBadgeModel.defaultBadges();

    return KhatmaPlanModel(
      id: json['id']?.toString() ?? 'khatma_1',
      title: json['title']?.toString() ?? 'ختمة القرآن الكريم',
      type: KhatmaPlanType.values.firstWhere(
        (t) => t.name == json['type']?.toString(),
        orElse: () => KhatmaPlanType.durationDays,
      ),
      targetPagesPerDay: (json['targetPagesPerDay'] as num?)?.toInt() ?? 20,
      targetDays: (json['targetDays'] as num?)?.toInt() ?? 30,
      startDate: json['startDate'] != null
          ? (DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now())
          : DateTime.now(),
      completedDate: json['completedDate'] != null
          ? DateTime.tryParse(json['completedDate'].toString())
          : null,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      pagesReadToday: (json['pagesReadToday'] as num?)?.toInt() ?? 0,
      lastReadDate: json['lastReadDate'] != null
          ? DateTime.tryParse(json['lastReadDate'].toString())
          : null,
      reminderHour: (json['reminderHour'] as num?)?.toInt() ?? 20,
      reminderMinute: (json['reminderMinute'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      badges: badgesList.isEmpty ? KhatmaBadgeModel.defaultBadges() : badgesList,
    );
  }

  KhatmaPlanModel copyWith({
    String? id,
    String? title,
    KhatmaPlanType? type,
    int? targetPagesPerDay,
    int? targetDays,
    DateTime? startDate,
    DateTime? completedDate,
    int? currentPage,
    int? pagesReadToday,
    DateTime? lastReadDate,
    int? reminderHour,
    int? reminderMinute,
    bool? isCompleted,
    List<KhatmaBadgeModel>? badges,
  }) {
    return KhatmaPlanModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      targetPagesPerDay: targetPagesPerDay ?? this.targetPagesPerDay,
      targetDays: targetDays ?? this.targetDays,
      startDate: startDate ?? this.startDate,
      completedDate: completedDate ?? this.completedDate,
      currentPage: currentPage ?? this.currentPage,
      pagesReadToday: pagesReadToday ?? this.pagesReadToday,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isCompleted: isCompleted ?? this.isCompleted,
      badges: badges ?? this.badges,
    );
  }
}
