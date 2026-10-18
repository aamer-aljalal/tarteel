class QuranSurah {
  const QuranSurah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.transliteration,
    required this.revelationPlace,
    required this.versesCount,
  });

  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String transliteration;
  final String revelationPlace;
  final int versesCount;

  bool get isMakki => revelationPlace.toLowerCase() == 'makkah';

  factory QuranSurah.fromJson(Map<String, dynamic> json) {
    return QuranSurah(
      number: json['number'] as int,
      nameArabic: json['name'] as String? ?? json['nameArabic'] as String? ?? '',
      nameEnglish: json['englishName'] as String? ?? json['nameEnglish'] as String? ?? '',
      transliteration: json['englishNameTranslation'] as String? ?? json['transliteration'] as String? ?? '',
      revelationPlace: json['revelationType'] as String? ?? json['revelationPlace'] as String? ?? '',
      versesCount: json['numberOfAyahs'] as int? ?? json['versesCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'nameArabic': nameArabic,
      'nameEnglish': nameEnglish,
      'transliteration': transliteration,
      'revelationPlace': revelationPlace,
      'versesCount': versesCount,
    };
  }
}
