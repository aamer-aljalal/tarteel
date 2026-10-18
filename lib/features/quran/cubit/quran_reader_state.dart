import 'package:tarteel/features/quran/models/quran_models.dart';

class QuranReaderState {
  final QuranSurah surah;
  final List<QuranAyah> ayahs;
  final List<List<QuranAyah>> paginatedPages;
  final List<List<QuranAyah>> continuousPages;
  final bool isPageView;
  final double fontSize;
  final int currentPage;
  final bool isLoading;
  final String? errorMessage;
  final List<QuranSurah> allSurahs;
  final bool hasBookmarkedInThisSession;
  final bool hasChangedPage;

  const QuranReaderState({
    required this.surah,
    required this.ayahs,
    required this.paginatedPages,
    required this.continuousPages,
    this.isPageView = false,
    this.fontSize = 20.0,
    this.currentPage = 0,
    this.isLoading = false,
    this.errorMessage,
    this.allSurahs = const [],
    this.hasBookmarkedInThisSession = false,
    this.hasChangedPage = false,
  });

  /// الصفحات النشطة وفقاً للنمط المختار (صفحات vs قائمة متصلة)
  List<List<QuranAyah>> get pages =>
      isPageView ? paginatedPages : continuousPages;

  /// إجمالي عدد الصفحات
  int get totalPages => pages.length;

  /// السورة التالية
  QuranSurah? get nextSurah {
    if (allSurahs.isEmpty) return null;
    final nextNumber = surah.number + 1;
    if (nextNumber > 114) return null;
    try {
      return allSurahs.firstWhere((s) => s.number == nextNumber);
    } catch (_) {
      return null;
    }
  }

  /// السورة السابقة
  QuranSurah? get prevSurah {
    if (allSurahs.isEmpty) return null;
    final prevNumber = surah.number - 1;
    if (prevNumber < 1) return null;
    try {
      return allSurahs.firstWhere((s) => s.number == prevNumber);
    } catch (_) {
      return null;
    }
  }

  /// رقم الجزء الحالي المعروض بدقة
  int get currentJuz {
    final currentPages = pages;
    if (currentPage >= 0 &&
        currentPage < currentPages.length &&
        currentPages[currentPage].isNotEmpty) {
      return currentPages[currentPage].first.juz;
    }
    return ayahs.isNotEmpty ? ayahs.first.juz : 1;
  }

  /// رقم الحزب الحالي المعروض بدقة
  int get currentHizb {
    final currentPages = pages;
    if (currentPage >= 0 &&
        currentPage < currentPages.length &&
        currentPages[currentPage].isNotEmpty) {
      return currentPages[currentPage].first.hizb;
    }
    return ayahs.isNotEmpty ? ayahs.first.hizb : 1;
  }

  /// رقم الصفحة الحالية المعروضة بمصحف المدينة
  int get currentPageNumber {
    final currentPages = pages;
    if (currentPage >= 0 &&
        currentPage < currentPages.length &&
        currentPages[currentPage].isNotEmpty) {
      return currentPages[currentPage].first.page;
    }
    return ayahs.isNotEmpty ? ayahs.first.page : 1;
  }

  /// نص مؤشر الصفحة الدقيق لمصحف المدينة
  String getPageIndicatorText(int index) {
    if (index >= 0 && index < pages.length && pages[index].isNotEmpty) {
      final firstAyah = pages[index].first;
      return 'الجزء ${firstAyah.juz} • الحزب ${firstAyah.hizb} • صفحة ${firstAyah.page}';
    }
    return '${index + 1}';
  }

  QuranReaderState copyWith({
    QuranSurah? surah,
    List<QuranAyah>? ayahs,
    List<List<QuranAyah>>? paginatedPages,
    List<List<QuranAyah>>? continuousPages,
    bool? isPageView,
    double? fontSize,
    int? currentPage,
    bool? isLoading,
    String? errorMessage,
    List<QuranSurah>? allSurahs,
    bool? hasBookmarkedInThisSession,
    bool? hasChangedPage,
  }) {
    return QuranReaderState(
      surah: surah ?? this.surah,
      ayahs: ayahs ?? this.ayahs,
      paginatedPages: paginatedPages ?? this.paginatedPages,
      continuousPages: continuousPages ?? this.continuousPages,
      isPageView: isPageView ?? this.isPageView,
      fontSize: fontSize ?? this.fontSize,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      allSurahs: allSurahs ?? this.allSurahs,
      hasBookmarkedInThisSession:
          hasBookmarkedInThisSession ?? this.hasBookmarkedInThisSession,
      hasChangedPage: hasChangedPage ?? this.hasChangedPage,
    );
  }
}
