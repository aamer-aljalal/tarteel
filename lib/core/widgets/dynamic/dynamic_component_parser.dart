/// ==============================================================================
///  وصف الملف: dynamic_component_parser.dart
/// ==============================================================================
/// المحرك الذكي لتحليل وبناء ودجات فلاتر ديناميكياً من ملفات JSON (Server-Driven UI).
///
///  فكرة هذا المحرك:
/// - لا يحتاج إلى موديلات مخصصة لكل صفحة جديدة.
/// - يقرأ كتل البناء (Components) المرسلة من جيت هب ويرسمها فوراً:
///   1. "text"    -> نصوص، عناوين، أسئلة، أحاديث.
///   2. "card"    -> بطاقات محتوى فخمة بتصميم ترتيل الإسلامي مع دعم النسخ والمشاركة.
///   3. "button"  -> أزرار تفاعلية (للإجابات في المسابقات، أو الانتقال بين الخطوات).
///   4. "icon"    -> أيقونات وزخارف إسلامية.
///   5. "spacer"  -> مسافات وفواصل بين العناصر.
/// ==============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tarteel/core/theme/app_colors.dart';

class DynamicComponentParser {
  /// الدالة الرئيسية لتحويل خريطة JSON إلى ودجت فلاتر
  static Widget buildComponent({
    required BuildContext context,
    required Map<String, dynamic> json,
    void Function(String action, dynamic value)? onActionTriggered,
  }) {
    final type = (json['type'] as String? ?? 'text').toLowerCase().trim();

    switch (type) {
      //  كتلة النصوص والعناوين
      case 'text':
        return _buildText(context, json);

      //  كتلة البطاقات الإسلامية الفاخرة
      case 'card':
        return _buildCard(context, json);

      //  كتلة الأزرار التفاعلية (أزرار الخيارات والمسابقات والتالي/السابق)
      case 'button':
      case 'option':
        return _buildButton(context, json, onActionTriggered);

      //  كتلة الأيقونات والرموز
      case 'icon':
        return _buildIcon(context, json);

      //  كتلة المسافات والفواصل
      case 'spacer':
        return _buildSpacer(json);

      // افتراضياً: نص تنبيهي
      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================================
  //  بناء النصوص (العناوين، الفقرات، الأسئلة)
  // ============================================================================
  static Widget _buildText(BuildContext context, Map<String, dynamic> json) {
    final text = json['content'] as String? ?? json['text'] as String? ?? '';
    final styleType = (json['style'] as String? ?? 'body').toLowerCase();
    final textAlign = _parseTextAlign(json['align'] as String?);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double fontSize = 14.sp;
    FontWeight fontWeight = FontWeight.normal;
    Color color = isDark ? Colors.white : AppColors.primary;
    String fontFamily = 'Cairo';

    if (styleType == 'title' || styleType == 'question') {
      fontSize = 18.sp;
      fontWeight = FontWeight.bold;
      color = isDark ? Colors.white : AppColors.primary;
    } else if (styleType == 'subtitle' || styleType == 'step') {
      fontSize = 15.sp;
      fontWeight = FontWeight.w600;
      color = AppColors.goldAccent;
    } else if (styleType == 'quran' || styleType == 'hadith') {
      fontSize = 17.sp;
      fontFamily = 'Amiri';
      fontWeight = FontWeight.bold;
      color = isDark ? Colors.white : AppColors.primary;
    } else if (styleType == 'caption') {
      fontSize = 12.sp;
      color = Colors.grey;
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: (json['verticalPadding'] as num? ?? 6).toDouble().h,
      ),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          fontFamily: fontFamily,
          height: 1.6,
        ),
      ),
    );
  }

  // ============================ءذ================================================
  //  بناء البطاقات الإسلامية المريحة مع دعم النسخ والمشاركة
  // ============================================================================
  static Widget _buildCard(BuildContext context, Map<String, dynamic> json) {
    final title = json['title'] as String?;
    final content = json['content'] as String? ?? '';
    final reference = json['reference'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null && title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: AppColors.goldAccent,
              ),
            ),
            SizedBox(height: 8.h),
          ],
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: 'Cairo',
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          if (reference != null && reference.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              reference,
              style: TextStyle(
                fontSize: 11.sp,
                fontFamily: 'Cairo',
                color: Colors.grey,
              ),
            ),
          ],
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.copy_rounded, size: 18.sp, color: Colors.grey),
                tooltip: 'نسخ',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم النسخ بنجاح',
                        textAlign: TextAlign.right,
                      ),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.share_rounded,
                  size: 18.sp,
                  color: Colors.grey,
                ),
                tooltip: 'مشاركة',
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text: '$content\n\n- تمت المشاركة من تطبيق ترتيل',
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  //  بناء الأزرار التفاعلية (إجابات المسابقات، أزرار الإجراءات)
  // ============================================================================
  static Widget _buildButton(
    BuildContext context,
    Map<String, dynamic> json,
    void Function(String action, dynamic value)? onActionTriggered,
  ) {
    final text = json['text'] as String? ?? json['title'] as String? ?? '';
    final action = json['action'] as String? ?? 'click';
    final actionValue = json['value'];
    final isOutlined = json['isOutlined'] as bool? ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: isOutlined
          ? OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onActionTriggered?.call(action, actionValue);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onActionTriggered?.call(action, actionValue);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 2,
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  // ============================================================================
  //  بناء الأيقونات
  // ============================================================================
  static Widget _buildIcon(BuildContext context, Map<String, dynamic> json) {
    final size = (json['size'] as num? ?? 32).toDouble().sp;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Icon(
          Icons.auto_awesome_rounded,
          size: size,
          color: isDark ? AppColors.goldAccent : AppColors.primary,
        ),
      ),
    );
  }

  // ============================================================================
  //  مسافة فاصلة
  // ============================================================================
  static Widget _buildSpacer(Map<String, dynamic> json) {
    final height = (json['height'] as num? ?? 16).toDouble().h;
    return SizedBox(height: height);
  }

  static TextAlign _parseTextAlign(String? align) {
    switch (align?.toLowerCase()) {
      case 'center':
        return TextAlign.center;
      case 'left':
        return TextAlign.left;
      default:
        return TextAlign.right;
    }
  }
}
