import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  const KhatmaReaderPage({super.key, required this.initialPage});

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
  bool _canPop = false;

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

  bool get _isCurrentPageBookmarked =>
      _savedKhatmaPage == _currentMushafPageNumber;

  Future<void> _handleSaveKhatmaBookmark() async {
    final targetPage = _currentMushafPageNumber;
    final newlyUnlocked = await KhatmaService.updateReadingProgress(
      newPage: targetPage,
    );

    if (mounted) {
      setState(() {
        _savedKhatmaPage = targetPage;
      });

      final msg = newlyUnlocked != null
          ? 'تم حفظ موضع الختمة عند صفحة $targetPage • مبارك نيل ${newlyUnlocked.title}'
          : 'تم حفظ موضع الختمة عند صفحة $targetPage بنجاح';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showAyahActions(
    QuranAyah ayah,
    QuranSurah fallbackSurah,
  ) async {
    _pressedAyahNotifier.value = ayah;
    final interpretation = await QuranService.loadInterpretation(
      surahNumber: ayah.chapter,
      ayahNumber: ayah.verse,
    );

    if (!mounted) {
      _pressedAyahNotifier.value = null;
      return;
    }

    final surah = _allSurahs.firstWhere(
      (s) => s.number == ayah.chapter,
      orElse: () => fallbackSurah,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          elevation: 0,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              constraints: BoxConstraints(maxWidth: 420.w),
              padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2621) : Colors.white,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.primary,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سورة ${surah.nameArabic} - الآية ${ayah.verse}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                            Text(
                              'الصفحة ${ayah.page} • الجزء ${ayah.juz}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10.5.sp,
                                color: isDark
                                    ? Colors.white54
                                    : AppColors.lightSecondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF9F7F1),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Text(
                      '﴿ ${ayah.text} ﴾',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16.sp,
                        height: 1.8,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFE2B755)
                            : const Color(0xFF9E7728),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (interpretation.isNotEmpty) ...[
                    Flexible(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF141A16)
                                : const Color(0xFFF4F6F4),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            interpretation,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 14.sp,
                              height: 1.8,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await Clipboard.setData(
                              ClipboardData(
                                text:
                                    'سورة ${surah.nameArabic} - الآية ${ayah.verse}\n\n${ayah.text}',
                              ),
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ الآية للحافظة'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text(
                            'نسخ الآية',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    _pressedAyahNotifier.value = null;
  }

  Future<void> _handleCloseOrPromptExit() async {
    if (_canPop) return;

    // إذا كانت الصفحة الحالية مطابقة لآخر صفحة محفوظة، نخرج مباشرة
    if (_currentMushafPageNumber == _savedKhatmaPage) {
      if (mounted) {
        setState(() => _canPop = true);
        Navigator.of(context).pop();
      }
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentP = _currentMushafPageNumber;
    final savedP = _savedKhatmaPage ?? widget.initialPage;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          elevation: 0,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              constraints: BoxConstraints(maxWidth: 420.w),
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2621) : Colors.white,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.bookmark_added_rounded,
                          color: AppColors.primary,
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'تأكيد حفظ موضع الختمة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx, 'cancel'),
                        icon: const Icon(Icons.close_rounded),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF9F7F1),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Text(
                      'لقد انتقلت إلى الصفحة ($currentP) دون حفظها.\nهل تود حفظ الموضع الحالي أم الإبقاء على موضعك السابق (صفحة $savedP)؟',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.5.sp,
                        height: 1.6,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // خيار 1: حفظ الموضع الحالي والخروج
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, 'save_current'),
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(
                      'حفظ الموضع الحالي (صفحة $currentP)',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  // خيار 2: الإبقاء على الموضع السابق والخروج
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx, 'keep_previous'),
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: Text(
                      'الإبقاء على السابق (صفحة $savedP)',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : Colors.black87,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.2),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  // إلغاء ومتابعة القراءة
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, 'cancel'),
                    child: Text(
                      'متابعة القراءة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.5.sp,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || result == null || result == 'cancel') {
      return;
    }

    if (result == 'save_current') {
      await KhatmaService.updateReadingProgress(newPage: currentP);
      if (mounted) {
        setState(() => _canPop = true);
        Navigator.of(context).pop();
      }
    } else if (result == 'keep_previous') {
      if (mounted) {
        setState(() => _canPop = true);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: _canPop,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _handleCloseOrPromptExit();
          }
        },
        child: Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : const Color(0xFFFBF9F4),
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
                          final surahNumber = pageAyahs.isNotEmpty
                              ? pageAyahs.first.chapter
                              : 1;
                          final pageSurah = _allSurahs.firstWhere(
                            (s) => s.number == surahNumber,
                            orElse: () => _currentSurah,
                          );
                          final isFirstPageOfSurah =
                              pageAyahs.isNotEmpty &&
                              pageAyahs.any((a) => a.verse == 1);

                          return MushafPage(
                            key: ValueKey('khatma_page_$realMushafPage'),
                            surah: pageSurah,
                            ayahs: pageAyahs,
                            isFirstPage: isFirstPageOfSurah,
                            isLastPage: false,
                            pageNumber: realMushafPage,
                            onAyahLongPress: (ayah) =>
                                _showAyahActions(ayah, pageSurah),
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
                                  onTap: _handleCloseOrPromptExit,
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
      ),
    );
  }
}
