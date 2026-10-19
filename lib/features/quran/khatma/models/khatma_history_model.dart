import 'khatma_plan_model.dart';

class KhatmaHistoryModel {
  final String id;
  final String title;
  final KhatmaPlanType type;
  final DateTime startDate;
  final DateTime completedDate;
  final int daysTaken;
  final int totalPages;

  const KhatmaHistoryModel({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    required this.completedDate,
    required this.daysTaken,
    this.totalPages = 604,
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
    };
  }

  factory KhatmaHistoryModel.fromJson(Map<String, dynamic> json) {
    return KhatmaHistoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: KhatmaPlanType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => KhatmaPlanType.durationDays,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      completedDate: DateTime.parse(json['completedDate'] as String),
      daysTaken: json['daysTaken'] as int? ?? 30,
      totalPages: json['totalPages'] as int? ?? 604,
    );
  }
}
