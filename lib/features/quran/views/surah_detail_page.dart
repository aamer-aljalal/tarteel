import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/bottom_sheets/app_modal_bottom_sheet.dart';
import 'package:tarteel/core/widgets/buttons/app_button.dart';
import 'package:tarteel/core/widgets/buttons/app_glass_button.dart';
import 'package:tarteel/core/widgets/dialogs/app_confirm_dialog.dart';
import 'package:tarteel/features/quran/cubit/quran_reader_cubit.dart';
import 'package:tarteel/features/quran/cubit/quran_reader_state.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/widgets/ayah_top_bar.dart';
import 'package:tarteel/features/quran/widgets/mushaf_page.dart';

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
      return await AppConfirmDialog.show(
        context,
        title: 'تحديث الختمة',
        message:
            'لقد تقدمت في القراءة دون تحديث موضع الختمة. هل تود الخروج دون تحديث الموضع؟',
        confirmText: 'الخروج بدون تحديث',
        cancelText: 'العودة للتحديث',
        icon: Icons.bookmark_border_rounded,
      );
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
                    text: 'عرض التفسير الآية',
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
                            context.read<QuranReaderCubit>().copyAyah(ayah);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ الآية')),
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
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final isAdded = await context
                                .read<QuranReaderCubit>()
                                .toggleFavoriteAyah(
                                  ayah: ayah,
                                  interpretation: interpretation,
                                );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAdded
                                        ? 'تمت إضافة الآية للمفضلة'
                                        : 'تمت إزالة الآية من المفضلة',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  // 5. زر تحديث الختمة (إذا كانت الجلسة جلسة ختمة)
                  if (widget.isKhatmaSession) ...[
                    SizedBox(height: 10.h),
                    AppButton(
                      text:
                          'حفظ موضع الختمة (صفحة ${context.read<QuranReaderCubit>().state.currentPageNumber})',
                      leadingIcon: Icons.bookmark_added_rounded,
                      variant: AppButtonVariant.gold,
                      size: AppButtonSize.medium,
                      isFullWidth: true,
                      borderRadius: 14.r,
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final cubit = context.read<QuranReaderCubit>();
                        final pageNum = cubit.state.currentPageNumber;
                        final success = await cubit.updateKhatmaBookmark(ayah);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'تم حفظ موضع الختمة عند صفحة $pageNum بنجاح'
                                    : 'حدث خطأ أثناء حفظ موضع الختمة',
                              ),
                            ),
                          );
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
      wrapWithScrollView: false,
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
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: state.pages.length,
                            physics: const ClampingScrollPhysics(),
                            onPageChanged: (index) {
                              context.read<QuranReaderCubit>().changePage(
                                index,
                              );
                            },
                            itemBuilder: (context, index) {
                              return _buildPageSliver(context, state, index);
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
                            // 1. أزرار التنقل بين السور على الجانب الأيسر (أزرار أنيقة بحدود بيضاء وعرض متجاوب ثابت)
                            Positioned(
                              left: 8.w,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // زر السورة السابقة
                                  if (state.prevSurah != null)
                                    AppGlassButton(
                                      onTap: () {
                                        context
                                            .read<QuranReaderCubit>()
                                            .navigateToSurah(
                                              state.prevSurah!.number,
                                            );
                                      },
                                      tooltip:
                                          'السورة السابقة: ${state.prevSurah!.nameArabic}',
                                      width: 76.w,
                                      height: 30.h,
                                      borderRadius: 6.r,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.arrow_back_ios_rounded,
                                            color: Colors.white,
                                            size: 11.sp,
                                          ),
                                          SizedBox(width: 3.w),
                                          Text(
                                            state.prevSurah!.nameArabic,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11.5.sp,
                                              fontFamily: 'Cairo',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  if (state.prevSurah != null &&
                                      state.nextSurah != null)
                                    SizedBox(width: 6.w),

                                  // زر السورة التالية
                                  if (state.nextSurah != null)
                                    AppGlassButton(
                                      onTap: () {
                                        context
                                            .read<QuranReaderCubit>()
                                            .navigateToSurah(
                                              state.nextSurah!.number,
                                            );
                                      },
                                      tooltip:
                                          'السورة التالية: ${state.nextSurah!.nameArabic}',
                                      width: 76.w,
                                      height: 30.h,
                                      borderRadius: 6.r,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            state.nextSurah!.nameArabic,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11.5.sp,
                                              fontFamily: 'Cairo',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 3.w),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: Colors.white,
                                            size: 11.sp,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // 2. أزرار الشريط السفلي على اليمين: فهرس السور وزر حفظ العلامة المرجعية (أزرار دائرية أنيقة)
                            Positioned(
                              right: 8.w,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // زر فهرس السور (دائري بخلفية شفافة وحدود بيضاء)
                                  AppGlassButton(
                                    onTap: () =>
                                        _showSurahSelector(context, state),
                                    tooltip: 'فهرس السور',
                                    isCircle: true,
                                    width: 32.w,
                                    height: 32.h,
                                    child: Icon(
                                      Icons.format_list_bulleted_rounded,
                                      color: Colors.white,
                                      size: 18.sp,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  // زر حفظ العلامة المرجعية للصفحة (دائري ويتحول للأحمر عند حفظها)
                                  AppGlassButton(
                                    onTap: () async {
                                      final cubit = context
                                          .read<QuranReaderCubit>();
                                      final pageNum =
                                          cubit.state.currentPageNumber;

                                      bool success = false;
                                      if (widget.isKhatmaSession) {
                                        // إذا كانت الجلسة جلسة ختمة يحفظ فقط موضع الختمة
                                        success = await cubit
                                            .updateKhatmaBookmark();
                                      } else {
                                        // إذا كانت جلسة عادية يحفظ فقط العلامة المرجعية العادية
                                        success = await cubit
                                            .savePageBookmark();
                                      }

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              success
                                                  ? (widget.isKhatmaSession
                                                        ? 'تم حفظ موضع الختمة عند صفحة $pageNum'
                                                        : 'تم حفظ العلامة المرجعية عند صفحة $pageNum')
                                                  : 'تعذر حفظ العلامة المرجعية',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    tooltip: widget.isKhatmaSession
                                        ? 'حفظ موضع الختمة لهذه الصفحة'
                                        : 'حفظ العلامة المرجعية لهذه الصفحة',
                                    isCircle: true,
                                    width: 32.w,
                                    height: 32.h,
                                    borderColor: state.isCurrentPageBookmarked
                                        ? Colors.redAccent.withValues(
                                            alpha: 0.8,
                                          )
                                        : Colors.white.withValues(alpha: 0.5),
                                    backgroundColor:
                                        state.isCurrentPageBookmarked
                                        ? Colors.redAccent.withValues(
                                            alpha: 0.15,
                                          )
                                        : Colors.white.withValues(alpha: 0.08),
                                    child: Icon(
                                      state.isCurrentPageBookmarked
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_outline_rounded,
                                      color: state.isCurrentPageBookmarked
                                          ? Colors.redAccent
                                          : Colors.white,
                                      size: 18.sp,
                                    ),
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
