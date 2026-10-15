import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_catalog_cubit.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_catalog_state.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/widgets/grids/access_list_grid.dart';
import 'package:tarteel/core/widgets/backgrounds/islamic_pattern_background.dart';
import 'package:tarteel/features/hisn_almuslim/cubit/hisn_catalog_bridge.dart';
import 'package:tarteel/features/hisn_almuslim/model/hisn_category.dart';

class HisnCategoriesScreen extends StatelessWidget {
  const HisnCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HisnCubitFactory.create(),
      child: const _HisnCategoriesView(),
    );
  }
}

class _HisnCategoriesView extends StatefulWidget {
  const _HisnCategoriesView();

  @override
  State<_HisnCategoriesView> createState() => _HisnCategoriesViewState();
}

class _HisnCategoriesViewState extends State<_HisnCategoriesView>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 650),
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
          titleText: 'حصن المسلم',
          showSearch: true,
          searchController: _searchController,
          searchHint: 'ابحث عن دعاء أو ذكر...',
          bottomHeight: 75,
          toolbarHeight: 80,
          onSearchChanged: (val) {
            context
                .read<GenericCatalogCubit<AccessListModel, HisnCategory>>()
                .search(val);
          },
        ),
        body: IslamicPatternBackground(
          child: BlocConsumer<
              GenericCatalogCubit<AccessListModel, HisnCategory>,
              GenericCatalogState<AccessListModel>>(
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
                            context
                                .read<
                                    GenericCatalogCubit<AccessListModel,
                                        HisnCategory>>()
                                .loadCatalog();
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state.filteredItems.isEmpty) {
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
                            context
                                .read<
                                    GenericCatalogCubit<AccessListModel,
                                        HisnCategory>>()
                                .clearSearch();
                          },
                          child: const Text(
                            'عرض كل الفصول',
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
                      actions: state.filteredItems,
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
