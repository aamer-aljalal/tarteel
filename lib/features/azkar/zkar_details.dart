import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/features/azkar/model/zekr_category.dart';
import 'package:tarteel/features/azkar/model/zekr_model%20.dart';
import 'package:tarteel/core/widgets/buttons/interactive_counter_control.dart';
import 'package:tarteel/core/widgets/cards/interactive_content_card.dart';
import 'package:tarteel/core/widgets/bottom_sheets/app_modal_bottom_sheet.dart';
import 'package:tarteel/Routes/AppRoutes.dart';
import 'package:tarteel/core/widgets/backgrounds/animated_sky_background.dart';
import 'package:tarteel/features/azkar/services/azkar_service.dart';
import 'package:tarteel/core/widgets/grids/access_list_grid.dart';
import 'package:tarteel/core/widgets/progress/section_progress_bar.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_reader_cubit.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_reader_state.dart';
import 'package:tarteel/core/widgets/states/app_status_view.dart';

class AzkarDetailsScreen extends StatelessWidget {
  final ZekrCategory? category;
  final String? categoryTitle;

  const AzkarDetailsScreen({super.key, this.category, this.categoryTitle})
    : assert(category != null || categoryTitle != null);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GenericReaderCubit<ZekrCategory, ZekrModel>(
        initialDetail: category,
        initialTitle: categoryTitle ?? category!.title,
        categoryKey: 'azkar',
        detailFetcher: AzkarService.loadCategoryByTitle,
        itemsExtractor: (cat) => cat.azkar,
        targetRepeatExtractor: (zekr) => int.tryParse(zekr.count) ?? 1,
      ),
      child: const _AzkarDetailsView(),
    );
  }
}

class _AzkarDetailsView extends StatefulWidget {
  const _AzkarDetailsView();

  @override
  State<_AzkarDetailsView> createState() => _AzkarDetailsViewState();
}

class _AzkarDetailsViewState extends State<_AzkarDetailsView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showCategoriesBottomSheet(BuildContext context) async {
    HapticFeedback.lightImpact();
    final cubit = context.read<GenericReaderCubit<ZekrCategory, ZekrModel>>();
    final currentTitle = cubit.state.title;

    final actions = await AzkarService.loadAzkarAsActions();
    if (!context.mounted) return;

    AppModalBottomSheet.show(
      context: context,
      title: 'أقسام الأذكار',
      subtitle: 'اختر القسم الذي ترغب بالانتقال إليه مباشرة',
      heightFraction: 0.72,
      child: AccessListGrid(
        actions: actions,
        isRectangle: true,
        selectedTitle: currentTitle,
        padding: EdgeInsets.zero,
        onItemTap: (item) {
          Navigator.pop(context);
          if (item.title != currentTitle) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AzkarDetailsScreen(categoryTitle: item.title),
              ),
            );
          }
        },
      ),
    );
  }

  void _showCompletionSheet(BuildContext context) {
    final cubit = context.read<GenericReaderCubit<ZekrCategory, ZekrModel>>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.primary,
              size: 72.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              'تقبل الله طاعتك',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'لقد أتممت قراءة كافة أذكار ${cubit.state.title} بنجاح.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                fontFamily: 'Cairo',
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      cubit.resetCategory();
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(0);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text(
                      'البدء من جديد',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text(
                      'العودة للأذكار',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<
      GenericReaderCubit<ZekrCategory, ZekrModel>,
      GenericReaderState<ZekrCategory, ZekrModel>
    >(
      listener: (context, state) {
        if (_pageController.hasClients &&
            _pageController.page?.round() != state.currentIndex) {
          _pageController.jumpToPage(state.currentIndex);
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: tarteelAppBar(
              titleText: state.title,
              elevation: 0,
              toolbarHeight: 90,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.errorMessage != null) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: tarteelAppBar(
              titleText: state.title,
              elevation: 0,
              toolbarHeight: 90,
            ),
            body: AppStatusView.error(
              message: state.errorMessage!,
              onRetry: () {
                context
                    .read<GenericReaderCubit<ZekrCategory, ZekrModel>>()
                    .reload();
              },
            ),
          );
        }

        if (state.items.isEmpty) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: tarteelAppBar(
              titleText: state.title,
              elevation: 0,
              toolbarHeight: 90,
            ),
            body: AppStatusView.empty(
              title: 'لا توجد أذكار في هذا القسم حالياً',
              icon: Icons.bookmark_border_rounded,
            ),
          );
        }

        final cubit = context.read<GenericReaderCubit<ZekrCategory, ZekrModel>>();

        return ReaderScope(
          cubit: cubit,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: tarteelAppBar(
              titleText: state.title,
              elevation: 0,
              toolbarHeight: 90,
            ),
            body: AnimatedSkyBackground(
              categoryTitle: state.title,
              child: SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 16.h),
                    SectionProgressBar(
                      currentIndex: state.currentIndex,
                      totalCount: state.totalCount,
                      isZeroBasedIndex: true,
                    ),

                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: state.totalCount,
                        onPageChanged: (index) {
                          context
                              .read<GenericReaderCubit<ZekrCategory, ZekrModel>>()
                              .changePage(index);
                        },
                        itemBuilder: (context, index) {
                          final zekr = state.items[index];

                          return AnimatedPadding(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.only(
                              left: 20.w,
                              right: 20.w,
                              top: 20.h,
                            ),
                            child: InteractiveContentCard(
                              content: zekr.content,
                              indexLabel: 'الذكر ${index + 1}',
                              showFavorite: true,
                              favoriteType: 'azkar',
                              description: zekr.description,
                              reference: zekr.reference,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 60.h),

                    InteractiveCounterControl(
                      pageController: _pageController,
                      autoNextOnComplete: true,
                      allowOvercount: false,
                      showNavigationButtons: true,
                      showResetButton: true,
                      onAllCompleted: () => _showCompletionSheet(context),
                      cornerAction: CounterSideAction(
                        icon: Icons.format_list_bulleted_rounded,
                        tooltip: 'أقسام الأذكار',
                        onTap: () => _showCategoriesBottomSheet(context),
                      ),
                      leftCornerAction: CounterSideAction(
                        icon: Icons.home_rounded,
                        tooltip: 'الصفحة الرئيسية',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.homePage,
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
