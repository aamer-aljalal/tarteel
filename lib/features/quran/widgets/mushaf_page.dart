import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/widgets/ayah_number.dart';

class MushafPage extends StatefulWidget {
  const MushafPage({
    super.key,
    required this.surah,
    required this.ayahs,
    required this.isFirstPage,
    required this.isLastPage,
    required this.pageNumber,
    required this.onAyahLongPress,
    required this.pressedAyahNotifier,
    required this.ayahKeys,
    required this.fontSize,
    this.initialAyah,
  });

  final QuranSurah surah;
  final List<QuranAyah> ayahs;
  final bool isFirstPage;
  final bool isLastPage;
  final int pageNumber;
  final ValueChanged<QuranAyah> onAyahLongPress;
  final ValueNotifier<QuranAyah?> pressedAyahNotifier;
  final Map<int, GlobalKey> ayahKeys;
  final double fontSize;
  final int? initialAyah;

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

    // قياس الارتفاع بدقة متناهية مع احتساب الأبعاد الفعلية لـ WidgetSpan الخاص برقم الآية
    double measure(double fs, double lh) {
      final spans = <InlineSpan>[];
      final placeholders = <PlaceholderDimensions>[];
      final scale = fs / 20.0;
      // أبعاد الشارة الحقيقية المتناسقة مع النص (28.0 * scale) مع الهامش الجانبي (3.w)
      final badgeDimension = (28.0 * scale).w;
      final badgeTotalWidth = badgeDimension + 3.w;

      for (final ayah in widget.ayahs) {
        if (widget.surah.number == 1 && ayah.verse == 1) continue;
        spans.add(
          TextSpan(
            text: '${ayah.text}\u00A0', // مسافة غير قابلة للكسر تمنع سقوط رقم الآية وحيداً
            style: TextStyle(
              fontSize: fs,
              height: lh,
              fontFamily: 'Amiri',
              fontWeight: FontWeight.w500,
            ),
          ),
        );
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(width: badgeTotalWidth, height: badgeDimension),
          ),
        );
        placeholders.add(
          PlaceholderDimensions(
            size: Size(badgeTotalWidth, badgeDimension),
            alignment: PlaceholderAlignment.middle,
          ),
        );
        spans.add(const TextSpan(text: ' '));
      }

      final tp = TextPainter(
        text: TextSpan(children: spans),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
      );
      tp.setPlaceholderDimensions(placeholders);
      tp.layout(maxWidth: availableWidth);
      return tp.height;
    }

    // بحث ثنائي دقيق: لا يتجاوز الحدود الطبيعية لخط المصحف
    double lowFs = baseFontSize * 0.75;
    double highFs = baseFontSize * 1.15;
    double bestFs = lowFs;
    double bestLh = 1.95;

    for (int i = 0; i < 10; i++) {
      final midFs = (lowFs + highFs) / 2;
      final factor = ((midFs - lowFs) / (highFs - lowFs)).clamp(0.0, 1.0);
      final midLh = 1.90 + (factor * 0.25); // بين 1.90 و 2.15
      final h = measure(midFs, midLh);

      if (h <= targetHeight) {
        bestFs = midFs;
        bestLh = midLh;
        lowFs = midFs;
      } else {
        highFs = midFs;
      }
    }

    // زيادة تباعد الأسطر بأمان تام فقط إذا كان الارتفاع يسمح بذلك دون أي تجاوز
    double testLh = bestLh;
    for (double step = 0.05; step <= 0.35; step += 0.05) {
      if (measure(bestFs, bestLh + step) <= targetHeight) {
        testLh = bestLh + step;
      } else {
        break;
      }
    }
    bestLh = testLh;

    return (fontSize: bestFs, lineHeight: bestLh);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark
        ? const Color(0xFFFAF7EE)
        : const Color(0xFF1A1710);
    final basmalaColor = isDark
        ? const Color(0xFFFAF7EE)
        : const Color(0xFF1E1A12);
    final pageNumberColor = isDark
        ? const Color(0xFFE2B755)
        : const Color(0xFF8A6D2B);
    final outerBorderColor = isDark
        ? const Color(0xFFE2B755).withValues(alpha: 0.9)
        : const Color(0xFFC89933).withValues(alpha: 0.85);
    final innerBorderColor = isDark
        ? const Color(0xFFD4AF37).withValues(alpha: 0.7)
        : const Color(0xFFD4AF37).withValues(alpha: 0.6);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isContinuous = constraints.maxHeight.isInfinite;
        // المساحة العرضية الدقيقة داخل الإطارين
        final totalHorizontalInset = (4.w + 2.5 + 1.5 + 8.w + 1.0) * 2;
        final availableWidth = (constraints.maxWidth - totalHorizontalInset)
            .clamp(100.0, double.infinity);
        final availableHeight = constraints.maxHeight;

        double calculatedFontSize = widget.fontSize.sp;
        double calculatedLineHeight = 2.0;

        if (!isContinuous) {
          // حجز ارتفاع كافي بدقة يشمل هوامش الإطار الداخلي والخارجي ورقم الصفحة والبسملة
          double reservedHeight = 52.h;
          if (widget.isFirstPage && _showBasmala) {
            reservedHeight += 58.h;
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.center,
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
                              color: basmalaColor,
                              fontSize: 19.sp,
                              fontWeight: FontWeight.w900,
                              height: 2.0.h,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 8.h),
                    ],
                    ValueListenableBuilder<QuranAyah?>(
                      valueListenable: widget.pressedAyahNotifier,
                      builder: (context, pressedAyah, child) {
                        return RichText(
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.justify,
                          text: TextSpan(
                            style: TextStyle(
                              color: textColor,
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
            border: Border.all(color: outerBorderColor, width: 1.5),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: innerBorderColor, width: 1.0),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Column(
              children: [
                // محتوى الآيات محمي دائماً بواسطة FittedBox لمنع أي overflow نهائياً
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: contentWidget,
                    ),
                  ),
                ),
                // رقم الصفحة يظهر كنص أنيق في الأسفل فوق الخط السفلي مباشرة
                Padding(
                  padding: EdgeInsets.only(top: 2.h, bottom: 2.h),
                  child: Text(
                    '${widget.pageNumber}',
                    style: TextStyle(
                      color: pageNumberColor,
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

      // إضافة مسافة غير قابلة للكسر \u00A0 في نهاية نص الآية لربطها بشارة رقم الآية ومنع سقوطها بمفردها
      spans.add(
        TextSpan(
          text: '${ayah.text}\u00A0',
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
