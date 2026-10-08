import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/services/stats_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';

class QuranReadingController {
  static const String savedAyahsKey = 'saved_quran_ayahs';
  static const String readingModeKey = 'quran_reading_mode'; // 'list' or 'page'

  static Future<String> getReadingMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(readingModeKey) ?? 'page';
  }

  static Future<void> setReadingMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(readingModeKey, mode);
  }

  static List<List<QuranAyah>> splitIntoPages(List<QuranAyah> ayahs) {
    if (ayahs.isEmpty) return [[]];

    final pages = <List<QuranAyah>>[];
    var currentPage = <QuranAyah>[];
    int currentWords = 0;

    for (final ayah in ayahs) {
      final wordsCount = ayah.text.trim().split(RegExp(r'\s+')).length;
      final isFirstPage = pages.isEmpty;
      // 50 words for Page 1 (due to Basmala space), 75 words for subsequent pages
      final maxWordsForPage = isFirstPage ? 50 : 75;

      if (currentPage.isNotEmpty &&
          (currentWords + wordsCount > maxWordsForPage)) {
        pages.add(currentPage);
        currentPage = <QuranAyah>[ayah];
        currentWords = wordsCount;
      } else {
        currentPage.add(ayah);
        currentWords += wordsCount;
      }
    }

    if (currentPage.isNotEmpty) {
      pages.add(currentPage);
    }

    return pages;
  }

  static Future<void> saveRecentAction({
    required QuranSurah surah,
    required int currentPage,
    required int? initialAyah,
    required bool isKhatmaSession,
  }) async {
    if (isKhatmaSession) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quran_page_${surah.number}', currentPage);
      await prefs.setInt('quran_last_read_surah_number', surah.number);

      final currentAyah = initialAyah ?? 1;
      await prefs.setInt('quran_bookmark_surah', surah.number);
      await prefs.setInt('quran_bookmark_ayah', currentAyah);
      await prefs.setInt('quran_ayah_${surah.number}', currentAyah);

      await RecentActionsManager.addAction(
        category: 'quran',
        title: 'سورة ${surah.nameArabic}',
        subtitle: initialAyah != null
            ? 'الآية $initialAyah'
            : 'قراءة السورة',
        extraData: {
          'surah_number': surah.number,
          'ayah_number': currentAyah,
        },
      );
    } catch (_) {}
  }

  static void saveTopVisibleAyah({
    required QuranSurah surah,
    required List<QuranAyah> ayahs,
    required Map<int, GlobalKey> ayahKeys,
    required bool isKhatmaSession,
  }) async {
    if (isKhatmaSession) return;
    try {
      int? topmostAyah;
      double minDiff = double.infinity;

      for (final ayah in ayahs) {
        final key = ayahKeys[ayah.verse];
        if (key == null) continue;
        final context = key.currentContext;
        if (context == null) continue;
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) continue;

        final position = box.localToGlobal(Offset.zero);
        final y = position.dy;

        if (y >= 80.h && y < minDiff) {
          minDiff = y;
          topmostAyah = ayah.verse;
        }
      }

      if (topmostAyah != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('quran_bookmark_surah', surah.number);
        await prefs.setInt('quran_bookmark_ayah', topmostAyah);
        await prefs.setInt('quran_last_read_surah_number', surah.number);
        await prefs.setInt('quran_ayah_${surah.number}', topmostAyah);

        await RecentActionsManager.addAction(
          category: 'quran',
          title: 'سورة ${surah.nameArabic}',
          subtitle: 'الآية $topmostAyah',
          extraData: {
            'surah_number': surah.number,
            'ayah_number': topmostAyah,
          },
        );
      }
    } catch (_) {}
  }

  static Future<bool> updateKhatmaBookmark({
    required BuildContext context,
    required QuranAyah ayah,
  }) async {
    Navigator.pop(context); // close sheet

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('khatma_last_read_surah', ayah.chapter);
      await prefs.setInt('khatma_last_read_ayah', ayah.verse);

      final absoluteAyah = await QuranService.getAbsoluteAyahOffset(
        ayah.chapter,
        ayah.verse,
      );
      final prevMaxReached = prefs.getInt('khatma_max_reached_ayah') ?? 0;
      final previousTotalRead = prefs.getInt('khatma_ayahs_read') ?? 0;

      if (absoluteAyah > prevMaxReached) {
        final difference = absoluteAyah - prevMaxReached;
        await prefs.setInt('khatma_max_reached_ayah', absoluteAyah);

        final newTotalRead = (previousTotalRead + difference).clamp(0, 6236);
        await prefs.setInt('khatma_ayahs_read', newTotalRead);

        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month}-${now.day}';
        var readToday = prefs.getInt('khatma_ayahs_read_today') ?? 0;
        final lastReadStr = prefs.getString('khatma_last_read_date');
        if (lastReadStr != null) {
          final lastReadDate = DateTime.parse(lastReadStr);
          final lastReadDayStr =
              '${lastReadDate.year}-${lastReadDate.month}-${lastReadDate.day}';
          if (todayStr != lastReadDayStr) {
            readToday = 0;
          }
        }

        final newReadToday = readToday + difference;
        await prefs.setInt('khatma_ayahs_read_today', newReadToday);
        await prefs.setString('khatma_last_read_date', now.toIso8601String());

        await StatsService.recordAction('quran', amount: difference);

        if (newTotalRead >= 6236) {
          await StatsService.incrementCompletedKhatmas();
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث موضع الختمة إلى آية ${ayah.verse} بنجاح'),
          ),
        );
      }
      return true;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء حفظ موضع الختمة')),
        );
      }
      return false;
    }
  }

  static Future<void> copyAyah({
    required BuildContext context,
    required QuranSurah surah,
    required QuranAyah ayah,
  }) async {
    await Clipboard.setData(
      ClipboardData(
        text: 'سورة ${surah.nameArabic} - الآية ${ayah.verse}\n\n${ayah.text}',
      ),
    );

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ الآية')));
  }

  static Future<void> saveAyahToFavorites({
    required BuildContext context,
    required QuranSurah surah,
    required QuranAyah ayah,
    required String interpretation,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(savedAyahsKey) ?? [];
    final key = '${ayah.chapter}:${ayah.verse}';

    final alreadySaved = saved.any((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      return decoded['key'] == key;
    });

    if (!alreadySaved) {
      saved.add(
        jsonEncode({
          'key': key,
          'surahNumber': ayah.chapter,
          'surahName': surah.nameArabic,
          'ayahNumber': ayah.verse,
          'ayahText': ayah.text,
          'interpretation': interpretation,
          'savedAt': DateTime.now().toIso8601String(),
        }),
      );
      await prefs.setStringList(savedAyahsKey, saved);
    }

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(alreadySaved ? 'الآية محفوظة سابقاً' : 'تم حفظ الآية'),
      ),
    );
  }

  static Future<bool> showKhatmaExitWarning(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor:
                isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'تحديث الختمة',
              style: TextStyle(
                
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            content: Text(
              'لقد تقدمت في القراءة دون تحديث موضع الختمة. هل تود الخروج دون تحديث الموضع؟',
              style: TextStyle( fontSize: 14.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'الخروج بدون تحديث',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'العودة للتحديث',
                  style: TextStyle(
                    color: Colors.white,
                    
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }
}
