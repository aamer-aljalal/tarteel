class ZekrModel {

  final String category;

  final String count;

  final String description;

  final String reference;

  final String content;

  int currentCount;

  ZekrModel({
    required this.category,
    required this.count,
    required this.description,
    required this.reference,
    required this.content,
    this.currentCount = 0,
  });

  factory ZekrModel.fromJson(Map<String, dynamic> json) {
    return ZekrModel(
      category: json['category']?.toString() ?? '',
      count: json['count']?.toString() ?? '1',
      description: json['description']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      content: json['content']?.toString() ?? json['zekr']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'count': count,
      'description': description,
      'reference': reference,
      'content': content,
    };
  }
}