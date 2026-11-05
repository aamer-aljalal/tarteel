import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_catalog_cubit.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_catalog_state.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/widgets/backgrounds/islamic_pattern_background.dart';
import 'package:tarteel/core/widgets/buttons/app_glass_button.dart';
import 'package:tarteel/core/widgets/grids/access_list_grid.dart';
import 'package:tarteel/core/widgets/states/app_status_view.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/views/quran_verse_search_page.dart';
import 'package:tarteel/features/quran/views/surah_detail_page.dart';

class SurahListPage extends StatelessWidget {
  const SurahListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GenericCatalogCubit<AccessListModel, QuranSurah>(
        loader: const QuranService(),
        titleExtractor: (item) =>
            '${item.title} ${(item.arguments is QuranSurah) ? (item.arguments as QuranSurah).nameArabic : ''} ${(item.arguments is QuranSurah) ? (item.arguments as QuranSurah).nameEnglish : ''} ${(item.arguments is QuranSurah) ? (item.arguments as QuranSurah).transliteration : ''} ${item.badge ?? ''} ${item.subtitle ?? ''}',
      ),
      child: const _SurahListView(),
    );
  }
}

class _SurahListView extends StatefulWidget {
  const _SurahListView();

  @override
  State<_SurahListView> createState() => _SurahListViewState();
}

class _SurahListViewState extends State<_SurahListView>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openSurah(BuildContext context, QuranSurah surah) async {
    final ayahs = await QuranService.loadAyahs(surah.number);
    if (!context.mounted) return;

    final startPage = ayahs.isNotEmpty
        ? ayahs.first.page
        : QuranService.getSurahStartPage(surah.number);
    final targetPage = (startPage - 1).clamp(0, 603);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahDetailPage(
          surah: surah,
          ayahs: ayahs,
          initialPage: targetPage,
        ),
      ),
    );
  }



  Future<void> _openSavedBookmark(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final surahNumber = prefs.getInt('quran_bookmark_surah');
      final ayahNumber = prefs.getInt('quran_bookmark_ayah');
      final pageNumber = prefs.getInt('quran_bookmark_page');

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading indicator

      if (surahNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم تقم بحفظ علامة مرجعية بعد'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final surahs = await QuranService.loadSurahs();
      final surah = surahs.firstWhere((s) => s.number == surahNumber);
      final ayahs = await QuranService.loadAyahs(surahNumber);

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SurahDetailPage(
            surah: surah,
            ayahs: ayahs,
            initialPage: pageNumber != null ? (pageNumber - 1) : null,
            initialAyah: ayahNumber,
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الانتقال إلى الصفحة المحفوظة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: tarteelAppBar(
          titleText: 'القرآن الكريم',
          elevation: 0,
          showSearch: true,
          searchController: _searchController,
          searchHint: 'ابحث عن سورة بالاسم أو الرقم...',
          bottomHeight: 75,
          toolbarHeight: 80,
          centerTitle: true,
          searchActions: [
            // زر الانتقال للعلامة المرجعية المحفوظة (دائري بنفس أسلوب أزرار المصحف)
            AppGlassButton(
              onTap: () => _openSavedBookmark(context),
              tooltip: 'الانتقال إلى موضع القراءة المحفوظ',
              isCircle: true,
              width: 38.w,
              height: 38.h,
              child: Icon(
                Icons.bookmark_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            // زر البحث في آيات المصحف (دائري بنفس أسلوب أزرار المصحف)
            AppGlassButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QuranVerseSearchPage(),
                  ),
                );
              },
              tooltip: 'البحث في آيات القرآن الكريم',
              isCircle: true,
              width: 38.w,
              height: 38.h,
              child: Icon(
                Icons.manage_search_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ],
          onSearchChanged: (val) {
            context
                .read<GenericCatalogCubit<AccessListModel, QuranSurah>>()
                .search(val);
          },
        ),
        body: IslamicPatternBackground(
          child:
              BlocConsumer<
                GenericCatalogCubit<AccessListModel, QuranSurah>,
                GenericCatalogState<AccessListModel>
              >(
                listener: (context, state) {
                  if (!state.isLoading && state.errorMessage == null) {
                    _animationController.reset();
                    _animationController.forward();
                  }
                },
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.errorMessage != null) {
                    return AppStatusView.error(
                      message: state.errorMessage!,
                      onRetry: () {
                        context
                            .read<
                              GenericCatalogCubit<AccessListModel, QuranSurah>
                            >()
                            .loadCatalog();
                      },
                    );
                  }

                  if (state.filteredItems.isEmpty) {
                    return AppStatusView.empty(
                      title: 'لا توجد سور مطابقة لبحثك',
                      icon: Icons.search_off_rounded,
                      buttonText: 'عرض كافة السور',
                      onButtonPressed: () {
                        _searchController.clear();
                        context
                            .read<
                              GenericCatalogCubit<AccessListModel, QuranSurah>
                            >()
                            .clearSearch();
                      },
                    );
                  }

                  return AccessListGrid(
                    actions: state.filteredItems,
                    isRectangle: true,
                    header: null,
                    padding: EdgeInsets.only(
                      left: 20.w,
                      right: 20.w,
                      top: 16.h,
                      bottom: 50.h,
                    ),
                    controller: _animationController,
                    onItemTap: (item) async {
                      if (item.arguments is QuranSurah) {
                        _openSurah(context, item.arguments as QuranSurah);
                      } else {
                        final surahs = await QuranService.loadSurahs();
                        final surahNumber = int.tryParse(item.id ?? '') ?? 1;
                        final surah = surahs.firstWhere(
                          (s) => s.number == surahNumber,
                          orElse: () => surahs.first,
                        );
                        if (context.mounted) {
                          _openSurah(context, surah);
                        }
                      }
                    },
                  );
                },
              ),
        ),
      ),
    );
  }
}
