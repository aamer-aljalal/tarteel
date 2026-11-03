import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/services/favorites_service.dart';
import 'package:tarteel/core/services/in_app_notification_service.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'quran_reader_state.dart';

class QuranReaderCubit extends Cubit<QuranReaderState> {
  final int? initialAyah;

  static List<List<QuranAyah>> splitIntoPages(List<QuranAyah> ayahs) {
    if (ayahs.isEmpty) return [[]];
    final pageMap = <int, List<QuranAyah>>{};
    for (final ayah in ayahs) {
      pageMap.putIfAbsent(ayah.page, () => []).add(ayah);
    }
    return pageMap.values.toList();
  }

  static QuranReaderState _createInitialState({
    required QuranSurah initialSurah,
    required List<QuranAyah> initialAyahs,
    required int initialPage,
    required int? initialAyah,
  }) {
    final cachedPages = QuranService.getCachedAllPages();
    final cachedSurahs = QuranService.getCachedSurahs() ?? [initialSurah];

    if (cachedPages != null && cachedPages.isNotEmpty) {
      int targetPage = 0;
      if (initialPage >= 0 && initialPage < cachedPages.length) {
        targetPage = initialPage;
      } else if (initialAyah != null && initialAyahs.isNotEmpty) {
        final match = initialAyahs.firstWhere(
          (a) => a.verse == initialAyah,
          orElse: () => initialAyahs.first,
        );
        targetPage = (match.page - 1).clamp(0, cachedPages.length - 1);
      } else if (initialAyahs.isNotEmpty) {
        targetPage = (initialAyahs.first.page - 1).clamp(0, cachedPages.length - 1);
      } else {
        final startP = QuranService.getSurahStartPage(initialSurah.number);
        targetPage = (startP - 1).clamp(0, cachedPages.length - 1);
      }

      final pageAyahs = cachedPages[targetPage];
      final surahNum =
          pageAyahs.isNotEmpty ? pageAyahs.first.chapter : initialSurah.number;
      final activeSurah = cachedSurahs.firstWhere(
        (s) => s.number == surahNum,
        orElse: () => initialSurah,
      );

      return QuranReaderState(
        surah: activeSurah,
        ayahs: pageAyahs,
        paginatedPages: cachedPages,
        continuousPages: [initialAyahs],
        currentPage: targetPage,
        allSurahs: cachedSurahs,
        isLoading: false,
      );
    }

    return QuranReaderState(
      surah: initialSurah,
      ayahs: initialAyahs,
      paginatedPages: splitIntoPages(initialAyahs),
      continuousPages: [initialAyahs],
      currentPage: initialPage,
      allSurahs: cachedSurahs,
      isLoading: true,
    );
  }

  QuranReaderCubit({
    required QuranSurah initialSurah,
    required List<QuranAyah> initialAyahs,
    int initialPage = 0,
    this.initialAyah,
  }) : super(
         _createInitialState(
           initialSurah: initialSurah,
           initialAyahs: initialAyahs,
           initialPage: initialPage,
           initialAyah: initialAyah,
         ),
       ) {
    _initialize(initialPage);
  }

  Future<void> _initialize(int initialPage) async {
    final allSurahs = await QuranService.loadSurahs();
    final allPages = await QuranService.loadAllPages();

    int startPage = state.currentPage;

    if (state.isLoading || state.paginatedPages.length < 604) {
      if (initialPage >= 0 && initialPage < allPages.length) {
        startPage = initialPage;
      } else if (initialAyah != null && state.ayahs.isNotEmpty) {
        final match = state.ayahs.firstWhere(
          (a) => a.verse == initialAyah,
          orElse: () => state.ayahs.first,
        );
        startPage = (match.page - 1).clamp(0, allPages.length - 1);
      } else if (state.ayahs.isNotEmpty) {
        startPage = (state.ayahs.first.page - 1).clamp(0, allPages.length - 1);
      } else {
        final startP = QuranService.getSurahStartPage(state.surah.number);
        startPage = (startP - 1).clamp(0, allPages.length - 1);
      }
    }

    int? savedBookmarkPage;
    try {
      final prefs = await SharedPreferences.getInstance();
      savedBookmarkPage = prefs.getInt('quran_bookmark_page');
    } catch (_) {}

    final activeAyahs = allPages.isNotEmpty && startPage < allPages.length
        ? allPages[startPage]
        : state.ayahs;
    final activeSurahNum =
        activeAyahs.isNotEmpty ? activeAyahs.first.chapter : state.surah.number;
    final activeSurah = allSurahs.firstWhere(
      (s) => s.number == activeSurahNum,
      orElse: () => state.surah,
    );

    emit(
      state.copyWith(
        isPageView: true,
        fontSize: 20.0,
        surah: activeSurah,
        ayahs: activeAyahs,
        paginatedPages: allPages,
        currentPage: startPage,
        allSurahs: allSurahs,
        savedBookmarkPage: savedBookmarkPage,
        isLoading: false,
      ),
    );

    // 3. إشعار سورة الكهف
    if (activeSurah.number == 18) {
      InAppNotificationService.markCompleted('surah_kahf');
    }

    // 4. حفظ الإجراء الحديث (سجل التصفح الأخير)
    await _saveRecentAction(
      surah: activeSurah,
      currentPage: startPage,
      initialAyah: initialAyah,
    );
  }

  /// حفظ آخر موضع قراءة في السجل
  Future<void> _saveRecentAction({
    required QuranSurah surah,
    required int currentPage,
    required int? initialAyah,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quran_page_${surah.number}', currentPage);
      await prefs.setInt('quran_last_read_surah_number', surah.number);

      final currentAyah = initialAyah ?? 1;
      await prefs.setInt('quran_ayah_${surah.number}', currentAyah);

      await RecentActionsManager.addAction(
        category: 'quran',
        title: 'سورة ${surah.nameArabic}',
        subtitle: initialAyah != null ? 'الآية $initialAyah' : 'قراءة السورة',
        extraData: {'surah_number': surah.number, 'ayah_number': currentAyah},
      );
    } catch (_) {}
  }

  /// حفظ أو تحديث العلامة المرجعية للصفحة الحالية (يتحول الزر للون الأحمر عند الحفظ)
  Future<bool> savePageBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pageNum = state.currentPageNumber;
      final targetAyah = state.currentPageAyahs.isNotEmpty
          ? state.currentPageAyahs.first
          : (state.ayahs.isNotEmpty ? state.ayahs.first : null);

      await prefs.setInt('quran_bookmark_page', pageNum);
      await prefs.setInt('quran_bookmark_surah', state.surah.number);
      if (targetAyah != null) {
        await prefs.setInt('quran_bookmark_ayah', targetAyah.verse);
      }

      emit(state.copyWith(savedBookmarkPage: pageNum));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// الانتقال إلى صفحة أخرى عبر تقليب الصفحات
  void changePage(int index) {
    if (index >= 0 && index < state.totalPages) {
      final pageAyahs = state.pages[index];
      final surahNumber = pageAyahs.isNotEmpty
          ? pageAyahs.first.chapter
          : state.surah.number;
      final currentSurah = state.allSurahs.firstWhere(
        (s) => s.number == surahNumber,
        orElse: () => state.surah,
      );

      emit(
        state.copyWith(
          currentPage: index,
          surah: currentSurah,
          ayahs: pageAyahs,
          hasChangedPage: true,
        ),
      );

      _saveRecentAction(
        surah: currentSurah,
        currentPage: index,
        initialAyah: pageAyahs.isNotEmpty ? pageAyahs.first.verse : null,
      );

      if (currentSurah.number == 18) {
        InAppNotificationService.markCompleted('surah_kahf');
      }
    }
  }

  /// الانتقال إلى سورة أخرى مباشرة (مع دعم الانتقال لآخر صفحة عند التقليب للخلف)
  Future<void> navigateToSurah(int surahNumber, {bool toLastPage = false}) async {
    try {
      final surahs = state.allSurahs.isNotEmpty
          ? state.allSurahs
          : await QuranService.loadSurahs();
      final targetSurah = surahs.firstWhere((s) => s.number == surahNumber);

      final targetPageNumber = toLastPage
          ? QuranService.getSurahEndPage(surahNumber)
          : QuranService.getSurahStartPage(surahNumber);
      final targetIndex = (targetPageNumber - 1).clamp(0, state.totalPages - 1);
      final pageAyahs = state.pages.isNotEmpty && targetIndex < state.pages.length
          ? state.pages[targetIndex]
          : await QuranService.loadAyahs(surahNumber);

      emit(
        state.copyWith(
          surah: targetSurah,
          ayahs: pageAyahs,
          currentPage: targetIndex,
          hasChangedPage: true,
        ),
      );

      await _saveRecentAction(
        surah: targetSurah,
        currentPage: targetIndex,
        initialAyah: pageAyahs.isNotEmpty ? pageAyahs.first.verse : null,
      );
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'تعذر فتح السورة: $e'),
      );
    }
  }

  /// نسخ الآية للحافظة
  Future<void> copyAyah(QuranAyah ayah) async {
    await Clipboard.setData(
      ClipboardData(
        text:
            'سورة ${state.surah.nameArabic} - الآية ${ayah.verse}\n\n${ayah.text}',
      ),
    );
  }

  /// إضافة أو إزالة الآية من المفضلة عبر FavoritesService الموحدة
  Future<bool> toggleFavoriteAyah({
    required QuranAyah ayah,
    required String interpretation,
  }) async {
    final key = '${ayah.chapter}:${ayah.verse}';
    return await FavoritesService.toggleFavorite(
      type: 'quran',
      key: key,
      content: ayah.text,
      title: 'سورة ${state.surah.nameArabic}',
      description: interpretation,
      extraData: {
        'surahNumber': ayah.chapter,
        'surahName': state.surah.nameArabic,
        'ayahNumber': ayah.verse,
        'ayahText': ayah.text,
        'interpretation': interpretation,
      },
    );
  }
}
