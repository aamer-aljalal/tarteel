enum NameCategory {
  allah,
  prophet,
}

class AllahName {
  final int id;
  final String name;
  final String text;
  final NameCategory category;

  const AllahName({
    required this.id,
    required this.name,
    required this.text,
    this.category = NameCategory.allah,
  });

  factory AllahName.fromJson(
    Map<String, dynamic> json, {
    NameCategory category = NameCategory.allah,
    int? fallbackId,
  }) {
    return AllahName(
      id: json['id'] ?? fallbackId ?? 0,
      name: json['name'] ?? '',
      text: json['text'] ?? '',
      category: category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'text': text,
      'category': category.name,
    };
  }
}
