/// ==============================================================================
/// 📌 وصف الملف: islamic_quiz_screen.dart
/// ==============================================================================
/// مختبر تصميم "خريطة الرحلة الإيمانية" (Faith Map Journey) لتطبيق ترتيل.
///
/// 🎯 محتويات هذه الشاشة:
/// 1. شريط إحصائيات علوي (النقاط الكلية 💎، بنك الأخطاء 📖، الأوسمة 🏅).
/// 2. شريط نسبة الإنجاز والتقدم في الرحلة.
/// 3. مسار رحلة متعرج ومرن (Zigzag Path) يربط المحطات الإيمانية التاريخية.
/// 4. محطات تفاعلية: مكتملة (بنجوم)، نشطة (بنبض مضيء)، ومقفلة (بأقفال ذهبية).
/// 5. بطاقة منبثقة فاخرة عند النقر على أي محطة مفتوحة لبدء التحدي.
/// ==============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/widgets/bottom_sheets/app_modal_bottom_sheet.dart';
import 'package:tarteel/core/widgets/buttons/app_button.dart';
import 'package:tarteel/core/widgets/grids/access_list_grid.dart';

class IslamicQuizScreen extends StatefulWidget {
  const IslamicQuizScreen({super.key});

  @override
  State<IslamicQuizScreen> createState() => _IslamicQuizScreenState();
}

class _IslamicQuizScreenState extends State<IslamicQuizScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ============================================================================
  // 📦 بيانات تجريبية وهمية متكاملة للمحطات الإيمانية
  // ============================================================================
  final List<Map<String, dynamic>> _stations = [
    {
      'id': 'makkah',
      'title': 'واحة مكة المكرمة',
      'subtitle': 'بداية فجر الإسلام والدعوة المكية',
      'icon': Icons.mosque_rounded,
      'status': 'completed', // completed, active, locked
      'stars': 3,
      'questionsCount': 10,
      'color': const Color(0xFFD4AF37), // ذهبي
    },
    {
      'id': 'hijrah',
      'title': 'درب الهجرة النبوية',
      'subtitle': 'رحلة الغار وصحبة الصديق إلى يثرب',
      'icon': Icons.explore_rounded,
      'status': 'active',
      'stars': 0,
      'questionsCount': 10,
      'color': const Color(0xFF2E7D32), // أخضر زمردي
    },
    {
      'id': 'madinah',
      'title': 'طيبة الطيبة',
      'subtitle': 'بناء المسجد وتأسيس مجتمع الأنصار',
      'icon': Icons.home_work_rounded,
      'status': 'locked',
      'stars': 0,
      'questionsCount': 10,
      'color': Colors.grey,
    },
    {
      'id': 'quran_sciences',
      'title': 'رياض القرآن الكريم',
      'subtitle': 'أسرار السور، أسباب النزول، والإعجاز',
      'icon': Icons.menu_book_rounded,
      'status': 'locked',
      'stars': 0,
      'questionsCount': 12,
      'color': Colors.grey,
    },
    {
      'id': 'fiqh',
      'title': 'معالم الفقه والإيمان',
      'subtitle': 'أركان الإسلام العظام وأحكام الشريعة',
      'icon': Icons.auto_awesome_rounded,
      'status': 'locked',
      'stars': 0,
      'questionsCount': 15,
      'color': Colors.grey,
    },
  ];

  @override
  void initState() {
    super.initState();
    // أنيميشن النبض للمحطة النشطة الحالية
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF091410)
          : const Color(0xFFFAF6EE),
      appBar: tarteelAppBar(
        titleText: 'رحلة المؤمن الإيمانية',
        elevation: 0,
        toolbarHeight: 90,
      ),
      // 🏜️ خلفية الصحراء تمتد لتغطي كامل الصفحة بما فيها أسفل وحول الأزرار
      body: Stack(
        children: [
          // 1. الكثبان الرملية الذهبية في الخلفية ممتدة على كامل الشاشة
          Positioned.fill(
            child: CustomPaint(painter: _DesertDunesPainter(isDark: isDark)),
          ),

          // 2. المحتوى التفاعلي طافٍ بانسيابية فوق رمال الصحراء
          SafeArea(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  // 🌟 أزرار الإحصائيات الدائرية المستقلة
                  _buildIndependentStatsButtons(isDark),

                  // 🌟 خريطة المسار ثلاثية الأبعاد تنطلق من الأسفل للأعلى
                  Expanded(
                    child: ListView.builder(
                      reverse: true, // 🌟 تبدأ الرحلة من الأسفل إلى الأعلى!
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 16.h,
                      ),
                      itemCount: _stations.length,
                      itemBuilder: (context, index) {
                        final station = _stations[index];
                        final isFirstAtBottom = index == 0;
                        final isLastAtTop = index == _stations.length - 1;

                        return _buildDesert3DStationNode(
                          context: context,
                          station: station,
                          index: index,
                          isLastAtTop: isLastAtTop,
                          isFirstAtBottom: isFirstAtBottom,
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 1️⃣ أزرار الإحصائيات الدائرية الزجاجية (أيقونة داخل دائرة + الاسم بخط Amiri)
  // ============================================================================
  Widget _buildIndependentStatsButtons(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 💎 زر النقاط الدائري
          AppButton.circular(
            text: 'النقاط',
            icon: Icons.diamond_rounded,
            iconColor: const Color(0xFFFFB300),
            onPressed: () {
              _showPointsPreview();
            },
          ),

          // 📖 زر بنك الأخطاء الدائري
          AppButton.circular(
            text: 'بنك الأخطاء',
            icon: Icons.auto_stories_rounded,
            iconColor: const Color(0xFFFF7043),
            onPressed: () {
              _showMistakesBankPreview();
            },
          ),

          // 🏅 زر الأوسمة الدائري
          AppButton.circular(
            text: 'الأوسمة',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFD4AF37),
            onPressed: () {
              _showBadgesPreview();
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 3️⃣ منصة المحطة ثلاثية الأبعاد (3D Stepping Stone) + درب القافلة
  // ============================================================================
  Widget _buildDesert3DStationNode({
    required BuildContext context,
    required Map<String, dynamic> station,
    required int index,
    required bool isLastAtTop,
    required bool isFirstAtBottom,
    required bool isDark,
  }) {
    final status = station['status'] as String;
    final isCompleted = status == 'completed';
    final isActive = status == 'active';
    final isLocked = status == 'locked';

    // تموج المسار ثلاثي الأبعاد بين اليمين واليسار لمحاكاة دروب الصحراء
    final alignments = [
      Alignment.centerRight,
      Alignment.center,
      Alignment.centerLeft,
      Alignment.center,
    ];
    final currentAlignment = alignments[index % 4];
    final nextAlignment = alignments[(index + 1) % 4];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // درب القافلة الملتوي الموصل للمحطة التالية للأعلى
        if (!isLastAtTop)
          _build3DDesertPathConnection(
            fromAlignment: currentAlignment,
            toAlignment: nextAlignment,
            isActiveOrCompleted: isCompleted,
            isDark: isDark,
          ),

        // مجسم المنصة ثلاثية الأبعاد للمحطة الحالية
        Align(
          alignment: currentAlignment,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                if (isLocked) {
                  _showLockedMessage(station['title']);
                } else {
                  _showStationDetailsSheet(station, isDark);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // منصة الـ 3D الحجرية / الرملية مع الارتفاع والظلال
                  _build3DPedestal(
                    station,
                    isCompleted,
                    isActive,
                    isLocked,
                    isDark,
                  ),

                  SizedBox(height: 6.h),

                  // لافتة اسم المحطة المصممة كلوح بردي / نقش عريق
                  _buildStationBadge(
                    station['title'],
                    isCompleted,
                    isActive,
                    isLocked,
                    isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // منصة حجرية ثلاثية الأبعاد بارزة كأنها قاعدة مجسمة
  Widget _build3DPedestal(
    Map<String, dynamic> station,
    bool isCompleted,
    bool isActive,
    bool isLocked,
    bool isDark,
  ) {
    // ألوان الطبقات للـ 3D (حافة علوية فاتحة، وجه أوسط، قاعدة سفلية مظلمة لعمق البعد الثالث)
    Color topColor;
    Color bottomColor;
    Color borderColor;

    if (isCompleted) {
      topColor = const Color(0xFFFFD54F);
      bottomColor = const Color(0xFFC49000);
      borderColor = const Color(0xFFFFF176);
    } else if (isActive) {
      topColor = const Color(0xFF2E7D32);
      bottomColor = const Color(0xFF1B5E20);
      borderColor = const Color(0xFF81C784);
    } else {
      topColor = isDark ? const Color(0xFF37474F) : const Color(0xFFCFD8DC);
      bottomColor = isDark ? const Color(0xFF212121) : const Color(0xFF90A4AE);
      borderColor = isDark ? Colors.white12 : Colors.white60;
    }

    Widget pedestalBody = Container(
      width: 58.w,
      height: 58.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topColor, bottomColor],
        ),
        border: Border.all(color: borderColor, width: isActive ? 2.5 : 1.8),
        boxShadow: [
          // ظل البعد الثالث الساقط على الكثبان الرملية
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.3),
            offset: const Offset(0, 6),
            blurRadius: 8,
          ),
          if (isActive)
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 3,
            ),
          if (isCompleted)
            BoxShadow(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // لمعان علوي ثلاثي الأبعاد
          Positioned(
            top: 4.h,
            child: Container(
              width: 32.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: isCompleted || isActive ? 0.35 : 0.15,
                ),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),

          // الأيقونة الداخلية
          Icon(
            isLocked ? Icons.lock_outline_rounded : station['icon'] as IconData,
            size: 24.sp,
            color: isLocked
                ? (isDark ? Colors.grey.shade500 : Colors.blueGrey.shade600)
                : Colors.white,
          ),

          // النجوم الثلاثة عند اكتمال المرحلة
          if (isCompleted)
            Positioned(
              bottom: 3.h,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 9.sp,
                    color: const Color(0xFFFFEA00),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // إذا كانت نشطة، يحيط بها مؤشر رحلة دائري نابض (موقعك الحالي)
    if (isActive) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // حلقة النبض الخارجي
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 72.w,
              height: 72.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                  width: 2.0,
                ),
              ),
            ),
          ),
          pedestalBody,
        ],
      );
    }

    return pedestalBody;
  }

  // لافتة اسم المحطة بتنسيق مضغوط وجميل
  Widget _buildStationBadge(
    String title,
    bool isCompleted,
    bool isActive,
    bool isLocked,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF131D18).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isActive
              ? const Color(0xFF2E7D32)
              : (isCompleted
                    ? const Color(0xFFD4AF37)
                    : Colors.grey.withValues(alpha: 0.25)),
          width: isActive ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive) ...[
            Container(
              width: 6.r,
              height: 6.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2E7D32),
              ),
            ),
            SizedBox(width: 4.w),
          ],
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.sp,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: isLocked
                  ? Colors.grey.shade500
                  : (isActive
                        ? (isDark
                              ? const Color(0xFF81C784)
                              : const Color(0xFF1B5E20))
                        : (isDark ? Colors.white : AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  // درب القافلة المنقط ثلاثي الأبعاد المائل بين المحطات
  Widget _build3DDesertPathConnection({
    required Alignment fromAlignment,
    required Alignment toAlignment,
    required bool isActiveOrCompleted,
    required bool isDark,
  }) {
    return SizedBox(
      height: 44.h,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrailPathPainter(
          fromAlignment: fromAlignment,
          toAlignment: toAlignment,
          isActive: isActiveOrCompleted,
          isDark: isDark,
        ),
      ),
    );
  }

  // ============================================================================
  // 4️⃣ البطاقة المنبثقة الفاخرة عند الضغط على محطة لبدء التحدي
  // ============================================================================
  void _showStationDetailsSheet(Map<String, dynamic> station, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F1B) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مؤشر السحب
              Container(
                width: 48.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 18.h),

              // أيقونة وعنوان المحطة
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  station['icon'] as IconData,
                  size: 40.sp,
                  color: AppColors.goldAccent,
                ),
              ),
              SizedBox(height: 14.h),

              Text(
                station['title'],
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                station['subtitle'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.sp,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              SizedBox(height: 18.h),

              // معلومات التحدي
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildModalInfoPill(
                      Icons.help_outline_rounded,
                      '${station['questionsCount']} أسئلة',
                      'حجم التحدي',
                      isDark,
                    ),
                    _buildModalInfoPill(
                      Icons.diamond_outlined,
                      '+100 نقطة',
                      'المكافأة',
                      isDark,
                    ),
                    _buildModalInfoPill(
                      Icons.star_border_rounded,
                      '3 نجوم',
                      'الهدف',
                      isDark,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // زر بدء التحدي الفخم
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    HapticFeedback.heavyImpact();
                    _showStartChallengeMessage(station['title']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    'ابدأ رحلة المحطة الآن 🚀',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalInfoPill(
    IconData icon,
    String value,
    String label,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.goldAccent),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 10.sp,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // تنبيهات ومعاينات سريعة
  // ============================================================================
  void _showLockedMessage(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'محطة "$title" مقفلة! أكمل المحطة السابقة أولاً لتفتح لك 🔒',
          style: const TextStyle(fontFamily: 'Cairo'),
          textAlign: TextAlign.right,
        ),
        backgroundColor: Colors.grey.shade800,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showStartChallengeMessage(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'أنت الآن جاهز لبدء تحدي $title! في الخطوة القادمة سنربط شاشة الأسئلة 🎯',
          style: const TextStyle(fontFamily: 'Cairo'),
          textAlign: TextAlign.right,
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================================
  // 🏅 عرض نافذة الأوسمة السفلية الفخمة باستخدام AppModalBottomSheet و AccessListGrid
  // ============================================================================
  void _showBadgesPreview() {
    final List<AccessListModel> badgeItems = [
      const AccessListModel(
        id: 'badge_seerah',
        title: 'حافظ السيرة',
        route: '',
        icon: Icons.military_tech_rounded,
      ),
      const AccessListModel(
        id: 'badge_falcon',
        title: 'عين الصقر',
        route: '',
        icon: Icons.visibility_rounded,
      ),
      const AccessListModel(
        id: 'badge_starter',
        title: 'بداية النور',
        route: '',
        icon: Icons.wb_sunny_rounded,
      ),
      const AccessListModel(
        id: 'badge_streak',
        title: 'مداوم على الذكر',
        route: '',
        icon: Icons.local_fire_department_rounded,
      ),
      const AccessListModel(
        id: 'badge_quran',
        title: 'باحث التفسير',
        route: '',
        icon: Icons.auto_stories_rounded,
      ),
      const AccessListModel(
        id: 'badge_master',
        title: 'سفير الإيمان',
        route: '',
        icon: Icons.diamond_rounded,
      ),
    ];

    AppModalBottomSheet.show(
      context: context,
      title: 'لوحة الأوسمة والإنجازات',
      subtitle: 'أوسمتك المستحقة من خلال تقدمك في رحلة التحدي والمسابقات',
      heightFraction: 0.70,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // شبكة الأوسمة المربعة باستخدام المكون الجاهز AccessListGrid
            AccessListGrid(actions: badgeItems),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 📖 عرض نافذة بنك الأخطاء والمراجعة الذكية باستخدام AppModalBottomSheet
  // ============================================================================
  void _showMistakesBankPreview() {
    final List<AccessListModel> mistakeActions = [
      const AccessListModel(
        id: 'review_seerah',
        title: 'غزوة بدر الكبرى',
        route: '',
        icon: Icons.flag_rounded,
      ),
      const AccessListModel(
        id: 'review_quran',
        title: 'أسباب النزول',
        route: '',
        icon: Icons.menu_book_rounded,
      ),
      const AccessListModel(
        id: 'review_fiqh',
        title: 'أحكام التيمم',
        route: '',
        icon: Icons.water_drop_rounded,
      ),
      const AccessListModel(
        id: 'review_hadith',
        title: 'أحاديث النوافل',
        route: '',
        icon: Icons.library_books_rounded,
      ),
    ];

    AppModalBottomSheet.show(
      context: context,
      title: 'بنك المراجعة الذكي (أخطائي)',
      subtitle: 'الأسئلة التي أخطأت فيها محفوظة هنا لتختبر نفسك مجدداً وترسخها',
      heightFraction: 0.65,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          children: [
            AccessListGrid(actions: mistakeActions),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // 💎 عرض نافذة رصيد النقاط والمكافآت
  // ============================================================================
  void _showPointsPreview() {
    final List<AccessListModel> pointRewards = [
      const AccessListModel(
        id: 'reward_5050',
        title: 'حذف إجابتين',
        route: '',
        icon: Icons.filter_2_rounded,
      ),
      const AccessListModel(
        id: 'reward_hint',
        title: 'كشف الدليل',
        route: '',
        icon: Icons.lightbulb_rounded,
      ),
      const AccessListModel(
        id: 'reward_swap',
        title: 'تخطي السؤال',
        route: '',
        icon: Icons.cached_rounded,
      ),
    ];

    AppModalBottomSheet.show(
      context: context,
      title: 'رصيدك الإيماني (1250 نقطة)',
      subtitle: 'يمكنك استخدام نقاطك لشراء وسائل مساعدة إضافية في التحديات',
      heightFraction: 0.60,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          children: [
            AccessListGrid(actions: pointRewards),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 🏜️ رسام الكثبان الرملية الذهبية ومشاعر الصحراء والتاريخ (Desert Dunes Painter)
// ==============================================================================
class _DesertDunesPainter extends CustomPainter {
  final bool isDark;

  const _DesertDunesPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. تدرج سماء الصحراء / ليل الصحراء الصافي
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF091410),
                const Color(0xFF0F1E19),
                const Color(0xFF142921),
              ]
            : [
                const Color(0xFFFAF6EE),
                const Color(0xFFF5EEDB),
                const Color(0xFFEFE4C8),
              ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 2. الكثيب الرملي الأول (في الخلفية الناعمة)
    final dune1Path = Path();
    dune1Path.moveTo(0, h * 0.45);
    dune1Path.quadraticBezierTo(w * 0.35, h * 0.40, w * 0.65, h * 0.48);
    dune1Path.quadraticBezierTo(w * 0.85, h * 0.53, w, h * 0.46);
    dune1Path.lineTo(w, h);
    dune1Path.lineTo(0, h);
    dune1Path.close();

    final dune1Paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF12221B).withValues(alpha: 0.6),
                const Color(0xFF0B1713).withValues(alpha: 0.8),
              ]
            : [
                const Color(0xFFECDDBA).withValues(alpha: 0.5),
                const Color(0xFFDFCC9F).withValues(alpha: 0.7),
              ],
      ).createShader(Rect.fromLTWH(0, h * 0.40, w, h * 0.60));
    canvas.drawPath(dune1Path, dune1Paint);

    // 3. الكثيب الرملي الثاني (تموج صحراوي أوسط)
    final dune2Path = Path();
    dune2Path.moveTo(0, h * 0.68);
    dune2Path.quadraticBezierTo(w * 0.4, h * 0.74, w * 0.75, h * 0.66);
    dune2Path.quadraticBezierTo(w * 0.9, h * 0.62, w, h * 0.65);
    dune2Path.lineTo(w, h);
    dune2Path.lineTo(0, h);
    dune2Path.close();

    final dune2Paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF172D24).withValues(alpha: 0.7),
                const Color(0xFF0F1E18).withValues(alpha: 0.9),
              ]
            : [
                const Color(0xFFDCC896).withValues(alpha: 0.6),
                const Color(0xFFCBB276).withValues(alpha: 0.8),
              ],
      ).createShader(Rect.fromLTWH(0, h * 0.62, w, h * 0.38));
    canvas.drawPath(dune2Path, dune2Paint);

    // 4. نقوش حبيبات الرمل ونجوم ليلية خفيفة
    final starPaint = Paint()
      ..color = isDark
          ? const Color(0xFFD4AF37).withValues(alpha: 0.25)
          : const Color(0xFF8D6E14).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final points = [
      Offset(w * 0.15, h * 0.18),
      Offset(w * 0.82, h * 0.22),
      Offset(w * 0.28, h * 0.35),
      Offset(w * 0.72, h * 0.42),
      Offset(w * 0.10, h * 0.58),
      Offset(w * 0.88, h * 0.72),
      Offset(w * 0.45, h * 0.88),
    ];
    for (final pt in points) {
      canvas.drawCircle(pt, 1.8, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DesertDunesPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ==============================================================================
// 🐪 رسام درب القافلة المتصل والمنحني ثلاثي الأبعاد بين المحطات
// ==============================================================================
class _TrailPathPainter extends CustomPainter {
  final Alignment fromAlignment;
  final Alignment toAlignment;
  final bool isActive;
  final bool isDark;

  const _TrailPathPainter({
    required this.fromAlignment,
    required this.toAlignment,
    required this.isActive,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // حساب إحداثيات البداية والنهاية بناءً على محاذاة كل محطة
    final startX = _alignmentToX(fromAlignment, w);
    final startY = h; // تبدأ من أسفل الرابط (فوق المحطة السابقة)
    final endX = _alignmentToX(toAlignment, w);
    final endY = 0.0; // تنتهي عند أعلى الرابط (تحت المحطة اللاحقة)

    // منحنى بيزيه انسيابي كأثر قوافل الإبل في الرمال
    final path = Path();
    path.moveTo(startX, startY);
    final controlPointX = (startX + endX) / 2;
    final controlPointY = (startY + endY) / 2;
    path.quadraticBezierTo(controlPointX, controlPointY, endX, endY);

    // خط الظل ثلاثي الأبعاد في الرمال (3D Shadow trail)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.3 : 0.08)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final shadowPath = Path();
    shadowPath.moveTo(startX + 1, startY + 2);
    shadowPath.quadraticBezierTo(
      controlPointX + 1,
      controlPointY + 2,
      endX + 1,
      endY + 2,
    );
    canvas.drawPath(shadowPath, shadowPaint);

    // الخط الأساسي المنقط لدرب المسيرة
    final pathPaint = Paint()
      ..color = isActive
          ? const Color(0xFFD4AF37)
          : (isDark
                ? Colors.white.withValues(alpha: 0.18)
                : const Color(0xFFBCAAA4).withValues(alpha: 0.45))
      ..strokeWidth = isActive ? 3.5 : 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // رسم مسار متقطع ناعم (Dashed line)
    _drawDashedPath(canvas, path, pathPaint, dashWidth: 6, dashSpace: 5);
  }

  double _alignmentToX(Alignment alignment, double width) {
    if (alignment == Alignment.centerRight) {
      return width * 0.80;
    } else if (alignment == Alignment.centerLeft) {
      return width * 0.20;
    } else {
      return width * 0.50;
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashWidth,
    required double dashSpace,
  }) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPathPainter oldDelegate) =>
      oldDelegate.fromAlignment != fromAlignment ||
      oldDelegate.toAlignment != toAlignment ||
      oldDelegate.isActive != isActive ||
      oldDelegate.isDark != isDark;
}
