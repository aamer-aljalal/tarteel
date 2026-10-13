import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/widgets/grids/access_list_grid.dart';
import 'package:tarteel/core/widgets/backgrounds/islamic_pattern_background.dart';
import 'package:tarteel/features/azkar/cubit/azkar_cubit.dart';
import 'package:tarteel/features/azkar/cubit/azkar_state.dart';

class AzkarCategoriesScreen extends StatelessWidget {
  const AzkarCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AzkarCubit(),
      child: const _AzkarCategoriesView(),
    );
  }
}

class _AzkarCategoriesView extends StatefulWidget {
  const _AzkarCategoriesView();

  @override
  State<_AzkarCategoriesView> createState() => _AzkarCategoriesViewState();
}

class _AzkarCategoriesViewState extends State<_AzkarCategoriesView>
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: tarteelAppBar(
          titleText: 'الأذكار',
          elevation: 0,
          showSearch: true,
          searchController: _searchController,
          searchHint: 'ابحث في أقسام الأذكار...',
          bottomHeight: 75,
          toolbarHeight: 80,
          onSearchChanged: (val) {
            context.read<AzkarCubit>().filterCategories(val);
          },
        ),
        body: IslamicPatternBackground(
          child: BlocConsumer<AzkarCubit, AzkarState>(
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
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64.sp,
                          color: Colors.red.shade400,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          state.errorMessage!,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        SizedBox(height: 12.h),
                        ElevatedButton(
                          onPressed: () {
                            context.read<AzkarCubit>().loadCategories();
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state.filteredActions.isEmpty) {
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
                          'لا توجد أذكار مطابقة لبحثك',
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
                            context.read<AzkarCubit>().clearSearch();
                          },
                          child: const Text(
                            'عرض كافة الأذكار',
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

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  children: [
                    AccessListGrid(
                      actions: state.filteredActions,
                      controller: _animationController,
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
