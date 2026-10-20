import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/services/general_notification_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/widgets/buttons/app_glass_button.dart';
import 'package:tarteel/core/widgets/dialogs/app_confirm_dialog.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/views/surah_detail_page.dart';
import '../models/khatma_plan_model.dart';
import '../models/khatma_badge_model.dart';
import '../models/khatma_history_model.dart';
import '../services/khatma_service.dart';
import '../widgets/khatma_journey_card.dart';
import '../widgets/khatma_plan_selector.dart';
import '../widgets/khatma_share_card.dart';
import '../widgets/khatma_history_sheet.dart';

class KhatmaScreen extends StatefulWidget {
  const KhatmaScreen({super.key});

  @override
  State<KhatmaScreen> createState() => _KhatmaScreenState();
}

class _KhatmaScreenState extends State<KhatmaScreen> {
  bool _isLoading = true;
  KhatmaPlanModel? _activePlan;
  List<KhatmaBadgeModel> _badges = [];
  List<KhatmaHistoryModel> _history = [];
  int _streakDays = 0;
  KhatmaHistoryModel? _previewArchivedKhatma;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final plan = await KhatmaService.getActivePlan();
      final badges = await KhatmaService.getAllBadges();
      final history = await KhatmaService.getHistory();
      final streak = await KhatmaService.getStreakDays();

      if (mounted) {
        setState(() {
          _activePlan = plan;
          _badges = badges;
          _history = history;
          _streakDays = streak;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading Khatma data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleStartPlan({
    required String title,
    required KhatmaPlanType type,
    required int targetPagesPerDay,
    required int targetDays,
    required TimeOfDay reminderTime,
  }) async {
    await KhatmaService.createPlan(
      title: title,
      type: type,
      targetPagesPerDay: targetPagesPerDay,
      targetDays: targetDays,
      reminderTime: reminderTime,
    );
    await _loadData();
  }

  Future<void> _handleChangeReminder() async {
    if (_activePlan == null) return;

    final initialTime = TimeOfDay(
      hour: _activePlan!.reminderHour,
      minute: _activePlan!.reminderMinute,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null && mounted) {
      final updated = _activePlan!.copyWith(
        reminderHour: picked.hour,
        reminderMinute: picked.minute,
      );
      await KhatmaService.saveActivePlan(updated);
      await GeneralNotificationService.scheduleKhatmaReminder(
        picked.hour,
        picked.minute,
      );
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث موعد التذكير بنجاح')),
        );
      }
    }
  }

  Future<void> _handleCancelPlan() async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'إنهاء الخطة الحالية',
      message:
          'هل تود إنهاء الخطة الحالية؟ سيتم حفظ جميع أوسمتك وسجل ختماتك السابقة دون أي فقدان.',
      confirmText: 'إنهاء الخطة',
      cancelText: 'تراجع',
      isDestructive: true,
      icon: Icons.warning_amber_rounded,
    );

    if (confirm) {
      await KhatmaService.cancelCurrentPlan();
      await _loadData();
    }
  }

  Future<void> _navigateToKhatmaReading() async {
    if (_activePlan == null) return;

    final targetPage = _activePlan!.currentPage.clamp(1, 604);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pageAyahs = await QuranService.loadPage(targetPage);
      final surahs = await QuranService.loadSurahs();

      int targetSurahNumber = 1;
      int targetAyahNumber = 1;

      if (pageAyahs.isNotEmpty) {
        targetSurahNumber = pageAyahs.first.chapter;
        targetAyahNumber = pageAyahs.first.verse;
      }

      final surah = surahs.firstWhere(
        (s) => s.number == targetSurahNumber,
        orElse: () => surahs.first,
      );
      final allAyahsInSurah = await QuranService.loadAyahs(targetSurahNumber);

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurahDetailPage(
              surah: surah,
              ayahs: allAyahsInSurah,
              initialAyah: targetAyahNumber,
              isKhatmaSession: true,
            ),
          ),
        );

        // Reload data after reading session
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الانتقال إلى صفحة المصحف')),
        );
      }
    }
  }

  void _showHistorySheet() {
    KhatmaHistorySheet.show(
      context,
      history: _history,
      onSelectKhatma: (item) {
        setState(() {
          _previewArchivedKhatma = item;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const accentGold = Color(0xFFE2B755);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: tarteelAppBar(
          titleText: 'خطة إتمام المصحف',
          actions: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: AppGlassButton(
                width: 38.w,
                height: 38.w,
                isCircle: true,
                tooltip: 'سجل الختمات السابقة',
                onTap: _showHistorySheet,
                child: Icon(
                  Icons.history_edu_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Case 1: Viewing an archived past Khatma
                      if (_previewArchivedKhatma != null) ...[
                        KhatmaJourneyCard(
                          plan: _buildArchivedPreviewPlan(
                            _previewArchivedKhatma!,
                          ),
                          streakDays: _streakDays,
                          isArchivedPreview: true,
                          onContinueReading: () {},
                          onChangeReminder: () {},
                          onCancelPlan: () {},
                        ),
                        SizedBox(height: 14.h),
                        _buildReturnToActiveBar(),
                        SizedBox(height: 14.h),
                      ]
                      // Case 2: Active in-progress Khatma
                      else if (_activePlan != null &&
                          !_activePlan!.isCompleted) ...[
                        KhatmaJourneyCard(
                          plan: _activePlan!,
                          streakDays: _streakDays,
                          onContinueReading: _navigateToKhatmaReading,
                          onChangeReminder: _handleChangeReminder,
                          onCancelPlan: _handleCancelPlan,
                        ),
                        SizedBox(height: 16.h),
                      ]
                      // Case 3: Current Khatma just completed
                      else if (_activePlan != null &&
                          _activePlan!.isCompleted) ...[
                        _buildCompletionCelebrationCard(isDark),
                        SizedBox(height: 16.h),
                      ]
                      // Case 4: No active Khatma, show setup planner
                      else ...[
                        KhatmaPlanSelector(onStartPlan: _handleStartPlan),
                        SizedBox(height: 16.h),
                      ],

                      // History Card Shortcut
                      if (_history.isNotEmpty) ...[
                        _buildHistoryShortcutCard(isDark, accentGold),
                        SizedBox(height: 14.h),
                      ],

                      // Islamic Motivational Quote Card
                      _buildInspirationalCard(isDark, accentGold),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  KhatmaPlanModel _buildArchivedPreviewPlan(KhatmaHistoryModel historyItem) {
    return KhatmaPlanModel(
      id: historyItem.id,
      title: historyItem.title,
      type: historyItem.type,
      targetPagesPerDay:
          (historyItem.totalPages / math.max(1, historyItem.daysTaken)).ceil(),
      targetDays: historyItem.daysTaken,
      startDate: historyItem.startDate,
      completedDate: historyItem.completedDate,
      currentPage: 604,
      pagesReadToday: 0,
      isCompleted: true,
      badges: historyItem.badges.isNotEmpty
          ? historyItem.badges
          : KhatmaBadgeModel.defaultBadges()
                .map(
                  (b) => b.copyWith(
                    isUnlocked: true,
                    unlockedAt: historyItem.completedDate,
                  ),
                )
                .toList(),
    );
  }

  Widget _buildReturnToActiveBar() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _previewArchivedKhatma = null;
          });
        },
        icon: Icon(Icons.arrow_forward_rounded, size: 18.sp),
        label: Text(
          'العودة للختمة الجارية الحالية',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC5953C),
          side: const BorderSide(color: Color(0xFFC5953C), width: 1.2),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryShortcutCard(bool isDark, Color accentGold) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14241E) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: _showHistorySheet,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentGold.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.history_edu_rounded,
                    color: accentGold,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سجل الختمات السابقة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'لديك ${_history.length} ختمات مكتملة محفوظة بأوسمتها وتواريخها',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14.sp,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInspirationalCard(bool isDark, Color accentGold) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111E1A) : const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, color: accentGold, size: 22.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '« اقْرَؤُوا القُرْآنَ فإنَّه يَأْتي يَومَ القِيَامَةِ شَفِيعاً لأَصْحَابِهِ »',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14.sp,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'رواه مسلم عن أبي أمامة الباهلي رضي الله عنه',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10.sp,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCelebrationCard(bool isDark) {
    const accentGold = Color(0xFFE2B755);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1B3D2F), const Color(0xFF0F261D)]
              : [const Color(0xFF1C634F), const Color(0xFF144537)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accentGold, width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: accentGold.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentGold.withValues(alpha: 0.2),
              border: Border.all(color: accentGold, width: 2),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 34.sp,
              color: accentGold,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'هنيئاً لك ختم كتاب الله تعالى',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'الحمد لله الذي بنعمته تتم الصالحات، أتممت قراءة المصحف الشريف كاملاً (604 صفحة). نسأل الله أن يجعله شفيعاً لك ونوراً لقلبك.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final completeBadge = _badges.firstWhere(
                      (b) => b.milestoneType == MilestoneType.complete,
                      orElse: () => _badges.last,
                    );
                    KhatmaShareCardDialog.show(
                      context,
                      badge: completeBadge,
                      totalPages: 604,
                      streakDays: _streakDays,
                    );
                  },
                  icon: Icon(Icons.share_rounded, size: 18.sp),
                  label: Text(
                    'تاج الختمة والشهادة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC5953C),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await KhatmaService.cancelCurrentPlan();
                    await _loadData();
                  },
                  icon: Icon(Icons.refresh_rounded, size: 18.sp),
                  label: Text(
                    'بدء ختمة جديدة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
