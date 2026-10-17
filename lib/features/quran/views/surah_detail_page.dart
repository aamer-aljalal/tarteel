import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/features/quran/controllers/quran_reading_controller.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/core/widgets/bottom_sheets/app_modal_bottom_sheet.dart';
import 'package:tarteel/core/widgets/buttons/app_button.dart';
import 'package:tarteel/features/quran/widgets/ayah_top_bar.dart';
import 'package:tarteel/features/quran/widgets/mushaf_page.dart';
import 'package:tarteel/features/quran/widgets/reading_modes/quran_continuous_scroll_view.dart';
import 'package:tarteel/features/quran/widgets/reading_modes/quran_page_view.dart';
import 'package:tarteel/core/services/in_app_notification_service.dart';

class SurahDetailPage extends StatefulWidget {
  const SurahDetailPage({
    super.key,
    required this.surah,
    required this.ayahs,
    this.initialPage = 0,
    this.initialAyah,
    this.isKhatmaSession = false,
  });

  final QuranSurah surah;
  final List<QuranAyah> ayahs;
  final int initialPage;
  final int? initialAyah;
  final bool isKhatmaSession;

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  late final List<List<QuranAyah>> _continuousPages;
  List<List<QuranAyah>> _paginatedPages = [];
  late List<List<QuranAyah>> _pages;
  late List<GlobalKey> _pageKeys;
  late final GlobalKey _centerSliverKey;
  int _currentPage = 0;
  int _centerPage = 0;
  final bool _isLoading = false;
  List<QuranSurah> _allSurahs = [];
  final ValueNotifier<QuranAyah?> _pressedAyahNotifier = ValueNotifier(null);

  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  bool _isPageView = false;
  double _initialScrollOffset = 0.0;
  bool _hasBookmarkedInThisSession = false;
  bool _hasChangedPage = false;
  final GlobalKey _initialAyahKey = GlobalKey();
  late final Map<int, GlobalKey> _ayahKeys;

  double? _lastScreenWidth;
  double? _lastScreenHeight;
  double _fontSize = 20.0;

  @override
  void initState() {
    super.initState();
    _continuousPages = [widget.ayahs];
    _paginatedPages = [];
    _pages = _continuousPages;
    _pageKeys = List.generate(_pages.length, (_) => GlobalKey());
    _centerSliverKey = GlobalKey();

    _ayahKeys = {for (var a in widget.ayahs) a.verse: GlobalKey()};
    if (widget.initialAyah != null &&
        _ayahKeys.containsKey(widget.initialAyah)) {
      _ayahKeys[widget.initialAyah!] = _initialAyahKey;
    }

    int startPage = widget.initialPage;
    if (widget.initialAyah != null) {
      for (int i = 0; i < _pages.length; i++) {
        if (_pages[i].any((a) => a.verse == widget.initialAyah)) {
          startPage = i;
          break;
        }
      }
    }

    _centerPage = startPage;
    if (_centerPage >= _pages.length) _centerPage = 0;
    _currentPage = _centerPage;

    _loadAllSurahs();
    _loadReadingModePreference();
    _loadFontSizePreference();

    if (widget.surah.number == 18) {
      InAppNotificationService.markCompleted('surah_kahf');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialScrollOffset = _scrollController.hasClients
          ? _scrollController.position.pixels
          : 0.0;
      _saveRecentQuranAction();

      // Scroll to target initial Ayah if present
      if (widget.initialAyah != null &&
          _initialAyahKey.currentContext != null) {
        Scrollable.ensureVisible(
          _initialAyahKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1, // Near top
        );
      }
    });
  }

  Future<void> _loadFontSizePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final double savedSize = prefs.getDouble('quran_font_size') ?? 20.0;
    if (mounted) {
      setState(() {
        _fontSize = savedSize;
      });
      if (_lastScreenWidth != null && _lastScreenHeight != null) {
        _calculateDynamicPages(_lastScreenWidth!, _lastScreenHeight!);
      }
    }
  }

  Future<void> _setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quran_font_size', size);
    if (mounted) {
      setState(() {
        _fontSize = size;
      });
      if (_lastScreenWidth != null && _lastScreenHeight != null) {
        _calculateDynamicPages(_lastScreenWidth!, _lastScreenHeight!);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    if (screenWidth != _lastScreenWidth || screenHeight != _lastScreenHeight) {
      _lastScreenWidth = screenWidth;
      _lastScreenHeight = screenHeight;
      _calculateDynamicPages(screenWidth, screenHeight);
    }
  }

  void _calculateDynamicPages(double screenWidth, double screenHeight) {
    final mediaQuery = MediaQuery.of(context);
    final textScale = mediaQuery.textScaler.scale(1.0);

    final scaleX = screenWidth / 375.0;

    final fontSize = _fontSize * scaleX * textScale;
    final lineHeight = fontSize * 2.0;

    final scaleY = screenHeight / 812.0;
    final topBarOffset = 80.0 * scaleX;
    final bottomOffset = 100.0 * scaleY;

    final availableHeight =
        screenHeight -
        topBarOffset -
        bottomOffset -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;

    final maxLines = (availableHeight / lineHeight).floor().clamp(8, 20);

    final availableWidth = screenWidth - (56.0 * scaleX);
    final averageWordWidth = fontSize * 1.35;
    final wordsPerLine = (availableWidth / averageWordWidth).clamp(6.0, 12.0);

    _paginatedPages = _splitIntoPagesDynamic(
      widget.ayahs,
      maxLines: maxLines,
      wordsPerLine: wordsPerLine,
    );

    setState(() {
      _pages = _isPageView ? _paginatedPages : _continuousPages;
      _pageKeys = List.generate(_pages.length, (_) => GlobalKey());

      if (_currentPage >= _pages.length) {
        _currentPage = _pages.length - 1;
        if (_currentPage < 0) _currentPage = 0;
      }
    });
  }

  List<List<QuranAyah>> _splitIntoPagesDynamic(
    List<QuranAyah> ayahs, {
    required int maxLines,
    required double wordsPerLine,
  }) {
    if (ayahs.isEmpty) return [[]];

    final pages = <List<QuranAyah>>[];
    var currentPage = <QuranAyah>[];
    double currentLinesUsed = 0.0;

    for (final ayah in ayahs) {
      final wordsCount = ayah.text.trim().split(RegExp(r'\s+')).length;

      final ayahLines = (wordsCount / wordsPerLine) + 0.3;

      final isFirstPage = pages.isEmpty;
      final limitLines = isFirstPage ? (maxLines - 1.8) : maxLines;

      if (currentPage.isNotEmpty &&
          (currentLinesUsed + ayahLines > limitLines)) {
        pages.add(currentPage);
        currentPage = <QuranAyah>[ayah];
        currentLinesUsed = ayahLines;
      } else {
        currentPage.add(ayah);
        currentLinesUsed += ayahLines;
      }
    }

    if (currentPage.isNotEmpty) {
      pages.add(currentPage);
    }

    return pages;
  }

  Future<void> _loadReadingModePreference() async {
    final mode = await QuranReadingController.getReadingMode();
    if (mounted) {
      setState(() {
        _isPageView = mode == 'page';
        _pages = _isPageView ? _paginatedPages : _continuousPages;
        _pageKeys = List.generate(_pages.length, (_) => GlobalKey());

        int startPage = widget.initialPage;
        if (widget.initialAyah != null) {
          for (int i = 0; i < _pages.length; i++) {
            if (_pages[i].any((a) => a.verse == widget.initialAyah)) {
              startPage = i;
              break;
            }
          }
        }
        _currentPage = startPage;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isPageView && _pageController.hasClients) {
          _pageController.jumpToPage(_currentPage);
        } else if (!_isPageView && widget.initialAyah != null) {
          final targetKey = _ayahKeys[widget.initialAyah];
          if (targetKey != null && targetKey.currentContext != null) {
            Scrollable.ensureVisible(
              targetKey.currentContext!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.1,
            );
          }
        }
      });
    }
  }

  QuranAyah? _getCurrentVisibleAyah() {
    if (_isPageView) {
      if (_currentPage < _pages.length && _pages[_currentPage].isNotEmpty) {
        return _pages[_currentPage].first;
      }
    } else {
      double minDiff = double.infinity;
      QuranAyah? topmostAyah;
      for (final ayah in widget.ayahs) {
        final key = _ayahKeys[ayah.verse];
        if (key == null) continue;
        final context = key.currentContext;
        if (context == null) continue;
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) continue;
        final position = box.localToGlobal(Offset.zero);
        final y = position.dy;
        if (y >= 80.h && y < minDiff) {
          minDiff = y;
          topmostAyah = ayah;
        }
      }
      return topmostAyah ?? widget.ayahs.first;
    }
    return null;
  }

  void _setReadingMode(bool isPage) {
    if (_isPageView == isPage) return;

    final currentAyah = _getCurrentVisibleAyah();

    setState(() {
      _isPageView = isPage;
      _pages = _isPageView ? _paginatedPages : _continuousPages;
      _pageKeys = List.generate(_pages.length, (_) => GlobalKey());
    });
    QuranReadingController.setReadingMode(_isPageView ? 'page' : 'list');

    if (currentAyah != null) {
      if (_isPageView) {
        int targetPage = 0;
        for (int i = 0; i < _paginatedPages.length; i++) {
          if (_paginatedPages[i].any((a) => a.verse == currentAyah.verse)) {
            targetPage = i;
            break;
          }
        }
        _currentPage = targetPage;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(targetPage);
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final targetKey = _ayahKeys[currentAyah.verse];
          if (targetKey != null && targetKey.currentContext != null) {
            Scrollable.ensureVisible(
              targetKey.currentContext!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.1,
            );
          }
        });
      }
    }
  }

  Future<void> _loadAllSurahs() async {
    try {
      final surahs = await QuranService.loadSurahs();
      if (mounted) {
        setState(() {
          _allSurahs = surahs;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveRecentQuranAction() async {
    await QuranReadingController.saveRecentAction(
      surah: widget.surah,
      currentPage: _currentPage,
      initialAyah: widget.initialAyah,
      isKhatmaSession: widget.isKhatmaSession,
    );
  }

  void _saveCurrentVisibleAyah() {
    QuranReadingController.saveTopVisibleAyah(
      surah: widget.surah,
      ayahs: widget.ayahs,
      ayahKeys: _ayahKeys,
      isKhatmaSession: widget.isKhatmaSession,
    );
  }

  Future<void> _showAyahActions(QuranAyah ayah) async {
    _pressedAyahNotifier.value = ayah;
    final interpretation = await QuranService.loadInterpretation(
      surahNumber: ayah.chapter,
      ayahNumber: ayah.verse,
    );

    if (!mounted) {
      _pressedAyahNotifier.value = null;
      return;
    }

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
                  // 1. رأس النافذة المنبثقة
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
                              'سورة ${widget.surah.nameArabic}',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'الآية رقم ${ayah.verse} • ${widget.surah.revelationPlace == 'makkah' ? 'مكية' : 'مدنية'}',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Cairo',
                                color: AppColors.goldAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20.sp,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  Divider(
                    height: 1,
                    thickness: 0.8,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade200,
                  ),
                  SizedBox(height: 14.h),

                  // 2. بطاقة عرض نص الآية الكريمة
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    constraints: BoxConstraints(maxHeight: 160.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black26
                          : const Color(0xFFF9F6EE),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Center(
                        child: Text(
                          ayah.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17.sp,
                            height: 1.9,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Amiri',
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E2822),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // 3. زر التفسير الميسر الرئيسي الفاخر
                  AppButton(
                    text: 'عرض التفسير الميسر',
                    leadingIcon: Icons.auto_stories_rounded,
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.medium,
                    isFullWidth: true,
                    borderRadius: 14.r,
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showInterpretation(ayah, interpretation);
                    },
                  ),
                  SizedBox(height: 10.h),

                  // 4. صف الإجراءات (نسخ الآية وحفظها بالمفضلة)
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'نسخ الآية',
                          leadingIcon: Icons.copy_rounded,
                          variant: AppButtonVariant.outline,
                          size: AppButtonSize.medium,
                          borderRadius: 12.r,
                          onPressed: () {
                            Navigator.pop(ctx);
                            QuranReadingController.copyAyah(
                              context: context,
                              surah: widget.surah,
                              ayah: ayah,
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: AppButton(
                          text: 'حفظ بالمفضلة',
                          leadingIcon: Icons.favorite_border_rounded,
                          variant: AppButtonVariant.outline,
                          size: AppButtonSize.medium,
                          borderRadius: 12.r,
                          onPressed: () {
                            Navigator.pop(ctx);
                            QuranReadingController.saveAyahToFavorites(
                              context: context,
                              surah: widget.surah,
                              ayah: ayah,
                              interpretation: interpretation,
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // 5. زر تحديث الختمة (إذا كانت الجلسة جلسة ختمة)
                  if (widget.isKhatmaSession) ...[
                    SizedBox(height: 10.h),
                    AppButton(
                      text: 'تحديث موضع الختمة',
                      leadingIcon: Icons.bookmark_added_rounded,
                      variant: AppButtonVariant.gold,
                      size: AppButtonSize.medium,
                      isFullWidth: true,
                      borderRadius: 14.r,
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final success =
                            await QuranReadingController.updateKhatmaBookmark(
                          context: context,
                          ayah: ayah,
                        );
                        if (success && mounted) {
                          setState(() {
                            _hasBookmarkedInThisSession = true;
                            if (_scrollController.hasClients) {
                              _initialScrollOffset =
                                  _scrollController.position.pixels;
                            }
                          });
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    _pressedAyahNotifier.value = null;
  }

  void _showInterpretation(QuranAyah ayah, String interpretation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppModalBottomSheet.show(
      context: context,
      title: 'تفسير الآية (${ayah.verse}) من سورة ${widget.surah.nameArabic}',
      subtitle: 'التفسير الميسر',
      heightFraction: 0.75,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Text(
                ayah.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  height: 1.8,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Amiri',
                  color: isDark ? Colors.white : const Color(0xFF1A1710),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 24.h),
                child: Text(
                  interpretation.isEmpty ? 'التفسير غير متوفر' : interpretation,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.8,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pressedAyahNotifier.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildPageSliver(int index) {
    return MushafPage(
      key: _pageKeys[index],
      surah: widget.surah,
      ayahs: _pages[index],
      isFirstPage: index == 0,
      isLastPage: index == _pages.length - 1,
      pageNumber: index + 1,
      onAyahLongPress: _showAyahActions,
      nextSurah: _nextSurah,
      prevSurah: _prevSurah,
      onNavigate: _navigateToSurah,
      pressedAyahNotifier: _pressedAyahNotifier,
      initialAyah: widget.initialAyah,
      initialAyahKey: _initialAyahKey,
      ayahKeys: _ayahKeys,
      fontSize: _fontSize,
    );
  }

  QuranSurah? get _nextSurah {
    if (_allSurahs.isEmpty) return null;
    final nextNumber = widget.surah.number + 1;
    if (nextNumber > 114) return null;
    return _allSurahs.firstWhere((s) => s.number == nextNumber);
  }

  QuranSurah? get _prevSurah {
    if (_allSurahs.isEmpty) return null;
    final prevNumber = widget.surah.number - 1;
    if (prevNumber < 1) return null;
    return _allSurahs.firstWhere((s) => s.number == prevNumber);
  }

  Future<void> _navigateToSurah(int surahNumber) async {
    try {
      final surahs = await QuranService.loadSurahs();
      final targetSurah = surahs.firstWhere((s) => s.number == surahNumber);
      final ayahs = await QuranService.loadAyahs(surahNumber);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SurahDetailPage(
            surah: targetSurah,
            ayahs: ayahs,
            isKhatmaSession: widget.isKhatmaSession,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<bool> _onWillPop() async {
    if (!widget.isKhatmaSession || _hasBookmarkedInThisSession) return true;

    if (_isPageView) {
      if (_hasChangedPage) {
        return await QuranReadingController.showKhatmaExitWarning(context);
      }
    } else {
      if (_scrollController.hasClients) {
        final currentOffset = _scrollController.position.pixels;
        if ((currentOffset - _initialScrollOffset).abs() > 500) {
          return await QuranReadingController.showKhatmaExitWarning(context);
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(this.context).pop();
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          body: SafeArea(
            child: Column(
              children: [
                MushafTopBar(
                  surah: widget.surah,
                  isPageView: _isPageView,
                  onReadingModeChanged: _setReadingMode,
                  allSurahs: _allSurahs,
                  onNavigateToSurah: _navigateToSurah,
                  fontSize: _fontSize,
                  onFontSizeChanged: _setFontSize,
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(top: 75.h, bottom: 50.h),
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/img/surah_detail_green.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 22),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _isPageView
                          ? QuranPageView(
                              pageController: _pageController,
                              totalPages: _pages.length,
                              buildPageSliver: _buildPageSliver,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                  _hasChangedPage = true;
                                });
                              },
                            )
                          : QuranContinuousScrollView(
                              scrollController: _scrollController,
                              centerSliverKey: _centerSliverKey,
                              centerPage: _centerPage,
                              totalPages: _pages.length,
                              buildPageSliver: _buildPageSliver,
                              onScrollEnd: _saveCurrentVisibleAyah,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
