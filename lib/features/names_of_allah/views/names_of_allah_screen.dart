import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/features/names_of_allah/models/name_model.dart';
import 'package:tarteel/features/names_of_allah/services/names_of_allah_service.dart';
import 'package:tarteel/features/names_of_allah/views/names_of_allah_detail_screen.dart';

class NamesOfAllahScreen extends StatefulWidget {
  final NameCategory initialCategory;

  const NamesOfAllahScreen({
    super.key,
    this.initialCategory = NameCategory.allah,
  });

  @override
  State<NamesOfAllahScreen> createState() => _NamesOfAllahScreenState();
}

class _NamesOfAllahScreenState extends State<NamesOfAllahScreen> {
  final TextEditingController _searchController = TextEditingController();

  late NameCategory _selectedCategory;

  List<AllahName> _allahNames = [];
  List<AllahName> _prophetNames = [];

  List<AllahName> _filteredNames = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _loadAllData();
    _searchController.addListener(_filterNames);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        NamesOfAllahService.loadAllahNames(),
        NamesOfAllahService.loadProphetNames(),
      ]);

      if (!mounted) return;

      setState(() {
        _allahNames = results[0];
        _prophetNames = results[1];
        _isLoading = false;
        _filterNames();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر تحميل البيانات، يرجى المحاولة لاحقاً';
        _isLoading = false;
      });
    }
  }

  List<AllahName> get _currentSourceList {
    return _selectedCategory == NameCategory.prophet
        ? _prophetNames
        : _allahNames;
  }

  void _filterNames() {
    final query = _searchController.text.trim().toLowerCase();
    final sourceList = _currentSourceList;

    setState(() {
      if (query.isEmpty) {
        _filteredNames = sourceList;
      } else {
        _filteredNames = sourceList.where((item) {
          return item.name.contains(query) ||
              item.text.contains(query) ||
              item.id.toString().contains(query);
        }).toList();
      }
    });
  }

  void _onCategoryChanged(NameCategory category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
      _filterNames();
    });
  }

  void _navigateToDetail(AllahName nameItem) {
    final sourceList = _currentSourceList;
    final originalIndex = sourceList.indexOf(nameItem);
    if (originalIndex != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NamesOfAllahDetailScreen(
            names: sourceList,
            initialIndex: originalIndex,
            category: _selectedCategory,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProphet = _selectedCategory == NameCategory.prophet;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: tarteelAppBar(
          titleText: isProphet ? 'أسماء النبي ﷺ' : 'أسماء الله الحسنى',
          showSearch: true,
          searchController: _searchController,
          searchHint: isProphet
              ? 'ابحث عن اسم من أسماء النبي...'
              : 'ابحث عن اسم من أسماء الله...',
          centerTitle: true,
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildCategorySelector(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  /// Category Selector Tabs (أسماء الله الحسنى / أسماء النبي ﷺ)
  Widget _buildCategorySelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabItem(
                title: 'أسماء الله الحسنى',
                category: NameCategory.allah,
                icon: Icons.auto_awesome,
                activeColor: isDark ? AppColors.goldAccent : AppColors.primary,
              ),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: _buildTabItem(
                title: 'أسماء النبي ﷺ',
                category: NameCategory.prophet,
                icon: Icons.stars_rounded,
                activeColor: const Color(0xFFD4AF37),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required String title,
    required NameCategory category,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedCategory == category;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => _onCategoryChanged(category),
      borderRadius: BorderRadius.circular(12.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: isSelected
                  ? (category == NameCategory.allah && !isDark
                      ? Colors.white
                      : (category == NameCategory.prophet && isDark
                          ? AppColors.darkBackground
                          : Colors.white))
                  : (isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText),
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? (category == NameCategory.allah && !isDark
                        ? Colors.white
                        : (category == NameCategory.prophet && isDark
                            ? AppColors.darkBackground
                            : Colors.white))
                    : (isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            _selectedCategory == NameCategory.prophet
                ? const Color(0xFFD4AF37)
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.goldAccent
                    : AppColors.primary),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (_filteredNames.isEmpty) {
      return Center(
        child: Text(
          'لا توجد نتائج مطابقة لبحثك',
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.1,
      ),
      itemCount: _filteredNames.length,
      itemBuilder: (context, index) {
        final item = _filteredNames[index];
        return _NameGridTile(
          nameItem: item,
          category: _selectedCategory,
          onTap: () => _navigateToDetail(item),
        );
      },
    );
  }
}

class _NameGridTile extends StatelessWidget {
  final AllahName nameItem;
  final NameCategory category;
  final VoidCallback onTap;

  const _NameGridTile({
    required this.nameItem,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isProphet = category == NameCategory.prophet;

    final badgeColor = isProphet
        ? const Color(0xFFD4AF37)
        : (isDark ? AppColors.goldAccent : AppColors.primary);

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isProphet
                  ? AppColors.goldAccent.withValues(alpha: 0.25)
                  : (isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Beautiful ornamental ID Circle in the corner
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  width: 26.w,
                  height: 26.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '${nameItem.id}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ),

              // Centered name
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nameItem.name,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        nameItem.text.isNotEmpty
                            ? nameItem.text
                            : 'صَلَّى اللّٰهُ عَلَيْهِ وَسَلَّمَ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
