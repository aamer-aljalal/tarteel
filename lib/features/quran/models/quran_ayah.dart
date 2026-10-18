class QuranAyah {
  const QuranAyah({
    required this.chapter,
    required this.verse,
    required this.text,
    this.page = 1,
    this.juz = 1,
    this.hizbQuarter = 1,
    this.hasSajdah = false,
  });

  final int chapter;
  final int verse;
  final String text;
  final int page;
  final int juz;
  final int hizbQuarter;
  final bool hasSajdah;

  /// رقم الحزب (من 1 إلى 60)
  int get hizb => ((hizbQuarter - 1) ~/ 4) + 1;

  /// الربع داخل الحزب (من 1 إلى 4)
  int get quarterInHizb => ((hizbQuarter - 1) % 4) + 1;

  factory QuranAyah.fromJson(Map<String, dynamic> json) {
    return QuranAyah(
      chapter: json['chapter'] as int? ?? json['surah'] as int? ?? 1,
      verse: json['verse'] as int? ?? json['numberInSurah'] as int? ?? 1,
      text: json['text'] as String? ?? '',
      page: json['page'] as int? ?? 1,
      juz: json['juz'] as int? ?? 1,
      hizbQuarter: json['hizbQuarter'] as int? ?? 1,
      hasSajdah: json['hasSajdah'] as bool? ??
          (json['sajda'] != null && json['sajda'] != false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapter': chapter,
      'verse': verse,
      'text': text,
      'page': page,
      'juz': juz,
      'hizbQuarter': hizbQuarter,
      'hasSajdah': hasSajdah,
    };
  }
}
