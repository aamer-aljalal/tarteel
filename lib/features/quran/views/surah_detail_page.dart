import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/bottom_sheets/app_modal_bottom_sheet.dart';
import 'package:tarteel/core/widgets/buttons/app_button.dart';
import 'package:tarteel/features/quran/controllers/quran_reading_controller.dart';
import 'package:tarteel/features/quran/cubit/quran_reader_cubit.dart';
import 'package:tarteel/features/quran/cubit/quran_reader_state.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/widgets/ayah_top_bar.dart';
import 'package:tarteel/features/quran/widgets/mushaf_page.dart';
import 'package:tarteel/features/quran/widgets/reading_modes/quran_page_view.dart';

class SurahDetailPage extends StatelessWidget {
  final QuranSurah surah;
  final List<QuranAyah> ayahs;
  final int initialPage;
  final int? initialAyah;
  final bool isKhatmaSession;

  const SurahDetailPage({
    super.key,
    required this.surah,
    required this.ayahs,
    this.initialPage = 0,
    this.initialAyah,
    this.isKhatmaSession = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuranReaderCubit(
        initialSurah: surah,
        initialAyahs: ayahs,
        initialPage: initialPage,
        initialAyah: initialAyah,
        isKhatmaSession: isKhatmaSession,
      ),
      child: _SurahDetailView(
        isKhatmaSession: isKhatmaSession,
        initialAyah: initialAyah,
      ),
    );
  }
}

class _SurahDetailView extends StatefulWidget {
  final bool isKhatmaSession;
  final int? initialAyah;

  const _SurahDetailView({required this.isKhatmaSession, this.initialAyah});

  @override
  State<_SurahDetailView> createState() => _SurahDetailViewState();
}

class _SurahDetailViewState extends State<_SurahDetailView> {
  final PageController _pageController = PageController();
  final ValueNotifier<QuranAyah?> _pressedAyahNotifier = ValueNotifier(null);
  final GlobalKey _initialAyahKey = GlobalKey();

  late Map<int, GlobalKey> _ayahKeys;
  late List<GlobalKey> _pageKeys;
  bool _hasScrolledToInitialAyah = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<QuranReaderCubit>();
    _initKeys(cubit.state);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialAyahIfNeeded();
    });
  }

  void _initKeys(QuranReaderState state) {
    _pageKeys = List.generate(state.pages.length, (_) => GlobalKey());
    _ayahKeys = {for (var a in state.ayahs) a.verse: GlobalKey()};
    if (widget.initialAyah != null &&
        _ayahKeys.containsKey(widget.initialAyah)) {
      _ayahKeys[widget.initialAyah!] = _initialAyahKey;
    }
  }

  void _scrollToInitialAyahIfNeeded() {
    if (_hasScrolledToInitialAyah) return;
    if (widget.initialAyah != null && _initialAyahKey.currentContext != null) {
      _hasScrolledToInitialAyah = true;
      Scrollable.ensureVisible(
        _initialAyahKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  @override
  void dispose() {
    _pressedAyahNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop(QuranReaderState state) async {
    if (state.hasBookmarkedInThisSession) return true;

    if (state.hasChangedPage) {
      return await QuranReadingController.showKhatmaExitWarning(context);
    }
    return true;
  }

  Widget _buildPageSliver(
    BuildContext context,
    QuranReaderState state,
    int index,
  ) {
    final pageAyahs = state.pages[index];
    final realMushafPage = pageAyahs.isNotEmpty
        ? pageAyahs.first.page
        : (index + 1);

    if (index >= _pageKeys.length) {
      _pageKeys = List.generate(state.pages.length, (_) => GlobalKey());
    }

    return MushafPage(
      key: _pageKeys[index],
      surah: state.surah,
      ayahs: pageAyahs,
      isFirstPage: index == 0,
      isLastPage: index == state.pages.length - 1,
      pageNumber: realMushafPage,
      onAyahLongPress: (ayah) => _showAyahActions(ayah, state.surah),
      nextSurah: state.nextSurah,
      prevSurah: state.prevSurah,
      onNavigate: (surahNum) =>
          context.read<QuranReaderCubit>().navigateToSurah(surahNum),
      pressedAyahNotifier: _pressedAyahNotifier,
      initialAyah: widget.initialAyah,
      initialAyahKey: _initialAyahKey,
      ayahKeys: _ayahKeys,
      fontSize: state.fontSize,
    );
  }

  Future<void> _showAyahActions(QuranAyah ayah, QuranSurah surah) async {
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
                              'سورة ${surah.nameArabic}',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'الآية رقم ${ayah.verse} • ${surah.isMakki ? 'مكية' : 'مدنية'}',
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
                          color: isDark ? Colors.white54 : Colors.black45,
                          size: 20.sp,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        tooltip: 'إغلاق',
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // 2. بطاقة عرض نص الآية
                  Container(
                    constraints: BoxConstraints(maxHeight: 160.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFFBF9F4),
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
                      _showInterpretation(ayah, surah, interpretation);
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
                              surah: surah,
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
                              surah: surah,
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
                          context
                              .read<QuranReaderCubit>()
                              .markBookmarkedInSession();
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

  void _showInterpretation(
    QuranAyah ayah,
    QuranSurah surah,
    String interpretation,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppModalBottomSheet.show(
      context: context,
      title: 'تفسير الآية (${ayah.verse}) من سورة ${surah.nameArabic}',
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

  void _showSurahSelector(BuildContext context, QuranReaderState state) {
    AppModalBottomSheet.show(
      context: context,
      title: 'سور القرآن الكريم',
      heightFraction: 0.85,
      wrapWithScrollView: false,
      contentPadding: EdgeInsets.zero,
      child: SurahSelectorSheet(
        allSurahs: state.allSurahs,
        currentSurah: state.surah,
        onNavigate: (surahNum) =>
            context.read<QuranReaderCubit>().navigateToSurah(surahNum),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuranReaderCubit, QuranReaderState>(
      listener: (context, state) {
        _initKeys(state);

        if (state.isPageView && _pageController.hasClients) {
          if (_pageController.page?.round() != state.currentPage) {
            _pageController.jumpToPage(state.currentPage);
          }
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await _onWillPop(state);
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBackground
                  : const Color(0xFFFBF9F4),
              body: Column(
                children: [
                  // 1. الترويسة العلوية الفخمة تمتد لأعلى الشاشة بدون أي فراغ
                  MushafTopBar(
                    surah: state.surah,
                    currentJuz: state.currentJuz,
                    currentHizb: state.currentHizb,
                  ),
                  // 2. محتوى صفحة المصحف (قراءة مريحة بنمط صفحات المصحف)
                  Expanded(
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : QuranPageView(
                            pageController: _pageController,
                            totalPages: state.pages.length,
                            initialPage: state.currentPage,
                            showPageIndicator: false,
                            buildPageSliver: (index) =>
                                _buildPageSliver(context, state, index),
                            onPageChanged: (index) {
                              context.read<QuranReaderCubit>().changePage(
                                index,
                              );
                            },
                          ),
                  ),

                  // 3. الشريط السفلي مع خلفية background.png
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
                      child: Container(
                        height: 50.h,
                        // padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 2. زري فهرس السور والإعدادات على اليمين (أيقونات فقط)
                            Positioned(
                              right: 0,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _showSurahSelector(context, state),
                                    icon: Icon(
                                      Icons.format_list_bulleted_rounded,
                                      color: const Color.fromARGB(
                                        255,
                                        252,
                                        252,
                                        252,
                                      ),
                                      size: 24.sp,
                                    ),
                                    tooltip: 'فهرس السور',
                                  ),
                                ],
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
      },
    );
  }
}
