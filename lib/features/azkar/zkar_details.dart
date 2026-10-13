import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/features/azkar/model/zekr_category.dart';

import 'package:tarteel/core/services/in_app_notification_service.dart';
import 'package:tarteel/core/services/stats_service.dart';
import 'package:tarteel/core/widgets/buttons/interactive_counter_control.dart';
import 'package:tarteel/core/widgets/cards/interactive_content_card.dart';
import 'package:tarteel/core/widgets/bottom_sheets/app_modal_bottom_sheet.dart';
import 'package:tarteel/Routes/AppRoutes.dart';
import 'package:tarteel/core/widgets/backgrounds/animated_sky_background.dart';
import 'package:tarteel/features/azkar/icons/azkar_icons.dart';
import 'package:tarteel/features/azkar/services/azkar_service.dart';
import 'package:tarteel/core/widgets/progress/section_progress_bar.dart';

class AzkarDetailsScreen extends StatefulWidget {
  final ZekrCategory category;
  const AzkarDetailsScreen({super.key, required this.category});

  @override
  State<AzkarDetailsScreen> createState() => _AzkarDetailsScreenState();
}

class _AzkarDetailsScreenState extends State<AzkarDetailsScreen> {
  int currentZekrIndex = 0;
  bool _hapticEnabled = true;
  double _activeMaxFontSize = 16.0;

  dynamic get currentZekr => widget.category.azkar[currentZekrIndex];
  int get _totalRepeat => int.tryParse(currentZekr.count) ?? 1;
  double get _progress => currentZekr.currentCount / _totalRepeat;

  bool get _isAllAzkarCompleted => widget.category.azkar.every((zekr) {
    final repeat = int.tryParse(zekr.count) ?? 1;
    return zekr.currentCount >= repeat;
  });

  // bool get _hasStartedReciting =>
  //     widget.category.azkar.any((zekr) => zekr.currentCount > 0);

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadSavedIndex();

    if (widget.category.title == 'أذكار الصباح') {
      InAppNotificationService.markCompleted('morning_azkar');
    } else if (widget.category.title == 'أذكار المساء') {
      InAppNotificationService.markCompleted('evening_azkar');
    } else if (widget.category.title == 'أذكار النوم') {
      InAppNotificationService.markCompleted('sleep_azkar');
    }
  }

  Future<void> _loadSavedIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hapticEnabled = prefs.getBool('haptic_feedback') ?? true;

      // Load daily counts for each Zekr in this category
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';
      final savedDate = prefs.getString('azkar_date_${widget.category.title}');

      if (savedDate == todayStr) {
        for (int i = 0; i < widget.category.azkar.length; i++) {
          final countVal =
              prefs.getInt('azkar_count_${widget.category.title}_$i') ?? 0;
          widget.category.azkar[i].currentCount = countVal;
        }
      } else {
        await prefs.setString('azkar_date_${widget.category.title}', todayStr);
        for (int i = 0; i < widget.category.azkar.length; i++) {
          widget.category.azkar[i].currentCount = 0;
          await prefs.remove('azkar_count_${widget.category.title}_$i');
        }
      }

      final savedIndex =
          prefs.getInt('zekr_index_${widget.category.title}') ?? 0;

      if (mounted) {
        setState(() {
          if (savedIndex > 0 && savedIndex < widget.category.azkar.length) {
            currentZekrIndex = savedIndex;
          }
        });
      }

      if (savedIndex > 0 && savedIndex < widget.category.azkar.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(savedIndex);
          }
        });
      }
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveRecentAzkarAction();
    });
  }

  Future<void> _saveRecentAzkarAction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'zekr_index_${widget.category.title}',
        currentZekrIndex,
      );
      await RecentActionsManager.addAction(
        category: 'azkar',
        title: widget.category.title,
        subtitle: 'ذكر ${currentZekrIndex + 1}/${widget.category.azkar.length}',
        extraData: {'category_title': widget.category.title},
      );
    } catch (_) {}
  }

  void _onCounterTap() {
    // Record stats
    StatsService.recordAction('azkar');

    setState(() {
      if (currentZekr.currentCount < _totalRepeat) {
        currentZekr.currentCount++;

        // Save today's progress to SharedPreferences for this specific Zekr
        final targetIndex = currentZekrIndex;
        final categoryTitle = widget.category.title;
        final newCount = currentZekr.currentCount;
        SharedPreferences.getInstance()
            .then((prefs) {
              prefs.setInt(
                'azkar_count_${categoryTitle}_$targetIndex',
                newCount,
              );
            })
            .catchError((_) {});

        // When the single zekr count is fully completed!
        if (currentZekr.currentCount == _totalRepeat) {
          StatsService.recordAction('completed_azkar_single');

          if (_isAllAzkarCompleted) {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted) {
                _showCompletionSheet();
              }
            });
          } else if (currentZekrIndex < widget.category.azkar.length - 1) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  currentZekrIndex++;
                });
                _pageController.animateToPage(
                  currentZekrIndex,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            });
          }
        }
      }
    });

    if (_hapticEnabled) HapticFeedback.mediumImpact();
  }

  void _onZoomIn() {
    if (_activeMaxFontSize < 34.0) {
      setState(() {
        _activeMaxFontSize += 2.0;
      });
      if (_hapticEnabled) HapticFeedback.mediumImpact();
    }
  }

  void _onZoomOut() {
    if (_activeMaxFontSize > 14.0) {
      setState(() {
        _activeMaxFontSize -= 2.0;
      });
      if (_hapticEnabled) HapticFeedback.mediumImpact();
    }
  }

  void _resetCategory() {
    setState(() {
      for (var zekr in widget.category.azkar) {
        zekr.currentCount = 0;
      }
      currentZekrIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });

    SharedPreferences.getInstance()
        .then((prefs) async {
          for (int i = 0; i < widget.category.azkar.length; i++) {
            await prefs.remove('azkar_count_${widget.category.title}_$i');
          }
        })
        .catchError((_) {});

    _saveRecentAzkarAction();
    _showMessage('تمت إعادة تعيين العدادات بالكامل');
  }

  Future<void> _showCategoriesBottomSheet() async {
    HapticFeedback.lightImpact();
    final categories = await AzkarService.loadAzkar();
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppModalBottomSheet.show(
      context: context,
      title: 'أقسام الأذكار',
      subtitle: 'اختر القسم الذي ترغب بالانتقال إليه مباشرة',
      heightFraction: 0.72,
      items: categories.map((cat) {
        final isCurrent =
            cat.id == widget.category.id || cat.title == widget.category.title;
        final icon = AzkarIcons.icons[cat.title] ?? Icons.menu_book_rounded;

        return BottomSheetItem(
          title: cat.title,
          subtitle: '${cat.azkar.length} ذكر مأثور',
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
                  builder: (_) => AzkarDetailsScreen(category: cat),
                ),
              );
            }
          },
        );
      }).toList(),
    );
  }

  void _showCompletionSheet() {
    // Record completion of the entire Azkar category!
    StatsService.recordAction('completed_azkar_category');

    if (_hapticEnabled) HapticFeedback.vibrate();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => Container(
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
              'لقد أتممت قراءة كافة أذكار ${widget.category.title} بنجاح.',
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
                      _resetCategory();
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

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: tarteelAppBar(
        titleText: widget.category.title,
        elevation: 0,
        toolbarHeight: 90,
      ),
      body: AnimatedSkyBackground(
        categoryTitle: widget.category.title,
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 16.h),
              // Dynamic Section Progress Bar using reusable component & Cubit
              SectionProgressBar(
                currentIndex: currentZekrIndex,
                totalCount: widget.category.azkar.length,
                isZeroBasedIndex: true,
              ),
              // SizedBox(height: 16.h),

              // Page View Container
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.category.azkar.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentZekrIndex = index;
                    });
                    _saveRecentAzkarAction();
                  },
                  itemBuilder: (context, index) {
                    final zekr = widget.category.azkar[index];
                    return AnimatedPadding(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.only(
                        left: 20.w,
                        right: 20.w,
                        top: 20.h,
                        // bottom: 10.h,
                      ),
                      child: _buildZekrCard(zekr),
                    );
                  },
                ),
              ),
              SizedBox(height: 60.h),

              // SizedBox(height: 20.h),
              InteractiveCounterControl(
                count: currentZekr.currentCount,
                totalRepeat: _totalRepeat,
                progress: _progress,
                onCounterTap: _onCounterTap,
                cornerAction: CounterSideAction(
                  icon: Icons.format_list_bulleted_rounded,
                  tooltip: 'أقسام الأذكار',
                  onTap: _showCategoriesBottomSheet,
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
                hasNext: currentZekrIndex < widget.category.azkar.length - 1,
                hasPrevious: currentZekrIndex > 0,
                // showResetButton: _hasStartedReciting,
                onReset: _resetCategory,
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
  }

  Widget _buildZekrCard(dynamic zekr) {
    return InteractiveContentCard(
      content: zekr.content,
      indexLabel: 'الذكر ${currentZekrIndex + 1}',
      fontSize: _activeMaxFontSize,
      onZoomIn: _onZoomIn,
      onZoomOut: _onZoomOut,
      showFavorite: true,
      favoriteType: 'azkar',
      favoriteTitle: widget.category.title,
      description: zekr.description,
      reference: zekr.reference,
      counterBadgeText: 'التكرار  : ${zekr.currentCount} / $_totalRepeat',
    );
  }
}
