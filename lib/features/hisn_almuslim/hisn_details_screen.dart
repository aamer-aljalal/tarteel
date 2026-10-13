import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/cards/interactive_content_card.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/features/hisn_almuslim/model/hisn_category.dart';
import 'package:tarteel/core/services/stats_service.dart';
import 'package:tarteel/core/widgets/buttons/interactive_counter_control.dart';
import 'package:tarteel/core/widgets/bottom_sheets/app_modal_bottom_sheet.dart';
import 'package:tarteel/Routes/AppRoutes.dart';
import 'package:tarteel/features/hisn_almuslim/services/hisn_service.dart';
import 'package:tarteel/core/widgets/backgrounds/animated_sky_background.dart';
import 'package:tarteel/core/widgets/progress/section_progress_bar.dart';

class HisnDetailsScreen extends StatefulWidget {
  final HisnCategory category;
  const HisnDetailsScreen({super.key, required this.category});

  @override
  State<HisnDetailsScreen> createState() => _HisnDetailsScreenState();
}

class _HisnDetailsScreenState extends State<HisnDetailsScreen> {
  int currentHisnIndex = 0;
  bool _hapticEnabled = true;
  double _activeMaxFontSize = 18.0;

  // Since Hisn has no built-in target counts, we default to 1, or let it increment infinitely.
  // We'll maintain a list of current counts here:
  late List<int> _counters;

  String get currentText => widget.category.texts[currentHisnIndex];

  // We can assume a target of 1 for the progress ring to look full after 1 tap.
  int get _totalRepeat => 1;
  double get _progress =>
      (_counters[currentHisnIndex] / _totalRepeat).clamp(0.0, 1.0);

  bool get _isAllCompleted => _counters.every((count) => count >= _totalRepeat);

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _counters = List.filled(widget.category.texts.length, 0);
    _pageController = PageController();
    _loadSavedIndex();
  }

  Future<void> _loadSavedIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hapticEnabled = prefs.getBool('haptic_feedback') ?? true;

      // Load daily counts for each Hisn in this category
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';
      final savedDate = prefs.getString('hisn_date_${widget.category.title}');

      if (savedDate == todayStr) {
        for (int i = 0; i < widget.category.texts.length; i++) {
          final countVal =
              prefs.getInt('hisn_count_${widget.category.title}_$i') ?? 0;
          _counters[i] = countVal;
        }
      } else {
        await prefs.setString('hisn_date_${widget.category.title}', todayStr);
        for (int i = 0; i < widget.category.texts.length; i++) {
          _counters[i] = 0;
          await prefs.remove('hisn_count_${widget.category.title}_$i');
        }
      }

      final savedIndex =
          prefs.getInt('hisn_index_${widget.category.title}') ?? 0;

      if (mounted) {
        setState(() {
          if (savedIndex > 0 && savedIndex < widget.category.texts.length) {
            currentHisnIndex = savedIndex;
          }
        });
      }

      if (savedIndex > 0 && savedIndex < widget.category.texts.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(savedIndex);
          }
        });
      }
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveRecentAction();
    });
  }

  Future<void> _saveRecentAction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'hisn_index_${widget.category.title}',
        currentHisnIndex,
      );
      await RecentActionsManager.addAction(
        category: 'hisn',
        title: widget.category.title,
        subtitle: 'الدعاء ${currentHisnIndex + 1}',
        extraData: {
          'category_title': widget.category.title,
          'current_index': currentHisnIndex,
        },
      );
    } catch (_) {}
  }

  void _onCounterTap() async {
    if (_hapticEnabled) {
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _counters[currentHisnIndex]++;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'hisn_count_${widget.category.title}_$currentHisnIndex',
      _counters[currentHisnIndex],
    );

    // Update global stats
    StatsService.recordAction('hisn', amount: 1);

    // Auto navigate if they reached 1 (or more)
    if (_counters[currentHisnIndex] == _totalRepeat) {
      if (_hapticEnabled) {
        Future.delayed(const Duration(milliseconds: 150), () {
          HapticFeedback.heavyImpact();
        });
      }

      if (currentHisnIndex < widget.category.texts.length - 1) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && _pageController.hasClients) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        });
      } else if (_isAllCompleted) {
        // Complete!
      }
    }
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

  Future<void> _resetCategory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < widget.category.texts.length; i++) {
        _counters[i] = 0;
        prefs.remove('hisn_count_${widget.category.title}_$i');
      }
      currentHisnIndex = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    _saveRecentAction();
    _showMessage('تمت إعادة تعيين العدادات بالكامل');
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Cairo'),
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

  Future<void> _showCategoriesBottomSheet() async {
    HapticFeedback.lightImpact();
    final categories = await HisnService.loadHisn();
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppModalBottomSheet.show(
      context: context,
      title: 'أبواب حصن المسلم',
      subtitle: 'اختر الباب الذي ترغب بالانتقال إليه مباشرة',
      heightFraction: 0.72,
      items: categories.map((cat) {
        final isCurrent = cat.title == widget.category.title;
        final icon = HisnService.getHisnIcon(cat.title);

        return BottomSheetItem(
          title: cat.title,
          subtitle: '${cat.texts.length} دعاء وذكر',
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
                  builder: (_) => HisnDetailsScreen(category: cat),
                ),
              );
            }
          },
        );
      }).toList(),
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
                currentIndex: currentHisnIndex,
                totalCount: widget.category.texts.length,
                isZeroBasedIndex: true,
              ),
              // Page View Container
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.category.texts.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentHisnIndex = index;
                    });
                    _saveRecentAction();
                  },
                  itemBuilder: (context, index) {
                    final text = widget.category.texts[index];
                    // Extract footnote if available
                    String? footnote;
                    if (widget.category.footnotes.length > index) {
                      footnote = widget.category.footnotes[index];
                    }

                    return AnimatedPadding(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.only(
                        left: 20.w,
                        right: 20.w,
                        top: 20.h,
                      ),
                      child: _buildHisnCard(text, footnote, index),
                    );
                  },
                ),
              ),

              SizedBox(height: 60.h),
              InteractiveCounterControl(
                count: _counters[currentHisnIndex],
                totalRepeat: _totalRepeat,
                progress: _progress,
                onCounterTap: _onCounterTap,
                cornerAction: CounterSideAction(
                  icon: Icons.format_list_bulleted_rounded,
                  tooltip: 'أبواب حصن المسلم',
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
                hasNext: currentHisnIndex < widget.category.texts.length - 1,
                hasPrevious: currentHisnIndex > 0,
                showResetButton: true,
                onReset: _resetCategory,
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
  }

  Widget _buildHisnCard(String text, String? footnote, int index) {
    return InteractiveContentCard(
      content: text,
      indexLabel: 'الدعاء ${index + 1}',
      fontSize: _activeMaxFontSize,
      onZoomIn: _onZoomIn,
      onZoomOut: _onZoomOut,
      showFavorite: true,
      favoriteType: 'hisn',
      favoriteTitle: widget.category.title,
      description: footnote,
      showCounterBadge: false,
    );
  }
}
