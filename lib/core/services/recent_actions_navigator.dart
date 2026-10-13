import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/Routes/AppRoutes.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/features/azkar/services/azkar_service.dart';
import 'package:tarteel/features/prophets_stories/services/prophets_stories_service.dart';
import 'package:tarteel/features/prophets_stories/views/prophet_story_details_screen.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/views/surah_detail_page.dart';

class RecentActionNavigator {
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'quran':
        return Icons.menu_book_rounded;
      case 'azkar':
        return Icons.bookmark_added_rounded;
      case 'hadith':
        return Icons.auto_stories_rounded;
      case 'hisn_almuslim':
        return Icons.shield_outlined;
      case 'names_of_allah':
        return Icons.auto_awesome_rounded;
      case 'prophets_stories':
        return Icons.import_contacts_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  static String getCategoryLabel(String category) {
    switch (category) {
      case 'quran':
        return 'متابعة التلاوة';
      case 'azkar':
        return 'متابعة الأذكار';
      case 'hadith':
        return 'متابعة الحديث';
      case 'hisn_almuslim':
        return 'حصن المسلم';
      case 'prophets_stories':
        return 'قصص الأنبياء';
      case 'names_of_allah':
        return 'أسماء الله الحسنى';
      default:
        return 'آخر نشاط';
    }
  }

  static Future<void> resume(BuildContext context, RecentAction action) async {
    HapticFeedback.lightImpact();
    if (action.category == 'quran') {
      final surahNumber = action.extraData['surah_number'] as int?;
      final ayahNumber = action.extraData['ayah_number'] as int?;
      if (surahNumber != null) {
        await _resumeQuran(context, surahNumber, recentAyahNumber: ayahNumber);
      }
    } else if (action.category == 'azkar') {
      final categoryTitle = action.extraData['category_title'] as String?;
      if (categoryTitle != null) {
        await _resumeAzkar(context, categoryTitle);
      }
    } else if (action.category == 'hisn_almuslim') {
      final categoryTitle = action.extraData['category_title'] as String?;
      if (categoryTitle != null) {
        await _resumeHisn(context, categoryTitle);
      }
    } else if (action.category == 'hadith') {
      final hadithNumber = action.extraData['hadith_number'] as int?;
      if (hadithNumber != null) {
        await _resumeHadith(context, hadithNumber);
      }
    } else if (action.category == 'prophets_stories') {
      final storyId = action.extraData['story_id'] as int?;
      if (storyId != null) {
        await _resumeProphetStory(context, storyId);
      }
    }
  }

  static Future<void> _resumeQuran(
    BuildContext context,
    int surahNumber, {
    int? recentAyahNumber,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();

      int? targetAyah = recentAyahNumber;

      if (targetAyah == null) {
        final bmSurah = prefs.getInt('quran_bookmark_surah');
        if (bmSurah == surahNumber) {
          targetAyah = prefs.getInt('quran_bookmark_ayah');
        }
      }

      targetAyah ??= prefs.getInt('quran_ayah_$surahNumber');

      final surahs = await QuranService.loadSurahs();
      final surah = surahs.firstWhere((s) => s.number == surahNumber);
      final ayahs = await QuranService.loadAyahs(surahNumber);

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurahDetailPage(
              surah: surah,
              ayahs: ayahs,
              initialAyah: targetAyah,
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الصفحة المحفوظة')),
        );
      }
    }
  }

  static Future<void> _resumeAzkar(
    BuildContext context,
    String categoryTitle,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final categories = await AzkarService.loadAzkar();
      final category = categories.firstWhere((c) => c.title == categoryTitle);

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        await Navigator.pushNamed(
          context,
          AppRoutes.zkarDetails,
          arguments: category,
        );
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح الأذكار')));
      }
    }
  }

  static Future<void> _resumeHisn(
    BuildContext context,
    String categoryTitle,
  ) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.hisnDetails,
      arguments: categoryTitle,
    );
  }

  static Future<void> _resumeHadith(
    BuildContext context,
    int hadithNumber,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        await Navigator.pushNamed(
          context,
          AppRoutes.hadith,
          arguments: hadithNumber,
        );
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح الحديث')));
      }
    }
  }

  static Future<void> _resumeProphetStory(
    BuildContext context,
    int storyId,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final stories = await ProphetsStoriesService.loadStories();
      final story = stories.firstWhere((s) => s.id == storyId);

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProphetStoryDetailsScreen(story: story),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح قصة النبي')));
      }
    }
  }
}
