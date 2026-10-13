import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/Routes/AppRoutes.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/widgets/backgrounds/animated_sky_background.dart';
import 'package:tarteel/core/widgets/bottom_sheets/app_modal_bottom_sheet.dart';
import 'package:tarteel/core/widgets/buttons/interactive_counter_control.dart';
import 'package:tarteel/core/widgets/cards/interactive_content_card.dart';
import 'package:tarteel/core/widgets/progress/section_progress_bar.dart';
import 'package:tarteel/features/hisn_almuslim/cubit/details/hisn_details_cubit.dart';
import 'package:tarteel/features/hisn_almuslim/cubit/details/hisn_details_state.dart';
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
      create: (_) => HisnDetailsCubit(
        initialCategory: category,
        initialCategoryTitle: categoryTitle ?? category?.title,
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

  void _onCounterTap(BuildContext context) {
    context.read<HisnDetailsCubit>().incrementCounter(
      onNextRequested: () {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && _pageController.hasClients) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        });
      },
    );
  }

  Future<void> _showCategoriesBottomSheet(BuildContext context) async {
    HapticFeedback.lightImpact();
    final cubit = context.read<HisnDetailsCubit>();
    final currentTitle = cubit.state.categoryTitle;

    final actions = await HisnService.loadHisnAsActions();
    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppModalBottomSheet.show(
      context: context,
      title: 'أبواب حصن المسلم',
      subtitle: 'اختر الباب الذي ترغب بالانتقال إليه مباشرة',
      heightFraction: 0.72,
      items: actions.map((item) {
        final isCurrent = item.title == currentTitle;

        return BottomSheetItem(
          title: item.title,
          subtitle: 'باب مأثور',
          isSelected: isCurrent,
          leading: Container(
            width: 40.w,
            height: 40.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.goldAccent.withValues(alpha: 0.2)
                  : (isDark
                        ? Colors.white12
                        : AppColors.primary.withValues(alpha: 0.08)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 20.sp,
              color: isCurrent ? AppColors.goldAccent : AppColors.primary,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            if (!isCurrent) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HisnDetailsScreen(categoryTitle: item.title),
                ),
              );
            }
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<HisnDetailsCubit, HisnDetailsState>(
      listener: (context, state) {
        if (_pageController.hasClients &&
            _pageController.page?.round() != state.currentIndex) {
          _pageController.jumpToPage(state.currentIndex);
        }
      },
      builder: (context, state) {
        if (state.isLoading || state.category == null) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: tarteelAppBar(
              titleText: state.categoryTitle,
              elevation: 0,
              toolbarHeight: 90,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final category = state.category!;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: tarteelAppBar(
            titleText: state.categoryTitle,
            elevation: 0,
            toolbarHeight: 90,
          ),
          body: AnimatedSkyBackground(
            categoryTitle: state.categoryTitle,
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  // Dynamic Section Progress Bar using reusable component & Cubit
                  SectionProgressBar(
                    currentIndex: state.currentIndex,
                    totalCount: category.texts.length,
                    isZeroBasedIndex: true,
                  ),

                  // Page View Container
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: category.texts.length,
                      onPageChanged: (index) {
                        context.read<HisnDetailsCubit>().changePage(index);
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
                            fontSize: state.fontSize,
                            onZoomIn: () =>
                                context.read<HisnDetailsCubit>().zoomIn(),
                            onZoomOut: () =>
                                context.read<HisnDetailsCubit>().zoomOut(),
                            showFavorite: true,
                            favoriteType: 'hisn',
                            favoriteTitle: state.categoryTitle,
                            description: footnote,
                            showCounterBadge: false,
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 60.h),
                  InteractiveCounterControl(
                    count: state.currentCount,
                    totalRepeat: state.totalRepeat,
                    progress: state.currentProgress,
                    onCounterTap: () => _onCounterTap(context),
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
                    onNext: () {
                      if (_pageController.hasClients) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    onPrevious: () {
                      if (_pageController.hasClients) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    hasNext: state.currentIndex < category.texts.length - 1,
                    hasPrevious: state.currentIndex > 0,
                    showResetButton: true,
                    onReset: () async {
                      await context.read<HisnDetailsCubit>().resetCategory();
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(0);
                      }
                    },
                    resetConfirmTitle: 'إعادة تعيين الأدعية',
                    resetConfirmMessage:
                        'هل تريد إعادة تعيين عداد القراءة لكافة الأدعية في هذا القسم والبدء من جديد؟',
                    resetConfirmActionText: 'نعم، تصفير',
                    resetColor: Colors.redAccent,
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
