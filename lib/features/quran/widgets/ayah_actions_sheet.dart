import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';

class AyahActionsSheet extends StatelessWidget {
  const AyahActionsSheet({
    super.key,
    required this.surah,
    required this.ayah,
    required this.interpretation,
    required this.isKhatmaSession,
    required this.onInterpretation,
    required this.onCopy,
    required this.onSave,
    this.onUpdateKhatma,
  });

  final QuranSurah surah;
  final QuranAyah ayah;
  final String interpretation;
  final bool isKhatmaSession;
  final VoidCallback onInterpretation;
  final VoidCallback onCopy;
  final VoidCallback onSave;
  final VoidCallback? onUpdateKhatma;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 100.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44.w,
              height: 10.h,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'سورة ${surah.nameArabic} - الآية ${ayah.verse}',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A6B58),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            ayah.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16.sp,
              height: 1.7,
              color: const Color(0xFF1A1710),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _SheetActionButton(
                  icon: Icons.menu_book_outlined,
                  label: 'تفسير الآية',
                  onTap: onInterpretation,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _SheetActionButton(
                  icon: Icons.copy,
                  label: 'نسخ الآية',
                  onTap: onCopy,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _SheetActionButton(
                  icon: Icons.favorite_border,
                  label: 'المفضلة',
                  onTap: onSave,
                ),
              ),
            ],
          ),
          if (isKhatmaSession) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: onUpdateKhatma,
                icon: const Icon(
                  Icons.bookmark_added_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  'تحديث موضع الختمة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F6),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1A6B58), size: 22.sp),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1710),
                
              ),
            ),
          ],
        ),
      ),
    );
  }
}
