import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_catalog_cubit.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_catalog_state.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/widgets/grids/access_list_grid.dart';
import 'package:tarteel/core/widgets/backgrounds/islamic_pattern_background.dart';
import 'package:tarteel/core/widgets/states/app_status_view.dart';
import 'package:tarteel/features/azkar/model/zekr_category.dart';
import 'package:tarteel/features/azkar/services/azkar_service.dart';

class AzkarCategoriesScreen extends StatelessWidget {
  const AzkarCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GenericCatalogCubit<AccessListModel, ZekrCategory>(
        loader: AzkarService(),
        titleExtractor: (item) => item.title,
      ),
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
            context
                .read<GenericCatalogCubit<AccessListModel, ZekrCategory>>()
                .search(val);
          },
        ),
        body: IslamicPatternBackground(
          child:
              BlocConsumer<
                GenericCatalogCubit<AccessListModel, ZekrCategory>,
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
                              GenericCatalogCubit<AccessListModel, ZekrCategory>
                            >()
                            .loadCatalog();
                      },
                    );
                  }

                  if (state.filteredItems.isEmpty) {
                    return AppStatusView.empty(
                      title: 'لا توجد أذكار مطابقة لبحثك',
                      icon: Icons.search_off_rounded,
                      buttonText: 'عرض كافة الأذكار',
                      onButtonPressed: () {
                        _searchController.clear();
                        context
                            .read<
                              GenericCatalogCubit<AccessListModel, ZekrCategory>
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
