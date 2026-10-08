import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/Text/Responsive_text.dart';
import 'dart:math' as math;
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/features/hisn_almuslim/model/hisn_category.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tarteel/core/services/stats_service.dart';

class HisnDetailsScreen extends StatefulWidget {
  final HisnCategory category;
  const HisnDetailsScreen({super.key, required this.category});

  @override
  State<HisnDetailsScreen> createState() => _HisnDetailsScreenState();
}

class _HisnDetailsScreenState extends State<HisnDetailsScreen>
    with SingleTickerProviderStateMixin {
  double _buttonScale = 1.0;
  int currentHisnIndex = 0;
  bool _hapticEnabled = true;
  double _activeMaxFontSize = 14.0;
  
  // Since Hisn has no built-in target counts, we default to 1, or let it increment infinitely.
  // We'll maintain a list of current counts here:
  late List<int> _counters;

  String get currentText => widget.category.texts[currentHisnIndex];
  
  // We can assume a target of 1 for the progress ring to look full after 1 tap.
  int get _totalRepeat => 1; 
  double get _progress => (_counters[currentHisnIndex] / _totalRepeat).clamp(0.0, 1.0);

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
      _buttonScale = 0.95;
      _counters[currentHisnIndex]++;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'hisn_count_${widget.category.title}_$currentHisnIndex',
      _counters[currentHisnIndex],
    );

    // Update global stats
    StatsService.recordAction('hisn', amount: 1);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _buttonScale = 1.0;
        });
      }
    });

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

  void _showResetCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'إعادة تعيين',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: Text(
            'هل أنت متأكد من تصفير جميع العدادات في ${widget.category.title} والبدء من جديد؟',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _resetCategory();
              },
              child: const Text(
                'نعم، تصفير',
                style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
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
                    child: _buildHisnCard(text, footnote, isDark, index),
                  );
                },
              ),
            ),

            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // زر التالي (يسار الشاشة)
                IconButton(
                  onPressed: currentHisnIndex < widget.category.texts.length - 1
                      ? () {
                          if (_pageController.hasClients) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      : null,
                  icon: Icon(
                    Icons.arrow_forward_ios_rounded, // Right arrow for next in RTL
                    size: 30.sp,
                    color: currentHisnIndex < widget.category.texts.length - 1
                        ? AppColors.primary
                        : Colors.grey.shade400,
                  ),
                ),
                SizedBox(width: 20.w),
                _buildCounterButton(),
                SizedBox(width: 20.w),
                // زر السابق (يمين الشاشة)
                IconButton(
                  onPressed: currentHisnIndex > 0
                      ? () {
                          if (_pageController.hasClients) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      : null,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded, // Left arrow for previous in RTL
                    size: 30.sp,
                    color: currentHisnIndex > 0
                        ? AppColors.primary
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              'اضغط على الزر للتكرار والاحتساب',
              style: TextStyle(
                fontSize: 7.sp,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!_hasStartedReciting) ...[
              SizedBox(height: 46.h),
            ] else ...{
              TextButton.icon(
                onPressed: _showResetCategoryDialog,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.redAccent,
                ),
                label: Text(
                  'بدء من جديد / إعادة تعيين',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            },
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHisnCard(String text, String? footnote, bool isDark, int index) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2621) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.subtleShadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.grey.shade900
              : AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 10, bottom: 10, left: 15.w, right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row of the card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'الدعاء ${index + 1}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                // Zoom Controllers
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: Icon(
                          Icons.zoom_out_rounded,
                          size: 20.sp,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_activeMaxFontSize > 8) _activeMaxFontSize -= 2;
                          });
                        },
                      ),
                      Container(
                        width: 1,
                        height: 16,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: Icon(
                          Icons.zoom_in_rounded,
                          size: 20.sp,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_activeMaxFontSize < 40) _activeMaxFontSize += 2;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Divider(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              height: 1,
            ),
            
            // Text Body
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                    child: Column(
                      children: [
                        ResponsiveText(
                          content: text,
                          maxFontSize: _activeMaxFontSize,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontWeight: FontWeight.w600,
                            height: 2,
                            color: isDark ? Colors.white : const Color(0xFF2E5C2E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (footnote != null && footnote.trim().isNotEmpty) ...[
                          SizedBox(height: 16.h),
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black12 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 14.sp, color: AppColors.goldAccent),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    footnote,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 10.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            Divider(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              height: 1,
            ),
            // Bottom Action Row
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 22.sp,
                    ),
                    color: Colors.blue.shade700,
                    tooltip: 'نسخ النص',
                    onPressed: () => _copyText(text, index),
                  ),
                  SizedBox(width: 16.w),
                  Container(
                    width: 1,
                    height: 24.h,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  SizedBox(width: 16.w),
                  IconButton(
                    icon: Icon(
                      Icons.share_rounded,
                      size: 22.sp,
                    ),
                    color: AppColors.primary,
                    tooltip: 'مشاركة الدعاء',
                    onPressed: () => _shareText(text, index),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterButton() {
    return GestureDetector(
      onTap: _onCounterTap,
      child: AnimatedScale(
        scale: _buttonScale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: 140.w,
          height: 140.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140.w,
                height: 140.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: const Size(140, 140),
                painter: _HisnCircularProgressPainter(
                  progress: _progress,
                  strokeWidth: 8.0,
                  backgroundColor: Colors.grey.shade200,
                  progressColor: AppColors.primary,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _counters[currentHisnIndex].toString(),
                    style: TextStyle(
                      fontSize: 42.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HisnCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _HisnCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - strokeWidth / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HisnCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}
