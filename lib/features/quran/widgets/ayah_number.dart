import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

class AyahNumber extends StatelessWidget {
  final int number;
  final double fontSize;

  const AyahNumber({super.key, required this.number, this.fontSize = 20.0});

  @override
  Widget build(BuildContext context) {
    // 20.0 is the base font size
    final scale = fontSize / 20.0;
    // الحجم المتناسق مع ارتفاع السطر في المصاحف المطبوعة
    final badgeDimension = (28.0 * scale).w;

    return Container(
      width: badgeDimension,
      height: badgeDimension,
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(horizontal: 1.5.w),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/img/verseNumber.png'),
          fit: BoxFit.contain,
        ),
      ),
      child: Text(
        '$number',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: const Color.fromARGB(255, 254, 255, 255),
          fontSize: (9.5 * scale).sp,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
