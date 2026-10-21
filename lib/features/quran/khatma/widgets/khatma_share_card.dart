import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import '../models/khatma_badge_model.dart';

class KhatmaShareCardDialog extends StatefulWidget {
  final KhatmaBadgeModel badge;
  final int totalPages;
  final int streakDays;

  const KhatmaShareCardDialog({
    super.key,
    required this.badge,
    this.totalPages = 604,
    this.streakDays = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required KhatmaBadgeModel badge,
    int totalPages = 604,
    int streakDays = 0,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => KhatmaShareCardDialog(
        badge: badge,
        totalPages: totalPages,
        streakDays: streakDays,
      ),
    );
  }

  @override
  State<KhatmaShareCardDialog> createState() => _KhatmaShareCardDialogState();
}

class _KhatmaShareCardDialogState extends State<KhatmaShareCardDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _shareCardImage() async {
    setState(() => _isExporting = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/khatma_${widget.badge.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '${widget.badge.title}\n${widget.badge.description}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تجهيز بطاقة المشاركة')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _saveCardToDevice() async {
    setState(() => _isExporting = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      Directory? saveDir;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          saveDir = downloadDir;
        } else {
          saveDir = await getExternalStorageDirectory();
        }
      } else {
        saveDir = await getApplicationDocumentsDirectory();
      }
      saveDir ??= await getTemporaryDirectory();

      final fileName =
          'tarteel_khatma_${widget.badge.id}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.png';
      final file = File('${saveDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              'تم حفظ بطاقة التهنئة بنجاح في مجلد التنزيلات: $fileName',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ البطاقة في الجهاز')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'yyyy/MM/dd',
    ).format(widget.badge.unlockedAt ?? DateTime.now());

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // RepaintBoundary wrapping the clean certificate card
            RepaintBoundary(
              key: _cardKey,
              child: _buildCertificateCard(formattedDate),
            ),
            SizedBox(height: 18.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _shareCardImage,
                    icon: _isExporting
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.share_rounded, size: 20.sp),
                    label: Text(
                      'مشاركة البطاقة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.badge.style.primaryColor,
                      foregroundColor:
                          widget.badge.style.primaryColor.computeLuminance() >
                              0.5
                          ? const Color(0xFF16201B)
                          : Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _saveCardToDevice,
                    icon: Icon(Icons.download_rounded, size: 20.sp),
                    label: Text(
                      'حفظ كصورة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إغلاق',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Cairo',
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateCard(String formattedDate) {
    final style = widget.badge.style;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 420.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.15,
          colors: style.cardGradient,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: style.primaryColor.withValues(alpha: 0.75),
          width: 2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(color: style.glowColor, blurRadius: 28, spreadRadius: -4),
        ],
      ),
      child: CustomPaint(
        painter: _IslamicCertificateFramePainter(
          primaryColor: style.primaryColor,
          secondaryColor: style.secondaryColor,
        ),
        foregroundPainter: _IslamicWatermarkPainter(color: style.primaryColor),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: style.primaryColor,
                    size: 15.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'تطبيق ترتيل • إنجاز قرآني مبارك',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: style.primaryColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.auto_awesome,
                    color: style.primaryColor,
                    size: 15.sp,
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Tier Badge Pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: style.chipBg,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: style.primaryColor.withValues(alpha: 0.5),
                    width: 0.9.w,
                  ),
                ),
                child: Text(
                  style.tierTitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: style.primaryColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // Central Distinctive Emblem
              _buildMilestoneEmblem(widget.badge),
              SizedBox(height: 14.h),

              // Badge Title
              Text(
                widget.badge.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                  shadows: [Shadow(color: style.glowColor, blurRadius: 10)],
                ),
              ),
              SizedBox(height: 4.h),

              // Subtitle
              Text(
                widget.badge.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.sp,
                  color: style.primaryColor.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12.h),

              // Divider with decorative diamond
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: style.primaryColor.withValues(alpha: 0.35),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Transform.rotate(
                      angle: 0.785398, // 45 degrees
                      child: Container(
                        width: 7.w,
                        height: 7.w,
                        color: style.primaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: style.primaryColor.withValues(alpha: 0.35),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Description
              Text(
                widget.badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.5.sp,
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 14.h),

              // Quranic / Prophetic quote dedicated to this milestone
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: style.primaryColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  style.quote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: style.primaryColor.withValues(alpha: 0.95),
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Footer Stats: Date & Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: style.primaryColor,
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'التاريخ: $formattedDate',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: style.primaryColor,
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'الصفحة: ${widget.badge.targetPage} / ${widget.totalPages}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء الشارة المركزية المميزة هندسياً لكل مرحلة
  Widget _buildMilestoneEmblem(KhatmaBadgeModel badge) {
    final style = badge.style;

    switch (badge.milestoneType) {
      case MilestoneType.quarter:
        // وسام الربع: ميدالية برونزية دائرية فاخرة مرصعة بنقاط محيطية ناعمة
        return Container(
          width: 82.w,
          height: 82.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: style.emblemGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: style.glowColor,
                blurRadius: 18,
                spreadRadius: 3,
              ),
            ],
          ),
          padding: EdgeInsets.all(4.w),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.badgeBg,
              border: Border.all(
                color: style.primaryColor.withValues(alpha: 0.5),
                width: 1.5.w,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(badge.icon, size: 38.sp, color: style.primaryColor),
          ),
        );

      case MilestoneType.half:
        // وسام النصف: نجمة إسلامية مثمنة فضية (Rub El Hizb) من مربعين متداخلين
        return SizedBox(
          width: 82.w,
          height: 82.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // مربع خلفي 1
              Container(
                width: 74.w,
                height: 74.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: style.emblemGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: style.glowColor,
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
              // مربع 2 مائل بـ 45 درجة ليكوّن النجمة الثمانية
              Transform.rotate(
                angle: 0.785398,
                child: Container(
                  width: 74.w,
                  height: 74.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: style.emblemGradient,
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              // النواة الداخلية الفضية الكحلية
              Container(
                width: 54.w,
                height: 54.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.badgeBg,
                  border: Border.all(
                    color: style.primaryColor.withValues(alpha: 0.7),
                    width: 1.5.w,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(badge.icon, size: 32.sp, color: style.primaryColor),
              ),
            ],
          ),
        );

      case MilestoneType.threeQuarters:
        // وسام ثلاثة أرباع: شمسية ذهبية ملكية مشعة (12 ضلع متداخل)
        return SizedBox(
          width: 84.w,
          height: 84.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 74.w,
                height: 74.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: style.emblemGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: style.glowColor,
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              Transform.rotate(
                angle: 0.523599, // 30 degrees
                child: Container(
                  width: 74.w,
                  height: 74.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: style.emblemGradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              Transform.rotate(
                angle: 1.0472, // 60 degrees
                child: Container(
                  width: 74.w,
                  height: 74.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: style.emblemGradient,
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.badgeBg,
                  border: Border.all(color: style.primaryColor, width: 2.w),
                ),
                alignment: Alignment.center,
                child: Icon(badge.icon, size: 30.sp, color: style.primaryColor),
              ),
            ],
          ),
        );

      case MilestoneType.complete:
        // تاج الختمة: تاج وإطار ملكي إمبراطوري ألماسي متلألئ
        return SizedBox(
          width: 86.w,
          height: 86.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 82.w,
                height: 82.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: style.emblemGradient),
                  boxShadow: [
                    BoxShadow(
                      color: style.glowColor,
                      blurRadius: 24,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
              Transform.rotate(
                angle: 0.785398,
                child: Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1.5.w,
                    ),
                  ),
                ),
              ),
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.badgeBg,
                  border: Border.all(color: style.primaryColor, width: 2.2.w),
                ),
                alignment: Alignment.center,
                child: Icon(badge.icon, size: 34.sp, color: style.primaryColor),
              ),
            ],
          ),
        );
    }
  }
}

/// رسام الإطار الإسلامي الزخرفي المنمق لشهادة وبطاقة الوسام
class _IslamicCertificateFramePainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  const _IslamicCertificateFramePainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    const pad = 8.0;
    const corner = 26.0;

    // إطار داخلي رئيسي
    final innerRect = Rect.fromLTWH(
      pad,
      pad,
      size.width - pad * 2,
      size.height - pad * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(8)),
      borderPaint,
    );

    // إطار داخلي ثانوي رقيق
    const innerPad = 13.0;
    final fainterPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.22)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final secondInnerRect = Rect.fromLTWH(
      innerPad,
      innerPad,
      size.width - innerPad * 2,
      size.height - innerPad * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(secondInnerRect, const Radius.circular(6)),
      fainterPaint,
    );

    // الأركان الزخرفية الأربعة
    _drawOrnateCorner(canvas, pad, pad, 1, 1, corner, borderPaint, accentPaint);
    _drawOrnateCorner(
      canvas,
      size.width - pad,
      pad,
      -1,
      1,
      corner,
      borderPaint,
      accentPaint,
    );
    _drawOrnateCorner(
      canvas,
      pad,
      size.height - pad,
      1,
      -1,
      corner,
      borderPaint,
      accentPaint,
    );
    _drawOrnateCorner(
      canvas,
      size.width - pad,
      size.height - pad,
      -1,
      -1,
      corner,
      borderPaint,
      accentPaint,
    );

    // أشكال معينية زخرفية في منتصف الأضلاع الأربعة
    _drawCenterDiamond(canvas, Offset(size.width / 2, pad), accentPaint, 4.5);
    _drawCenterDiamond(
      canvas,
      Offset(size.width / 2, size.height - pad),
      accentPaint,
      4.5,
    );
    _drawCenterDiamond(canvas, Offset(pad, size.height / 2), accentPaint, 3.5);
    _drawCenterDiamond(
      canvas,
      Offset(size.width - pad, size.height / 2),
      accentPaint,
      3.5,
    );
  }

  void _drawOrnateCorner(
    Canvas canvas,
    double x,
    double y,
    double dx,
    double dy,
    double len,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    // قوس الركن مع التحديب الزخرفي الأرابيسك
    final path = Path();
    path.moveTo(x + dx * len, y);
    path.lineTo(x + dx * (len * 0.5), y);
    path.quadraticBezierTo(
      x + dx * (len * 0.4),
      y + dy * (len * 0.4),
      x,
      y + dy * (len * 0.5),
    );
    path.lineTo(x, y + dy * len);
    canvas.drawPath(path, strokePaint);

    // معين الركن الدقيق
    _drawCenterDiamond(canvas, Offset(x + dx * 9, y + dy * 9), fillPaint, 3.0);
  }

  void _drawCenterDiamond(
    Canvas canvas,
    Offset center,
    Paint paint,
    double radius,
  ) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _IslamicCertificateFramePainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.secondaryColor != secondaryColor;
}

/// علامة مائية إسلامية هندسية خافتة في عمق البطاقة لإعطاء طابع الشهادات الملكية
class _IslamicWatermarkPainter extends CustomPainter {
  final Color color;

  const _IslamicWatermarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    const step = 64.0;
    for (double x = 0; x <= size.width + step; x += step) {
      for (double y = 0; y <= size.height + step; y += step) {
        _drawEightPointStar(canvas, Offset(x, y), 16.0, paint);
      }
    }
  }

  void _drawEightPointStar(
    Canvas canvas,
    Offset center,
    double r,
    Paint paint,
  ) {
    final rRect1 = Rect.fromCenter(
      center: center,
      width: r * 1.5,
      height: r * 1.5,
    );
    canvas.drawRect(rRect1, paint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(0.785398); // 45 deg
    final rRect2 = Rect.fromCenter(
      center: Offset.zero,
      width: r * 1.5,
      height: r * 1.5,
    );
    canvas.drawRect(rRect2, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IslamicWatermarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
