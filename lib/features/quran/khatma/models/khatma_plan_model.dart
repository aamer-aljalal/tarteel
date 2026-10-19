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
    };
  }

  factory KhatmaPlanModel.fromJson(Map<String, dynamic> json) {
    return KhatmaPlanModel(
      id: json['id'] as String? ?? 'khatma_1',
      title: json['title'] as String? ?? 'ختمة القرآن الكريم',
      type: KhatmaPlanType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => KhatmaPlanType.durationDays,
      ),
      targetPagesPerDay: json['targetPagesPerDay'] as int? ?? 20,
      targetDays: json['targetDays'] as int? ?? 30,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      currentPage: json['currentPage'] as int? ?? 1,
      pagesReadToday: json['pagesReadToday'] as int? ?? 0,
      lastReadDate: json['lastReadDate'] != null
          ? DateTime.parse(json['lastReadDate'] as String)
          : null,
      reminderHour: json['reminderHour'] as int? ?? 20,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
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
    );
  }
}
