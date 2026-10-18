import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/widgets/ayah_number.dart';
import 'package:tarteel/features/quran/widgets/surah_navigation_card.dart';

class MushafPage extends StatefulWidget {
  const MushafPage({
    super.key,
    required this.surah,
    required this.ayahs,
    required this.isFirstPage,
    required this.isLastPage,
    required this.pageNumber,
    required this.onAyahLongPress,
    required this.nextSurah,
    required this.prevSurah,
    required this.onNavigate,
    required this.pressedAyahNotifier,
    required this.ayahKeys,
    required this.fontSize,
    this.initialAyah,
    this.initialAyahKey,
  });

  final QuranSurah surah;
  final List<QuranAyah> ayahs;
  final bool isFirstPage;
  final bool isLastPage;
  final int pageNumber;
  final ValueChanged<QuranAyah> onAyahLongPress;
  final QuranSurah? nextSurah;
  final QuranSurah? prevSurah;
  final ValueChanged<int> onNavigate;
  final ValueNotifier<QuranAyah?> pressedAyahNotifier;
  final Map<int, GlobalKey> ayahKeys;
  final double fontSize;
  final int? initialAyah;
  final GlobalKey? initialAyahKey;

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  bool get _showBasmala => widget.isFirstPage && widget.surah.number != 9;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context);
    return Stack(
      children: [
        // العمود الأيمن بأبعاده ونسبته الطبيعية
        Positioned(
          right: -98.w,
          top: 6.h,
          bottom: 6.h,
          child: Image.asset(
            'assets/img/quran/side_column.png',
            fit: BoxFit.fitHeight,
          ),
        ),
        // العمود الأيسر بأبعاده ونسبته الطبيعية (معكوس أفقياً)
        Positioned(
          left: -98.w,
          top: 0,
          bottom: 0,
          child: Transform.flip(
            flipX: true,
            child: Image.asset(
              'assets/img/quran/side_column.png',
              fit: BoxFit.fitHeight,
            ),
          ),
        ),
        // محتوى الآيات مع مساحة متناسقة
        Container(
          width: double.infinity,
          color: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 6.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.isFirstPage) ...[
                      if (_showBasmala) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF1E1A12),
                              fontSize: textScale.scale(18.sp),
                              fontWeight: FontWeight.w900,
                              height: 0.9.h,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 25.h),
                    ],
                    ValueListenableBuilder<QuranAyah?>(
                      valueListenable: widget.pressedAyahNotifier,
                      builder: (context, pressedAyah, child) {
                        return RichText(
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.justify,
                          text: TextSpan(
                            style: TextStyle(
                              color: const Color(0xFF1A1710),
                              fontSize: textScale.scale(widget.fontSize.sp),
                              height: 2,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Amiri',
                            ),
                            children: _buildAyahSpans(context, pressedAyah),
                          ),
                        );
                      },
                    ),
                    if (widget.isLastPage &&
                        (widget.prevSurah != null ||
                            widget.nextSurah != null)) ...[
                      SizedBox(height: 32.h),
                      Container(
                        width: 120.w,
                        height: 1.h,
                        color: const Color(0xFF1E1A12).withValues(alpha: 0.15),
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (widget.prevSurah != null)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6.w),
                                child: SurahNavigationCard(
                                  title: 'السورة السابقة',
                                  surahName: widget.prevSurah!.nameArabic,
                                  isNext: false,
                                  onTap: () => widget.onNavigate(
                                    widget.prevSurah!.number,
                                  ),
                                ),
                              ),
                            ),
                          if (widget.nextSurah != null)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6.w),
                                child: SurahNavigationCard(
                                  title: 'السورة التالية',
                                  surahName: widget.nextSurah!.nameArabic,
                                  isNext: true,
                                  onTap: () => widget.onNavigate(
                                    widget.nextSurah!.number,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<InlineSpan> _buildAyahSpans(
    BuildContext context,
    QuranAyah? pressedAyah,
  ) {
    final spans = <InlineSpan>[];
    for (final ayah in widget.ayahs) {
      if (widget.surah.number == 1 && ayah.verse == 1) {
        continue;
      }
      final isPressed =
          pressedAyah?.verse == ayah.verse &&
          pressedAyah?.chapter == ayah.chapter;

      spans.add(
        TextSpan(
          text: '${ayah.text} ',
          style: TextStyle(color: isPressed ? AppColors.goldAccent : null),
          recognizer:
              LongPressGestureRecognizer(
                  duration: const Duration(milliseconds: 800),
                )
                ..onLongPress = () {
                  HapticFeedback.mediumImpact();
                  widget.onAyahLongPress(ayah);
                },
        ),
      );

      final ayahKey = widget.ayahKeys[ayah.verse];

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            key: ayahKey,
            onLongPress: () {
              HapticFeedback.mediumImpact();
              widget.onAyahLongPress(ayah);
            },
            child: AyahNumber(number: ayah.verse, fontSize: widget.fontSize),
          ),
        ),
      );
      spans.add(const TextSpan(text: ' '));
    }
    return spans;
  }
}
