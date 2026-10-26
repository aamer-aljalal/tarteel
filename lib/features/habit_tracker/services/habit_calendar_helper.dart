import 'package:hijri/hijri_calendar.dart';

/// ==============================================================================
/// مساعد التقويم والمناسبات الدينية لسجل العبادات اليومي
/// ==============================================================================
class HabitCalendarHelper {
  HabitCalendarHelper._();

  /// الأرقام العربية المشرقية للأناقة والجمال البصري
  static String toArabicNumbers(dynamic input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final str = input.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      final digit = int.tryParse(char);
      if (digit != null && digit >= 0 && digit <= 9) {
        buffer.write(arabicDigits[digit]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// تحويل التاريخ إلى صيغة التخزين الثابتة YYYY-MM-DD
  static String formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// اسم اليوم باللغة العربية
  static String getDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الإثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      default:
        return '';
    }
  }

  /// هل التاريخ يوافق يوم الجمعة المبارك؟
  static bool isFriday(DateTime date) {
    return date.weekday == DateTime.friday;
  }

  /// هل التاريخ يوافق يوم الإثنين أو الخميس؟
  static bool isMondayOrThursday(DateTime date) {
    return date.weekday == DateTime.monday || date.weekday == DateTime.thursday;
  }

  /// حساب التقويم الهجري بدقة للتاريخ المعطى
  static HijriCalendar getHijriDate(DateTime date) {
    HijriCalendar.setLocal('ar');
    return HijriCalendar.fromDate(date);
  }

  /// هل التاريخ يوافق الأيام البيض (١٣، ١٤، ١٥ من الشهر الهجري)؟
  static bool isWhiteDays(DateTime date) {
    final hijri = getHijriDate(date);
    return hijri.hDay == 13 || hijri.hDay == 14 || hijri.hDay == 15;
  }

  /// استخراج سبب الصيام إن وجد لهذا اليوم
  static String? getFastingReason(DateTime date) {
    final hijri = getHijriDate(date);

    if (hijri.hDay == 13 || hijri.hDay == 14 || hijri.hDay == 15) {
      final dayStr = toArabicNumbers(hijri.hDay);
      return 'صيام الأيام البيض ($dayStr ${hijri.longMonthName})';
    }

    if (date.weekday == DateTime.monday) {
      return 'سنة صيام يوم الإثنين (تُعرض فيه الأعمال)';
    }

    if (date.weekday == DateTime.thursday) {
      return 'سنة صيام يوم الخميس (تُعرض فيه الأعمال)';
    }

    return null;
  }

  /// التاريخ الهجري منسقاً بأناقة
  static String formatHijri(DateTime date) {
    final hijri = getHijriDate(date);
    final day = toArabicNumbers(hijri.hDay);
    final year = toArabicNumbers(hijri.hYear);
    return '$day ${hijri.longMonthName} $year هـ';
  }

  /// التاريخ الميلادي منسقاً بأناقة
  static String formatGregorian(DateTime date) {
    final day = toArabicNumbers(date.day);
    final monthName = _getArabicMonthName(date.month);
    final year = toArabicNumbers(date.year);
    return '$day $monthName $year م';
  }

  static String _getArabicMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}
