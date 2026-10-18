import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/services/in_app_notification_service.dart';
import 'package:tarteel/features/quran/controllers/quran_reading_controller.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'quran_reader_state.dart';

class QuranReaderCubit extends Cubit<QuranReaderState> {
  final bool isKhatmaSession;
  final int? initialAyah;

  QuranReaderCubit({
    required QuranSurah initialSurah,
    required List<QuranAyah> initialAyahs,
    int initialPage = 0,
    this.initialAyah,
    this.isKhatmaSession = false,
  }) : super(QuranReaderState(
          surah: initialSurah,
          ayahs: initialAyahs,
          paginatedPages: QuranReadingController.splitIntoPages(initialAyahs),
          continuousPages: [initialAyahs],
          currentPage: initialPage,
        )) {
    _initialize(initialPage);
  }

  Future<void> _initialize(int initialPage) async {
    // 3. تحميل قائمة كافة السور للتنقل السلس
    List<QuranSurah> allSurahs = [];
    try {
      allSurahs = await QuranService.loadSurahs();
    } catch (_) {}

    // 4. تحديد الصفحة المبدئية عند فتح آية معينة
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

    emit(state.copyWith(
      isPageView: true,
      fontSize: 20.0,
      currentPage: startPage,
      allSurahs: allSurahs,
    ));

    // 5. إشعار سورة الكهف
    if (state.surah.number == 18) {
      InAppNotificationService.markCompleted('surah_kahf');
    }

    // 6. حفظ الإجراء الحديث
    await QuranReadingController.saveRecentAction(
      surah: state.surah,
      currentPage: startPage,
      initialAyah: initialAyah,
      isKhatmaSession: isKhatmaSession,
    );
  }

  /// تغيير نمط القراءة (صفحات مصحف vs قائمة متصلة)
  Future<void> setReadingMode(bool isPage, {QuranAyah? currentVisibleAyah}) async {
    if (state.isPageView == isPage) return;

    await QuranReadingController.setReadingMode(isPage ? 'page' : 'list');

    int newPage = 0;
    if (currentVisibleAyah != null && isPage) {
      for (int i = 0; i < state.paginatedPages.length; i++) {
        if (state.paginatedPages[i].any((a) => a.verse == currentVisibleAyah.verse)) {
          newPage = i;
          break;
        }
      }
    }

    emit(state.copyWith(
      isPageView: isPage,
      currentPage: newPage,
    ));
  }

  /// تغيير حجم الخط وحفظه تلقائياً
  Future<void> setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quran_font_size', size);
    emit(state.copyWith(fontSize: size));
  }

  /// الانتقال إلى صفحة أخرى
  void changePage(int index) {
    if (index >= 0 && index < state.totalPages) {
      emit(state.copyWith(
        currentPage: index,
        hasChangedPage: true,
      ));
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

      final paginated = QuranReadingController.splitIntoPages(ayahs);
      final continuous = [ayahs];

      emit(state.copyWith(
        surah: targetSurah,
        ayahs: ayahs,
        paginatedPages: paginated,
        continuousPages: continuous,
        currentPage: 0,
        isLoading: false,
        hasChangedPage: false,
      ));

      await QuranReadingController.saveRecentAction(
        surah: targetSurah,
        currentPage: 0,
        initialAyah: null,
        isKhatmaSession: isKhatmaSession,
      );
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر فتح السورة: $e',
      ));
    }
  }

  /// وسم تحديث الختمة في الجلسة الحالية
  void markBookmarkedInSession() {
    emit(state.copyWith(hasBookmarkedInThisSession: true));
  }
}
