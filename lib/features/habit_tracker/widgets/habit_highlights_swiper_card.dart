import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/views/surah_detail_page.dart';
import '../services/habit_calendar_helper.dart';

/// ==============================================================================
/// بطاقة الأوراد والمناسبات والتنبيهات المستقلة الشفافة (داخل الشريط العلوي)
/// ==============================================================================
class HabitHighlightsSwiperCard extends StatefulWidget {
  final DateTime selectedDate;

  const HabitHighlightsSwiperCard({super.key, required this.selectedDate});

  @override
  State<HabitHighlightsSwiperCard> createState() =>
      _HabitHighlightsSwiperCardState();
}

class _HabitHighlightsSwiperCardState extends State<HabitHighlightsSwiperCard> {
  late final PageController _pageController;
  int _currentIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final isFriday = HabitCalendarHelper.isFriday(widget.selectedDate);
    final fastingReason = HabitCalendarHelper.getFastingReason(
      widget.selectedDate,
    );

    // قائمة البطاقات والأوراد المستقلة عن الصلاة
    final List<Widget> slides = [
      // 1. بطاقة مناسبة اليوم (الجمعة / صيام النوافل والأيام البيض / فضل اليوم)
      _buildSpecialDaySlide(isFriday, fastingReason),

      // 2. بطاقة خطة ختمة المصحف الشريف المستقلة
      _buildKhatmaSlide(),

      // 3. بطاقة المسبحة الإلكترونية والتسبيح الحر
      _buildTasbeehSlide(),

      // 4. بطاقة موسوعة الأذكار وحصن المسلم
      _buildAzkarSlide(),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 104.h,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: slides.length,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return slides[index];
            },
          ),
        ),

        SizedBox(height: 6.h),

        // مؤشر النقاط التفاعلي أسفل البطاقة الشفافة
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (index) {
            final isSelected = index == _currentIndex;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.symmetric(horizontal: 2.5.w),
              width: isSelected ? 16.w : 5.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.goldAccent : Colors.white30,
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCardContainer({
    required IconData icon,
    required String title,
    required String badgeText,
    required String detail,
    required String buttonText,
    required VoidCallback onButtonTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(icon, size: 17.sp, color: AppColors.goldAccent),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (badgeText.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onButtonTap();
                },
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 9.sp,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6.r),
              border: Border(
                right: BorderSide(color: AppColors.goldAccent, width: 2.5.w),
              ),
            ),
            child: Text(
              detail,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialDaySlide(bool isFriday, String? fastingReason) {
    if (isFriday) {
      return _buildCardContainer(
        icon: Icons.auto_stories_rounded,
        title: 'يوم الجمعة المبارك',
        badgeText: 'سنة مؤكدة',
        detail:
            'قراءة سورة الكهف نور ما بين الجمعتين، والإكثار من الصلاة على النبي ﷺ',
        buttonText: 'الكهف',
        onButtonTap: () async {
          try {
            final surahs = await QuranService.loadSurahs();
            final kahf = surahs.firstWhere((s) => s.number == 18);
            final ayahs = await QuranService.loadAyahs(18);
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SurahDetailPage(surah: kahf, ayahs: ayahs),
                ),
              );
            }
          } catch (_) {}
        },
      );
    }

    if (fastingReason != null) {
      return _buildCardContainer(
        icon: Icons.today_rounded,
        title: 'سنة الصيام اليوم',
        badgeText: 'نافلة',
        detail: fastingReason,
        buttonText: 'الأذكار',
        onButtonTap: () {
          Navigator.pushNamed(context, '/azkar-categories');
        },
      );
    }

    return _buildCardContainer(
      icon: Icons.format_quote_rounded,
      title: 'فضل اليوم والمجاهدة',
      badgeText: 'حديث شريف',
      detail:
          'قال رسول الله ﷺ: «أَحَبُّ الأَعْمَالِ إِلَى اللهِ أَدْوَمُهَا وَإِنْ قَلَّ».',
      buttonText: 'الأذكار',
      onButtonTap: () {
        Navigator.pushNamed(context, '/azkar-categories');
      },
    );
  }

  Widget _buildKhatmaSlide() {
    return _buildCardContainer(
      icon: Icons.menu_book_rounded,
      title: 'خطة ختمة القرآن',
      badgeText: 'الورد اليومي',
      detail:
          'متابعة قراءة صفحات وردك اليومي لإتمام ختم كتاب الله المبارك بانتظام.',
      buttonText: 'الختمة',
      onButtonTap: () {
        Navigator.pushNamed(context, '/khatma-planner');
      },
    );
  }

  Widget _buildTasbeehSlide() {
    return _buildCardContainer(
      icon: Icons.all_inclusive_rounded,
      title: 'المسبحة الإلكترونية',
      badgeText: 'تسبيح واستغفار',
      detail:
          'أوراد التسبيح والاستغفار والصلاة على النبي ﷺ طهارة للقلب وبركة للرزق.',
      buttonText: 'المسبحة',
      onButtonTap: () {
        Navigator.pushNamed(context, '/tasbeeh');
      },
    );
  }

  Widget _buildAzkarSlide() {
    return _buildCardContainer(
      icon: Icons.bookmark_outline_rounded,
      title: 'حصن المسلم والأذكار',
      badgeText: 'الأوراد اليومية',
      detail: 'أذكار الصباح والمساء والاستيقاظ والنوم لحفظ المسلم وسكينته.',
      buttonText: 'الأذكار',
      onButtonTap: () {
        Navigator.pushNamed(context, '/azkar-categories');
      },
    );
  }
}
