import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/features/azkar/model/zekr_category.dart';
import 'package:tarteel/core/widgets/buttons/interactive_counter_control.dart';
import 'package:tarteel/core/widgets/cards/interactive_content_card.dart';
import 'package:tarteel/core/widgets/bottom_sheets/app_modal_bottom_sheet.dart';
import 'package:tarteel/Routes/AppRoutes.dart';
import 'package:tarteel/core/widgets/backgrounds/animated_sky_background.dart';
import 'package:tarteel/features/azkar/icons/azkar_icons.dart';
import 'package:tarteel/features/azkar/services/azkar_service.dart';
import 'package:tarteel/core/widgets/progress/section_progress_bar.dart';
import 'package:tarteel/features/azkar/cubit/details/azkar_details_cubit.dart';
import 'package:tarteel/features/azkar/cubit/details/azkar_details_state.dart';

class AzkarDetailsScreen extends StatelessWidget {
  final ZekrCategory? category;
  final String? categoryTitle;

  const AzkarDetailsScreen({super.key, this.category, this.categoryTitle})
    : assert(category != null || categoryTitle != null);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AzkarDetailsCubit(
        initialCategory: category,
        initialCategoryTitle: categoryTitle ?? category?.title,
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

  void _onCounterTap(BuildContext context) {
    final cubit = context.read<AzkarDetailsCubit>();
    cubit.incrementCounter(
      onSingleCompleted: () {
        final state = cubit.state;
        if (state.category != null &&
            state.currentIndex < state.category!.azkar.length - 1) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _pageController.hasClients) {
              final nextIndex = state.currentIndex + 1;
              _pageController.animateToPage(
                nextIndex,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      },
      onAllCompleted: () {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted && context.mounted) {
            _showCompletionSheet(context);
          }
        });
      },
    );
  }

  Future<void> _showCategoriesBottomSheet(BuildContext context) async {
    HapticFeedback.lightImpact();
    final cubit = context.read<AzkarDetailsCubit>();
    final currentTitle = cubit.state.categoryTitle;

    final actions = await AzkarService.loadAzkarAsActions();
    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppModalBottomSheet.show(
      context: context,
      title: 'أقسام الأذكار',
      subtitle: 'اختر القسم الذي ترغب بالانتقال إليه مباشرة',
      heightFraction: 0.72,
      items: actions.map((item) {
        final isCurrent = item.title == currentTitle;
        final icon = AzkarIcons.icons[item.title] ?? Icons.menu_book_rounded;

        return BottomSheetItem(
          title: item.title,
          subtitle: 'قسم مأثور',
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
              icon,
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
                  builder: (_) => AzkarDetailsScreen(categoryTitle: item.title),
                ),
              );
            }
          },
        );
      }).toList(),
    );
  }

  void _showCompletionSheet(BuildContext context) {
    final cubit = context.read<AzkarDetailsCubit>();
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
              'لقد أتممت قراءة كافة أذكار ${cubit.state.categoryTitle} بنجاح.',
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

    return BlocConsumer<AzkarDetailsCubit, AzkarDetailsState>(
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
        final currentZekr = state.currentZekr;

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
                    totalCount: category.azkar.length,
                    isZeroBasedIndex: true,
                  ),

                  // Page View Container
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: category.azkar.length,
                      onPageChanged: (index) {
                        context.read<AzkarDetailsCubit>().changePage(index);
                      },
                      itemBuilder: (context, index) {
                        final zekr = category.azkar[index];
                        return AnimatedPadding(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.only(
                            left: 20.w,
                            right: 20.w,
                            top: 20.h,
                          ),
                          child: InteractiveContentCard(
                            content: zekr.content,
                            indexLabel: 'الذكر ${state.currentIndex + 1}',
                            fontSize: state.fontSize,
                            onZoomIn: () =>
                                context.read<AzkarDetailsCubit>().zoomIn(),
                            onZoomOut: () =>
                                context.read<AzkarDetailsCubit>().zoomOut(),
                            showFavorite: true,
                            favoriteType: 'azkar',
                            favoriteTitle: state.categoryTitle,
                            description: zekr.description,
                            reference: zekr.reference,
                            counterBadgeText:
                                'التكرار  : ${zekr.currentCount} / ${state.totalRepeat}',
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 60.h),

                  InteractiveCounterControl(
                    count: currentZekr?.currentCount ?? 0,
                    totalRepeat: state.totalRepeat,
                    progress: state.currentProgress,
                    onCounterTap: () => _onCounterTap(context),
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
                    hasNext: state.currentIndex < category.azkar.length - 1,
                    hasPrevious: state.currentIndex > 0,
                    onReset: () async {
                      await context.read<AzkarDetailsCubit>().resetCategory();
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(0);
                      }
                    },
                    showResetButton: true,
                    resetConfirmTitle: 'إعادة تعيين الأذكار',
                    resetConfirmMessage:
                        'هل تريد إعادة تعيين عداد القراءة لكافة الأذكار في هذا القسم والبدء من جديد؟',
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
