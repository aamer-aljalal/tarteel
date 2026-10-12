import 'package:tarteel/features/azkar/model/zekr_model%20.dart';

class ZekrCategory {
  final int id;
  final String title;
  final List<ZekrModel> azkar;

  ZekrCategory({
    required this.id,
    required this.title,
    required this.azkar,
  });

  factory ZekrCategory.fromJson(Map<String, dynamic> json) {
    return ZekrCategory(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      azkar: (json['azkar'] as List? ?? [])
          .map((e) => ZekrModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'azkar': azkar.map((e) => e.toJson()).toList(),
    };
  }
}
