import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/features/hisn_almuslim/model/hisn_category.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tarteel/core/services/stats_service.dart';

class HisnDetailsScreen extends StatefulWidget {
  final HisnCategory category;
  const HisnDetailsScreen({super.key, required this.category});

  @override
  State<HisnDetailsScreen> createState() => _HisnDetailsScreenState();
}

class _HisnDetailsScreenState extends State<HisnDetailsScreen> {
  double _fontSize = 20.0;
  bool _hapticEnabled = true;
  final Map<int, int> _counters = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _saveRecentAction();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load daily counters for each prayer in this category
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';
      final savedDate = prefs.getString('hisn_date_${widget.category.title}');

      if (savedDate == todayStr) {
        setState(() {
          for (int i = 0; i < widget.category.texts.length; i++) {
            final countVal =
                prefs.getInt('hisn_count_${widget.category.title}_$i') ?? 0;
            if (countVal > 0) {
              _counters[i] = countVal;
            }
          }
        });
      } else {
        await prefs.setString('hisn_date_${widget.category.title}', todayStr);
        for (int i = 0; i < widget.category.texts.length; i++) {
          await prefs.remove('hisn_count_${widget.category.title}_$i');
        }
      }

      setState(() {
        _hapticEnabled = prefs.getBool('haptic_feedback') ?? true;
        _fontSize = prefs.getDouble('hisn_font_size') ?? 20.0;
      });
    } catch (_) {}
  }

  Future<void> _saveFontSize(double size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('hisn_font_size', size);
    } catch (_) {}
  }

  Future<void> _saveRecentAction() async {
    try {
      await RecentActionsManager.addAction(
        category: 'hisn_almuslim',
        title: widget.category.title,
        subtitle: 'حصن المسلم - ${widget.category.texts.length} أدعية',
        extraData: {'category_title': widget.category.title},
      );
    } catch (_) {}
  }

  void _onZoomIn() {
    if (_fontSize < 36.0) {
      setState(() {
        _fontSize += 2.0;
      });
      _saveFontSize(_fontSize);
      if (_hapticEnabled) HapticFeedback.lightImpact();
    }
  }

  void _onZoomOut() {
    if (_fontSize > 16.0) {
      setState(() {
        _fontSize -= 2.0;
      });
      _saveFontSize(_fontSize);
      if (_hapticEnabled) HapticFeedback.lightImpact();
    }
  }

  void _copyText(String text, int index) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (_hapticEnabled) HapticFeedback.mediumImpact();
    _showMessage('تم نسخ الدعاء رقم ${index + 1}');
  }

  void _shareText(String text, int index) async {
    final shareContent =
        '$text\n\n'
        'المصدر: كتاب حصن المسلم - باب "${widget.category.title}"\n'
        'تمت المشاركة من تطبيق ترتيل الإسلامي';

    await SharePlus.instance.share(
      ShareParams(text: shareContent, subject: 'دعاء من حصن المسلم'),
    );
    if (_hapticEnabled) HapticFeedback.mediumImpact();
  }

  void _incrementCounter(int index) {
    setState(() {
      _counters[index] = (_counters[index] ?? 0) + 1;

      // Persist count immediately
      final newCount = _counters[index]!;
      SharedPreferences.getInstance()
          .then((prefs) {
            prefs.setInt(
              'hisn_count_${widget.category.title}_$index',
              newCount,
            );
          })
          .catchError((_) {});
    });

    // Record statistics action
    StatsService.recordAction('hisn_almuslim');

    if (_hapticEnabled) HapticFeedback.lightImpact();
  }

  void _resetCounters() {
    setState(() {
      _counters.clear();
    });

    SharedPreferences.getInstance()
        .then((prefs) async {
          for (int i = 0; i < widget.category.texts.length; i++) {
            await prefs.remove('hisn_count_${widget.category.title}_$i');
          }
        })
        .catchError((_) {});

    if (_hapticEnabled) HapticFeedback.vibrate();
    _showMessage('تمت إعادة تعيين العدادات');
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
          borderRadius: BorderRadius.circular(12.r),
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: tarteelAppBar(
          titleText: widget.category.title,
          titleTextStyle: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
          toolbarHeight: 80,

          actions: [
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded, color: Colors.white),
              tooltip: 'إعادة تعيين العدادات',
              onPressed: _resetCounters,
            ),
          ],
        ),
        body: Column(
          children: [
            // Controls bar (Zoom controls)
            _buildControlsBar(isDark),

            // Scrollable list
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
                itemCount:
                    widget.category.texts.length +
                    (widget.category.footnotes.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  // If it's the last item and footnotes exist, render footnotes card
                  if (index == widget.category.texts.length) {
                    return _buildFootnotesCard(isDark);
                  }

                  final text = widget.category.texts[index];
                  final currentCount = _counters[index] ?? 0;

                  return _buildPrayerCard(index, text, currentCount, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsBar(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2621) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'حجم الخط المقروء: ${_fontSize.toInt()}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              fontFamily: 'Cairo',
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_in_rounded),
                  color: AppColors.primary,
                  onPressed: _onZoomIn,
                  tooltip: 'تكبير الخط',
                ),
                Container(
                  width: 1.w,
                  height: 20.h,
                  color: Colors.grey.shade400,
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_out_rounded),
                  color: AppColors.primary,
                  onPressed: _onZoomOut,
                  tooltip: 'تصغير الخط',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(
    int index,
    String text,
    int currentCount,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2621) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.subtleShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.grey.shade900
              : AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card header
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'الذكر ${index + 1}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),

                // Mini counter indicator
                if (currentCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'قرئ $currentCount مرات',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldAccent,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Main Calligraphy Text
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
                height: 1.85,
                color: isDark ? Colors.white : const Color(0xFF2E5C2E),
              ),
            ),
          ),

          // Divider
          Divider(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
            height: 1,
          ),

          // Card Actions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              children: [
                // Counter Tap Button
                Material(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30.r),
                  child: InkWell(
                    onTap: () => _incrementCounter(index),
                    borderRadius: BorderRadius.circular(30.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fingerprint_rounded,
                            size: 18.sp,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'تكرار: $currentCount',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Copy
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  color: Colors.blue.shade700,
                  tooltip: 'نسخ النص',
                  onPressed: () => _copyText(text, index),
                ),

                // Share
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  color: AppColors.primary,
                  tooltip: 'مشاركة الدعاء',
                  onPressed: () => _shareText(text, index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFootnotesCard(bool isDark) {
    return Container(
      margin: EdgeInsets.only(top: 8.h, bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF19211C)
            : Colors.amber.shade50.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? Colors.grey.shade900
              : AppColors.goldAccent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.goldAccent,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Text(
                  'المصادر والتخريج',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldAccent,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // List of footnotes
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.category.footnotes.length,
              itemBuilder: (context, fIndex) {
                final fn = widget.category.footnotes[fIndex];
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 4.h),
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          fn,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                            height: 1.6,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
