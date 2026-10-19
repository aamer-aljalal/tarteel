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
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
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
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
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
    final formattedDate = DateFormat('yyyy/MM/dd').format(
      widget.badge.unlockedAt ?? DateTime.now(),
    );

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
                      backgroundColor: const Color(0xFFC5953C),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
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
    const accentGold = Color(0xFFE2B755);
    const deepGreen1 = Color(0xFF07241A);
    const deepGreen2 = Color(0xFF0F3A2E);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 420.w),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.1,
          colors: [deepGreen2, deepGreen1],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: accentGold.withValues(alpha: 0.65),
          width: 2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _IslamicCornerOrnamentPainter(color: accentGold),
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
                    color: accentGold,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'تطبيق ترتيل • إنجاز قرآني مبارك',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: accentGold,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.auto_awesome,
                    color: accentGold,
                    size: 16.sp,
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Central Medal / Badge Frame
              Container(
                width: 76.w,
                height: 76.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE2B755), Color(0xFF8A651E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentGold.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: EdgeInsets.all(3.w),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0A291E),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    widget.badge.icon,
                    size: 38.sp,
                    color: accentGold,
                  ),
                ),
              ),
              SizedBox(height: 16.h),

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
                  color: accentGold.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12.h),

              // Divider with decorative diamond
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: accentGold.withValues(alpha: 0.3),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Transform.rotate(
                      angle: 0.785398, // 45 degrees
                      child: Container(
                        width: 8.w,
                        height: 8.w,
                        color: accentGold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: accentGold.withValues(alpha: 0.3),
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
                  fontSize: 13.sp,
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 14.h),

              // Quranic Hadith quote
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: accentGold.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Text(
                  '« يُقَالُ لِصَاحِبِ الْقُرْآنِ: اقْرَأْ وَارْتَقِ وَرَتِّلْ كَمَا كُنْتَ تُرَتِّلُ فِي الدُّنْيَا، فَإِنَّ مَنْزِلَتَكَ عِنْدَ آخِرِ آيَةٍ تَقْرَؤُهَا »',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13.sp,
                    color: Colors.white70,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
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
                        color: accentGold,
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'التاريخ: $formattedDate',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: accentGold,
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'الصفحة: ${widget.badge.targetPage} / ${widget.totalPages}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          color: Colors.white60,
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
}

/// Custom painter that draws delicate geometric Islamic corners inside the certificate card
class _IslamicCornerOrnamentPainter extends CustomPainter {
  final Color color;

  const _IslamicCornerOrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const cornerSize = 22.0;

    // Top-left corner
    final pathTL = Path()
      ..moveTo(0, cornerSize)
      ..lineTo(cornerSize, cornerSize)
      ..lineTo(cornerSize, 0);
    canvas.drawPath(pathTL, paint);

    // Top-right corner
    final pathTR = Path()
      ..moveTo(size.width, cornerSize)
      ..lineTo(size.width - cornerSize, cornerSize)
      ..lineTo(size.width - cornerSize, 0);
    canvas.drawPath(pathTR, paint);

    // Bottom-left corner
    final pathBL = Path()
      ..moveTo(0, size.height - cornerSize)
      ..lineTo(cornerSize, size.height - cornerSize)
      ..lineTo(cornerSize, size.height);
    canvas.drawPath(pathBL, paint);

    // Bottom-right corner
    final pathBR = Path()
      ..moveTo(size.width, size.height - cornerSize)
      ..lineTo(size.width - cornerSize, size.height - cornerSize)
      ..lineTo(size.width - cornerSize, size.height);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant _IslamicCornerOrnamentPainter oldDelegate) =>
      oldDelegate.color != color;
}
