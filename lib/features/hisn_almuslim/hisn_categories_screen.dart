import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/widgets/grids/access_list_grid.dart';
import 'package:tarteel/features/hisn_almuslim/services/hisn_service.dart';

class HisnCategoriesScreen extends StatefulWidget {
  const HisnCategoriesScreen({super.key});

  @override
  State<HisnCategoriesScreen> createState() => _HisnCategoriesScreenState();
}

class _HisnCategoriesScreenState extends State<HisnCategoriesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;

  List<AccessListModel> _allActions = [];
  List<AccessListModel> _filteredActions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _loadCategories();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final actions = await HisnService.loadHisnAsActions();
      if (!mounted) return;
      setState(() {
        _allActions = actions;
        _filteredActions = actions;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر تحميل كتاب حصن المسلم';
        _isLoading = false;
      });
    }
  }

  void _filterCategories() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredActions = _allActions;
      } else {
        _filteredActions = _allActions
            .where((action) => action.title.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: tarteelAppBar(
          titleText: 'حصن المسلم',
          showSearch: true,
          searchController: _searchController,
          searchHint: 'ابحث عن دعاء أو ذكر...',
          bottomHeight: 75,
          toolbarHeight: 80,
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
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64.sp, color: Colors.red.shade400),
              SizedBox(height: 16.h),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredActions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64.sp,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 16.h),
              Text(
                'لا توجد نتائج مطابقة لبحثك',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                  fontFamily: 'Cairo',
                ),
              ),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                },
                child: const Text(
                  'عرض كل الفصول',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        children: [
          AccessListGrid(
            actions: _filteredActions,
            controller: _animationController,
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}
