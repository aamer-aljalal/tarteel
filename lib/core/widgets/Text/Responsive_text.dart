import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ResponsiveText extends StatelessWidget {
  final String content;
  final double fontSize;
  final double? minFontSize;
  final double? maxFontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final String fontFamily;
  final TextAlign textAlign;
  final int? maxLines;
  final double? height;
  final TextOverflow overflow;
  final FontStyle? fontStyle;
  final TextDecoration? decoration;
  final List<Shadow>? shadows;
  final double? letterSpacing;
  final TextStyle? style; // لتمرير تنسيق كامل وجاهز وتعديله

  const ResponsiveText({
    super.key,
    required this.content,
    this.fontSize = 16,
    this.minFontSize,
    this.maxFontSize,
    this.color,
    this.fontWeight = FontWeight.bold,
    this.fontFamily = 'Amiri',
    this.textAlign = TextAlign.center,
    this.maxLines = 8,
    this.height,
    this.overflow = TextOverflow.ellipsis,
    this.fontStyle,
    this.decoration,
    this.shadows,
    this.letterSpacing,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    // 1. حساب الحجم الأساسي المتجاوب باستخدام ScreenUtil
    final double scaledBaseSize = fontSize.sp;
    
    // خطوة التصغير بـ 1 بكسل وهي الأكثر سلاسة واستقراراً
    const double step = 1.0;
    
    // 2. حساب الحد الأدنى المتجاوب للتصغير وتقريبه لمضاعفات الخطوة لمنع أي استثناءات
    final double rawMinSize = (minFontSize ?? (fontSize * 0.65)).sp;
    final double calculatedMin = (rawMinSize / step).roundToDouble() * step;
    
    // 3. حساب الحد الأقصى المتجاوب للتكبير وتقريبه لمضاعفات الخطوة لمنع أي استثناءات
    final double rawMaxSize = (maxFontSize ?? (fontSize * 1.5)).sp;
    final double calculatedMax = (rawMaxSize / step).roundToDouble() * step;

    // حماية قاطعة: التأكد من أن الحد الأدنى لا يتجاوز الحد الأقصى أبداً لمنع انهيار AutoSizeText
    final double scaledMinSize = calculatedMin <= calculatedMax ? calculatedMin : calculatedMax;
    final double scaledMaxSize = calculatedMax >= calculatedMin ? calculatedMax : calculatedMin;

    // 4. دمج التنسيقات المخصصة مع التنسيق الافتراضي
    final TextStyle baseStyle = style ?? TextStyle(
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
      fontStyle: fontStyle,
      decoration: decoration,
      shadows: shadows,
      letterSpacing: letterSpacing,
      height: height ?? 1.5,
    );

    final TextStyle finalStyle = baseStyle.copyWith(
      fontSize: scaledBaseSize,
      color: color ?? baseStyle.color ?? Theme.of(context).colorScheme.onSurface,
      fontWeight: fontWeight ?? baseStyle.fontWeight,
      fontFamily: fontFamily != 'Amiri' ? fontFamily : (baseStyle.fontFamily ?? fontFamily),
      fontStyle: fontStyle ?? baseStyle.fontStyle,
      decoration: decoration ?? baseStyle.decoration,
      shadows: shadows ?? baseStyle.shadows,
      letterSpacing: letterSpacing ?? baseStyle.letterSpacing,
      height: height ?? baseStyle.height ?? 1.5,
    );

    // إذا لم يتم تحديد حد أقصى للأسطر، نعرض النص كاملاً بدون أي اقتطاع أو إخفاء للكلام
    if (maxLines == null) {
      return Text(
        content,
        textAlign: textAlign,
        softWrap: true,
        style: finalStyle,
      );
    }

    return AutoSizeText(
      content,
      textAlign: textAlign,
      maxLines: maxLines,
      minFontSize: scaledMinSize,
      maxFontSize: scaledMaxSize,
      stepGranularity: step,
      overflow: overflow,
      style: finalStyle,
    );
  }
}
