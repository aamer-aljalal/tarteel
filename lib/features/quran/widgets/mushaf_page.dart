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

  ({double fontSize, double lineHeight}) _calculateTypography({
    required double availableWidth,
    required double targetHeight,
    required double baseFontSize,
  }) {
    if (targetHeight <= 100 || availableWidth <= 100 || widget.ayahs.isEmpty) {
      return (fontSize: baseFontSize, lineHeight: 2.0);
    }

    final sampleAyahsText = widget.ayahs
        .where((a) => !(widget.surah.number == 1 && a.verse == 1))
        .map((a) => '${a.text}  ﴿${a.verse}﴾  ')
        .join(' ');

    double measure(double fs, double lh) {
      final tp = TextPainter(
        text: TextSpan(
          text: sampleAyahsText,
          style: TextStyle(
            fontSize: fs,
            height: lh,
            fontFamily: 'Amiri',
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
      );
      tp.layout(maxWidth: availableWidth);
      return tp.height;
    }

    // بحث ثنائي دقيق: من 0.65 إلى 1.45 من حجم الخط الأساسي
    double lowFs = baseFontSize * 0.65;
    double highFs = baseFontSize * 1.45;
    double bestFs = lowFs;
    double bestLh = 1.8;

    for (int i = 0; i < 9; i++) {
      final midFs = (lowFs + highFs) / 2;
      // تباعد مرن ومتناسق مع الخط
      final factor = ((midFs - baseFontSize * 0.65) / (baseFontSize * 0.80))
          .clamp(0.0, 1.0);
      final midLh = 1.90 + (factor * 0.55); // تتراوح بين 1.75 و 2.30
      final h = measure(midFs, midLh);

      if (h <= targetHeight) {
        bestFs = midFs;
        bestLh = midLh;
        lowFs = midFs; // إمكانية التكبير أكثر لملء الصفحة
      } else {
        highFs = midFs; // تخفيض الحجم حتى لا يحدث overflow
      }
    }

    return (fontSize: bestFs, lineHeight: bestLh);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isContinuous = constraints.maxHeight.isInfinite;
        // نترك هامش جانبي ثابت مع مساحة للخطوط الصفراء
        const double sidePadding = -70.0;
        final availableWidth = (constraints.maxWidth - (sidePadding * 0.40))
            .clamp(100.0, double.infinity);
        final availableHeight = constraints.maxHeight;

        double calculatedFontSize = widget.fontSize.sp;
        double calculatedLineHeight = 2.5;

        if (!isContinuous) {
          // حجز ارتفاع كافي لمنع أي تجاوز رأسي أو تداخل مع الشريط السفلي
          double reservedHeight = 45.h;
          if (widget.isFirstPage && _showBasmala) {
            reservedHeight += 44.h;
          }
          if (widget.isLastPage &&
              (widget.prevSurah != null || widget.nextSurah != null)) {
            reservedHeight += 95.h;
          }

          final targetHeight = (availableHeight - reservedHeight).clamp(
            100.0,
            double.infinity,
          );
          final typo = _calculateTypography(
            availableWidth: availableWidth,
            targetHeight: targetHeight,
            baseFontSize: widget.fontSize.sp,
          );
          calculatedFontSize = typo.fontSize;
          calculatedLineHeight = typo.lineHeight;
        }

        final contentWidget = SizedBox(
          width: availableWidth,
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
                          padding: const EdgeInsets.only(
                            top: 4,
                            left: 10,
                            right: 10,
                          ),
                          child: Text(
                            'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF1E1A12),
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              height: 2.5.h,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 12.h),
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
                              fontSize: calculatedFontSize,
                              height: calculatedLineHeight,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Amiri',
                            ),
                            children: _buildAyahSpans(
                              context,
                              pressedAyah,
                              calculatedFontSize,
                            ),
                          ),
                        );
                      },
                    ),
                    if (widget.isLastPage &&
                        (widget.prevSurah != null ||
                            widget.nextSurah != null)) ...[
                      SizedBox(height: 24.h),
                      Container(
                        width: 120.w,
                        height: 1.h,
                        color: const Color(0xFF1E1A12).withValues(alpha: 0.15),
                      ),
                      SizedBox(height: 16.h),
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
        );

        // إطار المصحف المزدوج المتصل بالكامل بدون أي فجوات
        final pageWithBorders = Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFC89933).withValues(alpha: 0.85),
              width: 1.5,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            child: Column(
              children: [
                // محتوى الآيات داخل الإطار
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: contentWidget,
                  ),
                ),
                // رقم الصفحة يظهر كنص أنيق في الأسفل فوق الخط السفلي مباشرة
                Padding(
                  padding: EdgeInsets.only(top: 2.h, bottom: 2.h),
                  child: Text(
                    '${widget.pageNumber}',
                    style: TextStyle(
                      color: const Color(0xFF8A6D2B),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (isContinuous) {
          return Container(
            width: double.infinity,
            color: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: pageWithBorders,
          );
        }

        return Container(
          width: double.infinity,
          height: availableHeight,
          color: Colors.transparent,
          child: pageWithBorders,
        );
      },
    );
  }

  List<InlineSpan> _buildAyahSpans(
    BuildContext context,
    QuranAyah? pressedAyah, [
    double? currentFontSize,
  ]) {
    final effectiveFontSize = currentFontSize ?? widget.fontSize;
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
            child: AyahNumber(number: ayah.verse, fontSize: effectiveFontSize),
          ),
        ),
      );
      spans.add(const TextSpan(text: ' '));
    }
    return spans;
  }
}
