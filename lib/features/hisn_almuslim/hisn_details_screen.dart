import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/Routes/AppRoutes.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/widgets/backgrounds/animated_sky_background.dart';
import 'package:tarteel/core/widgets/bottom_sheets/app_modal_bottom_sheet.dart';
import 'package:tarteel/core/widgets/buttons/interactive_counter_control.dart';
import 'package:tarteel/core/widgets/cards/interactive_content_card.dart';
import 'package:tarteel/core/widgets/progress/section_progress_bar.dart';
import 'package:tarteel/core/widgets/grids/access_list_grid.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_reader_cubit.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_reader_state.dart';
import 'package:tarteel/core/widgets/states/app_status_view.dart';
import 'package:tarteel/features/hisn_almuslim/model/hisn_category.dart';
import 'package:tarteel/features/hisn_almuslim/services/hisn_service.dart';

class HisnDetailsScreen extends StatelessWidget {
  final HisnCategory? category;
  final String? categoryTitle;

  const HisnDetailsScreen({super.key, this.category, this.categoryTitle})
      : assert(category != null || categoryTitle != null);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GenericReaderCubit<HisnCategory, String>(
        initialDetail: category,
        initialTitle: categoryTitle ?? category!.title,
        categoryKey: 'hisn',
        detailFetcher: HisnService.loadCategoryByTitle,
        itemsExtractor: (cat) => cat.texts,
        targetRepeatExtractor: (_) => 1,
      ),
      child: const _HisnDetailsView(),
    );
  }
}

class _HisnDetailsView extends StatefulWidget {
  const _HisnDetailsView();

  @override
  State<_HisnDetailsView> createState() => _HisnDetailsViewState();
}

class _HisnDetailsViewState extends State<_HisnDetailsView> {
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
    final cubit = context.read<GenericReaderCubit<HisnCategory, String>>();
    final currentTitle = cubit.state.title;

    final actions = await HisnService.loadHisnAsActions();
    if (!context.mounted) return;

    AppModalBottomSheet.show(
      context: context,
      title: 'أبواب حصن المسلم',
      subtitle: 'اختر الباب الذي ترغب بالانتقال إليه مباشرة',
      heightFraction: 0.72,
      child: AccessListGrid(
        actions: actions,
        isRectangle: true,
        selectedTitle: currentTitle,
        padding: EdgeInsets.zero,
        onItemTap: (item) {
          Navigator.pop(context);
          if (!context.mounted) return;
          if (item.title != currentTitle) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => HisnDetailsScreen(categoryTitle: item.title),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<GenericReaderCubit<HisnCategory, String>,
        GenericReaderState<HisnCategory, String>>(
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
                    .read<GenericReaderCubit<HisnCategory, String>>()
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
              title: 'لا توجد أدعية في هذا الباب حالياً',
              icon: Icons.auto_stories_outlined,
            ),
          );
        }

        final category = state.detail!;

        return Scaffold(
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
                    totalCount: category.texts.length,
                    isZeroBasedIndex: true,
                  ),

                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: category.texts.length,
                      onPageChanged: (index) {
                        context
                            .read<GenericReaderCubit<HisnCategory, String>>()
                            .changePage(index);
                      },
                      itemBuilder: (context, index) {
                        final text = category.texts[index];
                        String? footnote;
                        if (category.footnotes.length > index) {
                          footnote = category.footnotes[index];
                        }

                        return AnimatedPadding(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.only(
                            left: 20.w,
                            right: 20.w,
                            top: 20.h,
                          ),
                          child: InteractiveContentCard(
                            content: text,
                            indexLabel: 'الدعاء ${index + 1}',
                            showFavorite: true,
                            favoriteType: 'hisn',
                            description: footnote,
                            showCounterBadge: false,
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
                    showResetButton: true,
                    resetConfirmTitle: 'إعادة تعيين الأدعية',
                    resetConfirmMessage:
                        'هل تريد إعادة تعيين عداد القراءة لكافة الأدعية في هذا القسم والبدء من جديد؟',
                    resetConfirmActionText: 'نعم، تصفير',
                    resetColor: Colors.redAccent,
                    cornerAction: CounterSideAction(
                      icon: Icons.format_list_bulleted_rounded,
                      tooltip: 'أبواب حصن المسلم',
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
        );
      },
    );
  }
}
