import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/services/favorites_service.dart';
import 'package:tarteel/core/services/in_app_notification_service.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/services/stats_service.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'quran_reader_state.dart';

class QuranReaderCubit extends Cubit<QuranReaderState> {
  final bool isKhatmaSession;
  final int? initialAyah;

  static List<List<QuranAyah>> splitIntoPages(List<QuranAyah> ayahs) {
    if (ayahs.isEmpty) return [[]];
    final pageMap = <int, List<QuranAyah>>{};
    for (final ayah in ayahs) {
      pageMap.putIfAbsent(ayah.page, () => []).add(ayah);
    }
    return pageMap.values.toList();
  }

  QuranReaderCubit({
    required QuranSurah initialSurah,
    required List<QuranAyah> initialAyahs,
    int initialPage = 0,
    this.initialAyah,
    this.isKhatmaSession = false,
  }) : super(
         QuranReaderState(
           surah: initialSurah,
           ayahs: initialAyahs,
           paginatedPages: splitIntoPages(initialAyahs),
           continuousPages: [initialAyahs],
           currentPage: initialPage,
         ),
       ) {
    _initialize(initialPage);
  }

  Future<void> _initialize(int initialPage) async {
    // 1. تحميل قائمة كافة السور للتنقل السلس
    List<QuranSurah> allSurahs = [];
    try {
      allSurahs = await QuranService.loadSurahs();
    } catch (_) {}

    // 2. تحديد الصفحة المبدئية عند فتح آية معينة
    int startPage = initialPage;
    final activePages = state.paginatedPages;

    if (initialAyah != null) {
      for (int i = 0; i < activePages.length; i++) {
        if (activePages[i].any((a) => a.verse == initialAyah)) {
          startPage = i;
          break;
        }
      }
    }

    if (startPage >= activePages.length) {
      startPage = 0;
    }

    int? savedBookmarkPage;
    try {
      final prefs = await SharedPreferences.getInstance();
      savedBookmarkPage = isKhatmaSession
          ? prefs.getInt('khatma_last_read_page')
          : prefs.getInt('quran_bookmark_page');
    } catch (_) {}

    emit(
      state.copyWith(
        isPageView: true,
        fontSize: 20.0,
        currentPage: startPage,
        allSurahs: allSurahs,
        savedBookmarkPage: savedBookmarkPage,
      ),
    );

    // 3. إشعار سورة الكهف
    if (state.surah.number == 18) {
      InAppNotificationService.markCompleted('surah_kahf');
    }

    // 4. حفظ الإجراء الحديث (سجل التصفح الأخير)
    await _saveRecentAction(
      surah: state.surah,
      currentPage: startPage,
      initialAyah: initialAyah,
      isKhatmaSession: isKhatmaSession,
    );
  }

  /// حفظ آخر موضع قراءة في السجل
  Future<void> _saveRecentAction({
    required QuranSurah surah,
    required int currentPage,
    required int? initialAyah,
    required bool isKhatmaSession,
  }) async {
    if (isKhatmaSession) return;
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

  /// الانتقال إلى صفحة أخرى
  void changePage(int index) {
    if (index >= 0 && index < state.totalPages) {
      emit(state.copyWith(currentPage: index, hasChangedPage: true));
    }
  }

  /// الانتقال إلى سورة أخرى مباشرة
  Future<void> navigateToSurah(int surahNumber) async {
    try {
      emit(state.copyWith(isLoading: true));
      final surahs = state.allSurahs.isNotEmpty
          ? state.allSurahs
          : await QuranService.loadSurahs();
      final targetSurah = surahs.firstWhere((s) => s.number == surahNumber);
      final ayahs = await QuranService.loadAyahs(surahNumber);

      final paginated = splitIntoPages(ayahs);

      emit(
        state.copyWith(
          surah: targetSurah,
          ayahs: ayahs,
          paginatedPages: paginated,
          currentPage: 0,
          isLoading: false,
          hasChangedPage: false,
        ),
      );

      await _saveRecentAction(
        surah: targetSurah,
        currentPage: 0,
        initialAyah: null,
        isKhatmaSession: isKhatmaSession,
      );
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, errorMessage: 'تعذر فتح السورة: $e'),
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

  /// تحديث موضع الختمة بناءً على الصفحة الحالية (أو آية معينة)
  Future<bool> updateKhatmaBookmark([QuranAyah? specificAyah]) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // نحدد الآية المستهدفة (إما الممررة أو أول آية في الصفحة الحالية)
      final pageAyahs = state.currentPageAyahs;
      final targetAyah =
          specificAyah ??
          (pageAyahs.isNotEmpty
              ? pageAyahs.first
              : (state.ayahs.isNotEmpty ? state.ayahs.first : null));
      if (targetAyah == null) return false;

      final pageNumber = state.currentPageNumber;

      // حفظ موضع السورة والصفحة ورقم الآية للتوافقية الكاملة
      await prefs.setInt('khatma_last_read_surah', targetAyah.chapter);
      await prefs.setInt('khatma_last_read_ayah', targetAyah.verse);
      await prefs.setInt('khatma_last_read_page', pageNumber);

      // احتساب التقدم بالنسبة لإجمالي صفحات أو آيات المصحف
      final absoluteAyah = await QuranService.getAbsoluteAyahOffset(
        targetAyah.chapter,
        targetAyah.verse,
      );
      final prevMaxReached = prefs.getInt('khatma_max_reached_ayah') ?? 0;
      final previousTotalRead = prefs.getInt('khatma_ayahs_read') ?? 0;

      if (absoluteAyah > prevMaxReached) {
        final difference = absoluteAyah - prevMaxReached;
        await prefs.setInt('khatma_max_reached_ayah', absoluteAyah);

        final newTotalRead = (previousTotalRead + difference).clamp(0, 6236);
        await prefs.setInt('khatma_ayahs_read', newTotalRead);

        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month}-${now.day}';
        var readToday = prefs.getInt('khatma_ayahs_read_today') ?? 0;
        final lastReadStr = prefs.getString('khatma_last_read_date');
        if (lastReadStr != null) {
          final lastReadDate = DateTime.parse(lastReadStr);
          final lastReadDayStr =
              '${lastReadDate.year}-${lastReadDate.month}-${lastReadDate.day}';
          if (todayStr != lastReadDayStr) {
            readToday = 0;
          }
        }

        final newReadToday = readToday + difference;
        await prefs.setInt('khatma_ayahs_read_today', newReadToday);
        await prefs.setString('khatma_last_read_date', now.toIso8601String());

        await StatsService.recordAction('quran', amount: difference);

        if (newTotalRead >= 6236) {
          await StatsService.incrementCompletedKhatmas();
        }
      }

      emit(state.copyWith(savedBookmarkPage: pageNumber));
      markBookmarkedInSession();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// وسم تحديث الختمة في الجلسة الحالية
  void markBookmarkedInSession() {
    emit(state.copyWith(hasBookmarkedInThisSession: true));
  }
}
