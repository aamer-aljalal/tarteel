import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/buttons/app_glass_button.dart';
import 'package:tarteel/features/khatma/services/khatma_service.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/widgets/ayah_top_bar.dart';
import 'package:tarteel/features/quran/widgets/mushaf_page.dart';

/// صفحة قراءة المصحف الخاصة بمسار الختمة حصراً
/// مستقلة تماماً عن قارئ القرآن العام وتحتفظ بصفحتها وسجلها تلقائياً
class KhatmaReaderPage extends StatefulWidget {
  final int initialPage;

  const KhatmaReaderPage({
    super.key,
    required this.initialPage,
  });

  @override
  State<KhatmaReaderPage> createState() => _KhatmaReaderPageState();
}

class _KhatmaReaderPageState extends State<KhatmaReaderPage> {
  late final PageController _pageController;
  final ValueNotifier<QuranAyah?> _pressedAyahNotifier = ValueNotifier(null);

  bool _isLoading = true;
  List<QuranSurah> _allSurahs = [];
  List<List<QuranAyah>> _allPages = [];
  late int _currentPageIndex;
  int? _savedKhatmaPage;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = (widget.initialPage - 1).clamp(0, 603);
    _savedKhatmaPage = widget.initialPage;
    _pageController = PageController(initialPage: _currentPageIndex);
    _loadPagesData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pressedAyahNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadPagesData() async {
    try {
      final surahs = await QuranService.loadSurahs();
      final pages = await QuranService.loadAllPages();

      if (mounted) {
        setState(() {
          _allSurahs = surahs;
          _allPages = pages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _currentMushafPageNumber => _currentPageIndex + 1;

  QuranSurah get _currentSurah {
    if (_allPages.isNotEmpty && _currentPageIndex < _allPages.length) {
      final pageAyahs = _allPages[_currentPageIndex];
      if (pageAyahs.isNotEmpty) {
        final surahNumber = pageAyahs.first.chapter;
        return _allSurahs.firstWhere(
          (s) => s.number == surahNumber,
          orElse: () => _allSurahs.isNotEmpty
              ? _allSurahs.first
              : const QuranSurah(
                  number: 1,
                  nameArabic: 'الفاتحة',
                  nameEnglish: 'Al-Fatihah',
                  transliteration: 'Al-Faatiha',
                  versesCount: 7,
                  revelationPlace: 'مكية',
                ),
        );
      }
    }
    return _allSurahs.isNotEmpty
        ? _allSurahs.first
        : const QuranSurah(
            number: 1,
            nameArabic: 'الفاتحة',
            nameEnglish: 'Al-Fatihah',
            transliteration: 'Al-Faatiha',
            versesCount: 7,
            revelationPlace: 'مكية',
          );
  }

  int get _currentJuz {
    if (_allPages.isNotEmpty && _currentPageIndex < _allPages.length) {
      final pageAyahs = _allPages[_currentPageIndex];
      if (pageAyahs.isNotEmpty) return pageAyahs.first.juz;
    }
    return 1;
  }

  int get _currentHizb {
    if (_allPages.isNotEmpty && _currentPageIndex < _allPages.length) {
      final pageAyahs = _allPages[_currentPageIndex];
      if (pageAyahs.isNotEmpty) return pageAyahs.first.hizb;
    }
    return 1;
  }

  bool get _isCurrentPageBookmarked => _savedKhatmaPage == _currentMushafPageNumber;

  Future<void> _handleSaveKhatmaBookmark() async {
    final targetPage = _currentMushafPageNumber;
    final newlyUnlocked = await KhatmaService.updateReadingProgress(newPage: targetPage);

    if (mounted) {
      setState(() {
        _savedKhatmaPage = targetPage;
      });

      final msg = newlyUnlocked != null
          ? 'تم حفظ موضع الختمة عند صفحة $targetPage • مبارك نيل ${newlyUnlocked.title}'
          : 'تم حفظ موضع الختمة عند صفحة $targetPage بنجاح';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFFBF9F4),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 1. الترويسة العلوية الفخمة لمصحف المدينة
                  MushafTopBar(
                    surah: _currentSurah,
                    currentJuz: _currentJuz,
                    currentHizb: _currentHizb,
                  ),

                  // 2. محتوى صفحة المصحف بنمط صفحات المصحف
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _allPages.length,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      onPageChanged: (index) {
                        setState(() {
                          _currentPageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final pageAyahs = _allPages[index];
                        final realMushafPage = index + 1;
                        final surahNumber =
                            pageAyahs.isNotEmpty ? pageAyahs.first.chapter : 1;
                        final pageSurah = _allSurahs.firstWhere(
                          (s) => s.number == surahNumber,
                          orElse: () => _currentSurah,
                        );
                        final isFirstPageOfSurah =
                            pageAyahs.isNotEmpty && pageAyahs.any((a) => a.verse == 1);

                        return MushafPage(
                          key: ValueKey('khatma_page_$realMushafPage'),
                          surah: pageSurah,
                          ayahs: pageAyahs,
                          isFirstPage: isFirstPageOfSurah,
                          isLastPage: false,
                          pageNumber: realMushafPage,
                          onAyahLongPress: (_) {},
                          pressedAyahNotifier: _pressedAyahNotifier,
                          ayahKeys: const {},
                          fontSize: 20.0,
                        );
                      },
                    ),
                  ),

                  // 3. شريط التحكم السفلي المستقل لمسار الختمة
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/img/quran/background.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        height: 50.h,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // في المنتصف: مؤشر صفحة الختمة
                            Text(
                              'ختمة المصحف • صفحة $_currentMushafPageNumber من 604',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // على اليمين: زر حفظ موضع الختمة
                            Positioned(
                              right: 12.w,
                              child: AppGlassButton(
                                onTap: _handleSaveKhatmaBookmark,
                                tooltip: 'حفظ موضع الختمة لهذه الصفحة',
                                isCircle: true,
                                width: 34.w,
                                height: 34.h,
                                borderColor: _isCurrentPageBookmarked
                                    ? Colors.redAccent.withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.6),
                                backgroundColor: _isCurrentPageBookmarked
                                    ? Colors.redAccent.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.1),
                                child: Icon(
                                  _isCurrentPageBookmarked
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_outline_rounded,
                                  color: _isCurrentPageBookmarked
                                      ? Colors.redAccent
                                      : Colors.white,
                                  size: 19.sp,
                                ),
                              ),
                            ),

                            // على اليسار: زر إغلاق والرجوع لبطاقة الختمة
                            Positioned(
                              left: 12.w,
                              child: AppGlassButton(
                                onTap: () => Navigator.pop(context),
                                tooltip: 'الرجوع إلى بطاقة الختمة',
                                isCircle: true,
                                width: 34.w,
                                height: 34.h,
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 19.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
