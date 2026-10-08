import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import '../../models/ayah_model.dart';
import 'ayah_number.dart';

class AyahWidget extends StatelessWidget {
  final AyahModel ayah;
  final VoidCallback onTap;

  const AyahWidget({super.key, required this.ayah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            children: [
              TextSpan(
                text: "${ayah.text} ",
                style: TextStyle(
                  fontSize: 20.sp,
                  height: 2.h,
                  color: Colors.black,
                  fontFamily: 'Amiri', // مهم
                ),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: AyahNumber(number: ayah.number),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
