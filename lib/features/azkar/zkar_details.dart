import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/Text/Responsive_text.dart';
import 'dart:math' as math;
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/features/azkar/model/zekr_category.dart';

import 'package:tarteel/core/services/in_app_notification_service.dart';
import 'package:tarteel/core/services/stats_service.dart';

class AzkarDetailsScreen extends StatefulWidget {
  final ZekrCategory category;
  const AzkarDetailsScreen({super.key, required this.category});

  @override
  State<AzkarDetailsScreen> createState() => _AzkarDetailsScreenState();
}

class _AzkarDetailsScreenState extends State<AzkarDetailsScreen>
    with SingleTickerProviderStateMixin {
  double _buttonScale = 1.0;
  int currentZekrIndex = 0;
  bool _hapticEnabled = true;
  double _activeMaxFontSize = 14.0;

  dynamic get currentZekr => widget.category.azkar[currentZekrIndex];
  int get _totalRepeat => int.tryParse(currentZekr.count) ?? 1;
  double get _progress => currentZekr.currentCount / _totalRepeat;

  bool get _isAllAzkarCompleted => widget.category.azkar.every((zekr) {
    final repeat = int.tryParse(zekr.count) ?? 1;
    return zekr.currentCount >= repeat;
  });

  bool get _hasStartedReciting =>
      widget.category.azkar.any((zekr) => zekr.currentCount > 0);

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

      _buttonScale = 0.92;
    });

    if (_hapticEnabled) HapticFeedback.lightImpact();

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {
          _buttonScale = 1.0;
        });
      }
    });
  }

  void _onZoomIn() {
    if (_activeMaxFontSize < 25.0) {
      setState(() {
        _activeMaxFontSize += 2.0;
      });
      if (_hapticEnabled) HapticFeedback.lightImpact();
    }
  }

  void _onZoomOut() {
    if (_activeMaxFontSize > 12.0) {
      setState(() {
        _activeMaxFontSize -= 2.0;
      });
      if (_hapticEnabled) HapticFeedback.lightImpact();
    }
  }

  void _copyZekr() async {
    await Clipboard.setData(ClipboardData(text: currentZekr.content));
    if (_hapticEnabled) HapticFeedback.mediumImpact();
    _showMessage('تم نسخ الذكر بنجاح');
  }

  void _shareZekr() async {
    final text =
        '${currentZekr.content}\n\n'
        'فضل الذكر: ${currentZekr.description.isNotEmpty ? currentZekr.description : "من الأذكار النبوية"}\n'
        'المصدر: ${currentZekr.reference.isNotEmpty ? currentZekr.reference : "حصن المسلم"}\n\n'
        'تمت المشاركة من تطبيق ترتيل الإسلامي';
    await Clipboard.setData(ClipboardData(text: text));
    if (_hapticEnabled) HapticFeedback.mediumImpact();
    _showMessage('تم نسخ نص الذكر والفضل لمشاركته فوراً');
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
    _showMessage('تمت إعادة تعيين العدادات بالكامل 🔄');
  }

  void _showResetCategoryDialog() {
    if (_hapticEnabled) HapticFeedback.vibrate();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: const Text(
          'إعادة تعيين الأذكار',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: const Text(
          'هل تريد إعادة تعيين عداد القراءة لكافة الأذكار في هذا القسم والبدء من جديد؟',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetCategory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: tarteelAppBar(
        titleText: widget.category.title,
        elevation: 0,
        toolbarHeight: 90,

        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, color: Colors.white),
            tooltip: 'إعادة تعيين الأذكار',
            onPressed: _showResetCategoryDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 16.h),
            // Dynamic Progress Indicator at the top of page
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
                        '${currentZekrIndex + 1} / ${widget.category.azkar.length}',
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
                          (currentZekrIndex + 1) / widget.category.azkar.length,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 8.h,
                    ),
                    child: _buildZekrCard(zekr, isDark),
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
                  onPressed: currentZekrIndex < widget.category.azkar.length - 1
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
                    Icons.arrow_forward_ios_rounded,
                    size: 30.sp,
                    color: currentZekrIndex < widget.category.azkar.length - 1
                        ? AppColors.primary
                        : Colors.grey.shade400,
                  ),
                ),
                SizedBox(width: 20.w),
                _buildCounterButton(),
                SizedBox(width: 20.w),
                // زر السابق (يمين الشاشة)
                IconButton(
                  onPressed: currentZekrIndex > 0
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
                    Icons.arrow_back_ios_new_rounded,
                    size: 30.sp,
                    color: currentZekrIndex > 0
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
                    fontSize: 5.sp,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                // style: TextButton.styleFrom(
                //   // backgroundColor: Colors.redAccent.withOpacity(0.1),
                //   // shape: RoundedRectangleBorder(
                //   //   borderRadius: BorderRadius.circular(12.r),
                //   // ),
                // ),
              ),
            },
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildZekrCard(dynamic zekr, bool isDark) {
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
            // Header Row of the card: index and Zoom tools
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
                    'الذكر ${currentZekrIndex + 1}',
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
                    children: [
                      _buildZoomButton(
                        Icons.zoom_in_rounded,
                        _onZoomIn,
                        'تكبير',
                      ),
                      Container(
                        width: 1.w,
                        height: 20.h,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                      _buildZoomButton(
                        Icons.zoom_out_rounded,
                        _onZoomOut,
                        'تصغير',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // SizedBox(height: 16.h),

            // Content scroll area to prevent overflow of long azkar paragraphs!
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    ResponsiveText(
                      content: zekr.content,
                      fontSize: _activeMaxFontSize,
                      maxFontSize: _activeMaxFontSize,
                      minFontSize: 10,
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                      height: 2.8,
                      textAlign: TextAlign.center,
                      maxLines: 10,
                      color: isDark ? Colors.white : const Color(0xFF2E5C2E),
                    ),
                    if (zekr.description.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.goldAccent.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          zekr.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Amiri',
                          ),
                        ),
                      ),
                    ],
                    if (zekr.reference.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Text(
                        'المصدر: ${zekr.reference}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Bottom Actions: Copy, Share, and Repeat Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.copy_rounded,
                  onTap: _copyZekr,
                  color: Colors.blue.shade700,
                ),
                _buildActionButton(
                  icon: Icons.share_rounded,
                  onTap: _shareZekr,
                  color: AppColors.primary,
                ),
                SizedBox(width: 15.w),
                // Repeat Counter Card
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    'التكرار  : ${zekr.currentCount} / $_totalRepeat',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
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

  Widget _buildZoomButton(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          child: Icon(icon, size: 22.sp, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20.sp),
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
                painter: CircularProgressPainter(
                  progress: _progress,
                  strokeWidth: 8.0,
                  backgroundColor: Colors.grey.shade200,
                  progressColor: AppColors.primary,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 22.sp, color: AppColors.primary),
                  SizedBox(height: 6.h),
                  Text(
                    '${currentZekr.currentCount}',
                    style: TextStyle(
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'Cairo',
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

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}
