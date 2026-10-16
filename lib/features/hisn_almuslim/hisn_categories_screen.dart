import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_catalog_cubit.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_catalog_state.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/widgets/grids/access_list_grid.dart';
import 'package:tarteel/core/widgets/backgrounds/islamic_pattern_background.dart';
import 'package:tarteel/core/widgets/states/app_status_view.dart';
import 'package:tarteel/features/hisn_almuslim/model/hisn_category.dart';
import 'package:tarteel/features/hisn_almuslim/services/hisn_service.dart';

class HisnCategoriesScreen extends StatelessWidget {
  const HisnCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GenericCatalogCubit<AccessListModel, HisnCategory>(
        loader: HisnService(),
        titleExtractor: (item) => item.title,
      ),
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
          child:
              BlocConsumer<
                GenericCatalogCubit<AccessListModel, HisnCategory>,
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
                              GenericCatalogCubit<AccessListModel, HisnCategory>
                            >()
                            .loadCatalog();
                      },
                    );
                  }

                  if (state.filteredItems.isEmpty) {
                    return AppStatusView.empty(
                      title: 'لا توجد نتائج مطابقة لبحثك',
                      icon: Icons.search_off_rounded,
                      buttonText: 'عرض كل الفصول',
                      onButtonPressed: () {
                        _searchController.clear();
                        context
                            .read<
                              GenericCatalogCubit<AccessListModel, HisnCategory>
                            >()
                            .clearSearch();
                      },
                    );
                  }

                  return AccessListGrid(
                    actions: state.filteredItems,
                    padding: EdgeInsets.only(
                      left: 20.w,
                      right: 20.w,
                      top: 20.h,
                      bottom: 50.h,
                    ),
                    controller: _animationController,
                  );
                },
              ),
        ),
      ),
    );
  }
}
