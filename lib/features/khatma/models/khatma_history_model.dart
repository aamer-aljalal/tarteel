import 'khatma_plan_model.dart';
import 'khatma_badge_model.dart';

class KhatmaHistoryModel {
  final String id;
  final String title;
  final KhatmaPlanType type;
  final DateTime startDate;
  final DateTime completedDate;
  final int daysTaken;
  final int totalPages;
  final List<KhatmaBadgeModel> badges;

  const KhatmaHistoryModel({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    required this.completedDate,
    required this.daysTaken,
    this.totalPages = 604,
    this.badges = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'completedDate': completedDate.toIso8601String(),
      'daysTaken': daysTaken,
      'totalPages': totalPages,
      'badges': badges.map((b) => b.toJson()).toList(),
    };
  }

  factory KhatmaHistoryModel.fromJson(Map<String, dynamic> json) {
    final rawBadges = json['badges'] as List<dynamic>?;
    final badgesList = rawBadges != null
        ? rawBadges
            .whereType<Map>()
            .map((b) =>
                KhatmaBadgeModel.fromJson(Map<String, dynamic>.from(b)))
            .toList()
        : KhatmaBadgeModel.defaultBadges();

    return KhatmaHistoryModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: KhatmaPlanType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => KhatmaPlanType.durationDays,
      ),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      completedDate: DateTime.tryParse(json['completedDate']?.toString() ?? '') ?? DateTime.now(),
      daysTaken: (json['daysTaken'] as num?)?.toInt() ?? 30,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 604,
      badges: badgesList,
    );
  }
}
