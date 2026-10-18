import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/helpers/arabic_search_helper.dart';
import 'package:tarteel/core/theme/app_theme.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/views/surah_detail_page.dart';

class QuranVerseSearchPage extends StatefulWidget {
  const QuranVerseSearchPage({super.key});

  @override
  State<QuranVerseSearchPage> createState() => _QuranVerseSearchPageState();
}

class _QuranVerseSearchPageState extends State<QuranVerseSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchableAyah> _allAyahs = [];
  List<SearchableAyah> _filteredAyahs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final ayahs = await QuranService.loadAllSearchableAyahs();
    if (mounted) {
      setState(() {
        _allAyahs = ayahs;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = ArabicSearchHelper.normalize(_searchController.text);
    if (query.isEmpty) {
      setState(() {
        _filteredAyahs = [];
      });
      return;
    }

    final results = _allAyahs.where((ayah) {
      return ayah.normalizedText.contains(query);
    }).toList();

    setState(() {
      _filteredAyahs = results;
    });
  }

  void _openSurahAtVerse(SearchableAyah searchableAyah) async {
    final ayahs = await QuranService.loadAyahs(searchableAyah.surah.number);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahDetailPage(
          surah: searchableAyah.surah,
          ayahs: ayahs,
          initialAyah: searchableAyah.ayah.verse,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: tarteelAppBar(
          titleText: 'البحث في الآيات',
          showSearch: true,
          searchController: _searchController,
          searchHint: 'اكتب كلمة للبحث في القرآن...',
          centerTitle: true,
          elevation: 0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Text(
          'اكتب كلمة للبحث في القرآن الكريم',
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.grey,
            fontFamily: 'Cairo',
          ),
        ),
      );
    }

    if (_filteredAyahs.isEmpty) {
      return Center(
        child: Text(
          'لا توجد نتائج مطابقة',
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.grey,
            fontFamily: 'Cairo',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _filteredAyahs.length,
      itemBuilder: (context, index) {
        final item = _filteredAyahs[index];
        return _VerseTile(
          searchableAyah: item,
          onTap: () => _openSurahAtVerse(item),
        );
      },
    );
  }
}

class _VerseTile extends StatelessWidget {
  const _VerseTile({required this.searchableAyah, required this.onTap});

  final SearchableAyah searchableAyah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'سورة ${searchableAyah.surah.nameArabic}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppColors.goldAccent
                            : AppColors.primary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'آية ${searchableAyah.ayah.verse}',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12.sp,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  searchableAyah.ayah.text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 20.sp,
                    fontFamily: 'Amiri',
                    height: 1.8,
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
