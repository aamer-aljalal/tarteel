import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/features/Hadith/hadith_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/services/stats_service.dart';
import 'package:tarteel/core/widgets/Text/Responsive_text.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  static const String _favoritesKey = 'favorite_hadith_numbers';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<HadithModel> _allHadiths = [];
  List<HadithModel> _filteredHadiths = [];
  Set<int> _favoriteNumbers = {};
  bool _isLoading = true;
  String? _errorMessage;
  double _hadithFontSize = 18.0;
  bool _showingFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadHadiths();
    _loadHadithFontSize();
    _searchController.addListener(_filterHadiths);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _openHadithByNumber(args);
      }
    });
  }

  Future<void> _loadHadithFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final double savedSize = prefs.getDouble('hadith_font_size') ?? 18.0;
    if (mounted) {
      setState(() {
        _hadithFontSize = savedSize;
      });
    }
  }

  Future<void> _setHadithFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('hadith_font_size', size);
    if (mounted) {
      setState(() {
        _hadithFontSize = size;
      });
    }
  }

  void _showTextSettings(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  16.h,
                  16.w,
                  24.h + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'إعدادات حجم خط الأحاديث',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black12 : Colors.grey.shade50,
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'أ',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: 'Amiri',
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: AppColors.goldAccent,
                                inactiveTrackColor: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade200,
                                thumbColor: AppColors.goldAccent,
                                overlayColor: AppColors.goldAccent.withValues(
                                  alpha: 0.2,
                                ),
                                valueIndicatorColor: AppColors.primary,
                                valueIndicatorTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Slider(
                                value: _hadithFontSize,
                                min: 14.0,
                                max: 28.0,
                                divisions: 7,
                                label: '${_hadithFontSize.toInt()}',
                                onChanged: (newSize) {
                                  setStateSheet(() {
                                    _hadithFontSize = newSize;
                                  });
                                },
                                onChangeEnd: (newSize) {
                                  _setHadithFontSize(newSize);
                                },
                              ),
                            ),
                          ),
                          Text(
                            'أ',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontFamily: 'Amiri',
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openHadithByNumber(int number) {
    if (_isLoading) {
      Future.delayed(
        const Duration(milliseconds: 100),
        () => _openHadithByNumber(number),
      );
      return;
    }
    try {
      final hadith = _allHadiths.firstWhere(
        (h) => h.number == number,
        orElse: () => _allHadiths.first,
      );
      _showHadithDetails(hadith);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHadiths() async {
    try {
      final results = await Future.wait([
        HadithService.loadHadiths(),
        SharedPreferences.getInstance(),
      ]);

      final hadiths = results[0] as List<HadithModel>;
      final prefs = results[1] as SharedPreferences;
      final favoriteNumbers = prefs.getStringList(_favoritesKey) ?? [];

      if (!mounted) return;
      setState(() {
        _allHadiths = hadiths;
        _filteredHadiths = hadiths;
        _favoriteNumbers = favoriteNumbers
            .map((number) => int.tryParse(number))
            .whereType<int>()
            .toSet();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر تحميل الأحاديث النبوية الشريفة';
        _isLoading = false;
      });
    }
  }

  void _filterHadiths() {
    final query = _searchController.text;
    if (_showingFavoritesOnly && query.isEmpty) {
      return;
    }
    setState(() {
      _showingFavoritesOnly = false;
      _filteredHadiths = _allHadiths
          .where((hadith) => hadith.matches(query))
          .toList(growable: false);
    });
  }

  Future<void> _toggleFavorite(HadithModel hadith) async {
    setState(() {
      if (_favoriteNumbers.contains(hadith.number)) {
        _favoriteNumbers.remove(hadith.number);
      } else {
        _favoriteNumbers.add(hadith.number);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoritesKey,
      _favoriteNumbers.map((number) => number.toString()).toList(),
    );
  }

  Future<void> _copyHadith(HadithModel hadith) async {
    await Clipboard.setData(
      ClipboardData(
        text: '${hadith.hadith}\n\n[الأربعون النووية - ${hadith.shortTitle}]',
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ الحديث الشريف بنجاح')));
  }

  void _openRandomHadith() {
    if (_allHadiths.isEmpty) return;
    final random = _allHadiths[math.Random().nextInt(_allHadiths.length)];
    _showHadithDetails(random);
  }

  void _toggleFavoritesView() {
    setState(() {
      _showingFavoritesOnly = !_showingFavoritesOnly;
      if (_showingFavoritesOnly) {
        _searchController.clear();
        _filteredHadiths = _allHadiths
            .where((hadith) => _favoriteNumbers.contains(hadith.number))
            .toList(growable: false);
      } else {
        _filteredHadiths = _allHadiths;
      }
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _showHadithDetails(HadithModel hadith) {
    final isFavorite = _favoriteNumbers.contains(hadith.number);
    _saveRecentHadithAction(hadith);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.82,
            minChildSize: 0.5,
            maxChildSize: 0.96,
            builder: (context, controller) {
              return _HadithDetailsSheet(
                hadith: hadith,
                isFavorite: isFavorite,
                controller: controller,
                onCopy: () => _copyHadith(hadith),
                onFavorite: () {
                  Navigator.pop(context);
                  _toggleFavorite(hadith);
                  // Refresh active detail view if it was reopened
                  Future.delayed(const Duration(milliseconds: 150), () {
                    _showHadithDetails(hadith);
                  });
                },
                fontSize: _hadithFontSize,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _saveRecentHadithAction(HadithModel hadith) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_hadith_number', hadith.number);
      await RecentActionsManager.addAction(
        category: 'hadith',
        title: 'الأربعون النووية - ${hadith.shortTitle}',
        subtitle: 'واصل قراءة ودراسة الأحاديث النبوية الشريفة',
        extraData: {'hadith_number': hadith.number},
      );

      // Record statistics
      await StatsService.recordAction('hadith');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: tarteelAppBar(
          titleText: 'الأربعون النووية',
          showSearch: true,
          searchController: _searchController,
          searchHint: 'ابحث في الأحاديث أو الشروحات...',
          actions: [
            IconButton(
              tooltip: 'إعدادات الخط',
              icon: const Icon(Icons.format_size_rounded),
              onPressed: _isLoading ? null : () => _showTextSettings(context),
            ),
            IconButton(
              tooltip: 'حديث عشوائي مبارك',
              icon: const Icon(Icons.shuffle_rounded),
              onPressed: _isLoading ? null : _openRandomHadith,
            ),
            IconButton(
              tooltip: _showingFavoritesOnly
                  ? 'عرض كل الأحاديث'
                  : 'الأحاديث المحفوظة',
              icon: Icon(
                _showingFavoritesOnly
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: _showingFavoritesOnly ? Colors.amber : null,
              ),
              onPressed: _isLoading ? null : _toggleFavoritesView,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.red.shade700,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Summary Bar
        _HadithSummaryBar(
          total: _allHadiths.length,
          visible: _filteredHadiths.length,
          favorites: _favoriteNumbers.length,
        ),

        // Hadith list
        Expanded(
          child: _filteredHadiths.isEmpty
              ? _EmptyHadithState(
                  onReset: () {
                    setState(() {
                      _searchController.clear();
                      _filteredHadiths = _allHadiths;
                    });
                  },
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                  itemCount: _filteredHadiths.length,
                  itemBuilder: (context, index) {
                    final hadith = _filteredHadiths[index];
                    return _HadithCard(
                      hadith: hadith,
                      isFavorite: _favoriteNumbers.contains(hadith.number),
                      onTap: () => _showHadithDetails(hadith),
                      onCopy: () => _copyHadith(hadith),
                      onFavorite: () => _toggleFavorite(hadith),
                      fontSize: _hadithFontSize,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _HadithSummaryBar extends StatelessWidget {
  const _HadithSummaryBar({
    required this.total,
    required this.visible,
    required this.favorites,
  });

  final int total;
  final int visible;
  final int favorites;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.library_books_rounded,
            color: AppColors.primary,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'الأحاديث المتاحة: $visible من $total',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 12.sp,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          Icon(Icons.star_rounded, color: Colors.amber, size: 18.sp),
          SizedBox(width: 4.w),
          Text(
            '$favorites محفوظ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w800,
              fontSize: 11.sp,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({
    required this.hadith,
    required this.isFavorite,
    required this.onTap,
    required this.onCopy,
    required this.onFavorite,
    required this.fontSize,
  });

  final HadithModel hadith;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final VoidCallback onFavorite;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final scale = fontSize / 18.0;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isFavorite
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : (isDark ? Colors.white10 : Colors.grey.shade100),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HadithNumber(number: hadith.number),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: ResponsiveText(
                        content: hadith.shortTitle,
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    IconButton(
                      tooltip: 'نسخ',
                      onPressed: onCopy,
                      icon: Icon(Icons.copy_rounded, size: 18.sp),
                      color: Colors.grey.shade500,
                    ),
                    IconButton(
                      tooltip: 'المفضلة',
                      onPressed: onFavorite,
                      icon: Icon(
                        isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 21.sp,
                      ),
                      color: isFavorite ? Colors.amber : Colors.grey.shade500,
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                ResponsiveText(
                  content: hadith.textOnly,
                  maxLines: 4,
                  textAlign: TextAlign.right,
                  fontSize: 20 * scale,
                  height: 1.8,
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Amiri',
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ResponsiveText(
                      content: 'عرض الشرح والفوائد',
                      color: AppColors.goldAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 10.sp,
                      color: AppColors.goldAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HadithNumber extends StatelessWidget {
  const _HadithNumber({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.5),
                width: 1.5.w,
              ),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
        Text(
          '$number',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _HadithDetailsSheet extends StatelessWidget {
  const _HadithDetailsSheet({
    required this.hadith,
    required this.isFavorite,
    required this.controller,
    required this.onCopy,
    required this.onFavorite,
    required this.fontSize,
  });

  final HadithModel hadith;
  final bool isFavorite;
  final ScrollController controller;
  final VoidCallback onCopy;
  final VoidCallback onFavorite;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50;
    final scale = fontSize / 18.0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Drag handle indicator
          SizedBox(height: 10.h),
          Center(
            child: Container(
              width: 50.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Details Toolbar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                _HadithNumber(number: hadith.number),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    hadith.shortTitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: 'نسخ الحديث',
                ),
                IconButton(
                  onPressed: onFavorite,
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  ),
                  color: isFavorite ? Colors.amber : null,
                  tooltip: 'حفظ للمفضلة',
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // Scrollable content
          Expanded(
            child: ListView(
              controller: controller,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              children: [
                // Noble Hadith Text Panel
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            color: AppColors.primary,
                            size: 20.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'متن الحديث الشريف:',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      ResponsiveText(
                        content: hadith.textOnly,
                        textAlign: TextAlign.justify,
                        fontSize: 16 * scale,
                        height: 1.9,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: 'Amiri',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // Explanation/Benefits Panel
                if (hadith.description.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              color: AppColors.goldAccent,
                              size: 20.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'شرح وفوائد الحديث الشريف:',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldAccent,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        ResponsiveText(
                          content: hadith.description,
                          textAlign: TextAlign.justify,
                          fontSize: 13 * scale,
                          height: 1.7,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontFamily: 'Cairo',
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHadithState extends StatelessWidget {
  const _EmptyHadithState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 10.h),
            Text(
              'لا توجد أحاديث مطابقة للبحث',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
              ),
            ),
            SizedBox(height: 6.h),
            TextButton(
              onPressed: onReset,
              child: const Text(
                'عرض كل أحاديث الأربعين النووية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
