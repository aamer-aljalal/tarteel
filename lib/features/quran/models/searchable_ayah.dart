import 'quran_ayah.dart';
import 'quran_surah.dart';

class SearchableAyah {
  const SearchableAyah({
    required this.ayah,
    required this.surah,
    required this.normalizedText,
  });

  final QuranAyah ayah;
  final QuranSurah surah;
  final String normalizedText;
}
