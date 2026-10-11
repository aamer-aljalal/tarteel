import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/cards/interactive_content_card.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/features/hisn_almuslim/model/hisn_category.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tarteel/core/services/stats_service.dart';
import 'package:tarteel/core/widgets/buttons/interactive_counter_control.dart';

class HisnDetailsScreen extends StatefulWidget {
  final HisnCategory category;
  const HisnDetailsScreen({super.key, required this.category});

  @override
  State<HisnDetailsScreen> createState() => _HisnDetailsScreenState();
}

class _HisnDetailsScreenState extends State<HisnDetailsScreen> {
  int currentHisnIndex = 0;
  bool _hapticEnabled = true;
  double _activeMaxFontSize = 14.0;

  // Since Hisn has no built-in target counts, we default to 1, or let it increment infinitely.
  // We'll maintain a list of current counts here:
  late List<int> _counters;

  String get currentText => widget.category.texts[currentHisnIndex];

  // We can assume a target of 1 for the progress ring to look full after 1 tap.
  int get _totalRepeat => 1;
  double get _progress =>
      (_counters[currentHisnIndex] / _totalRepeat).clamp(0.0, 1.0);

  bool get _isAllCompleted => _counters.every((count) => count >= _totalRepeat);

  bool get _hasStartedReciting => _counters.any((count) => count > 0);

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

  Future<void> _showResetCategoryDialog() async {
    final confirmed = await InteractiveCounterControl.showResetConfirmation(
      context,
      title: 'إعادة تعيين',
      message:
          'هل أنت متأكد من تصفير جميع العدادات في ${widget.category.title} والبدء من جديد؟',
      confirmText: 'نعم، تصفير',
      confirmColor: Colors.redAccent,
    );
    if (confirmed) {
      _resetCategory();
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
  }

  void _copyText(String text, int index) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ الدعاء ${index + 1}',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareText(String text, int index) {
    Share.share('$text\n\n- ${widget.category.title}');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: tarteelAppBar(
        titleText: widget.category.title,
        elevation: 0,
        toolbarHeight: 80,
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, color: Colors.white),
            tooltip: 'إعادة تعيين الأدعية',
            onPressed: _showResetCategoryDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            // Dynamic Progress Indicator
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'التقدم في القسم',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldAccent,
                        ),
                      ),
                      Text(
                        '${currentHisnIndex + 1} / ${widget.category.texts.length}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: LinearProgressIndicator(
                      value:
                          (currentHisnIndex + 1) / widget.category.texts.length,
                      minHeight: 6.h,
                      backgroundColor: isDark
                          ? Colors.grey.shade900
                          : AppColors.primary.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

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
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 8.h,
                    ),
                    child: _buildHisnCard(text, footnote, index),
                  );
                },
              ),
            ),

            SizedBox(height: 20.h),
            InteractiveCounterControl(
              count: _counters[currentHisnIndex],
              totalRepeat: _totalRepeat,
              progress: _progress,
              onCounterTap: _onCounterTap,
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
              showResetButton: _hasStartedReciting,
              onReset: _resetCategory,
              resetConfirmTitle: 'إعادة تعيين',
              resetConfirmMessage:
                  'هل أنت متأكد من تصفير جميع العدادات في ${widget.category.title} والبدء من جديد؟',
              resetConfirmActionText: 'نعم، تصفير',
              resetColor: Colors.redAccent,
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHisnCard(String text, String? footnote, int index) {
    return InteractiveContentCard(
      content: text,
      indexLabel: 'الدعاء ${index + 1}',
      fontSize: _activeMaxFontSize,
      onZoomIn: () {
        setState(() {
          if (_activeMaxFontSize < 40) _activeMaxFontSize += 2;
        });
      },
      onZoomOut: () {
        setState(() {
          if (_activeMaxFontSize > 8) _activeMaxFontSize -= 2;
        });
      },
      description: footnote,
      onCopy: () => _copyText(text, index),
      onShare: () => _shareText(text, index),
      showCounterBadge: false,
    );
  }
}
