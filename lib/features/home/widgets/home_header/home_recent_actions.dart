import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:tarteel/Routes/AppRoutes.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/features/azkar/services/azkar_service.dart';
import 'package:tarteel/features/hisn_almuslim/services/hisn_service.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/views/surah_detail_page.dart';
import 'package:tarteel/features/prophets_stories/services/prophets_stories_service.dart';
import 'package:tarteel/features/prophets_stories/views/prophet_story_details_screen.dart';
import 'package:tarteel/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeRecentActions extends StatefulWidget {
  const HomeRecentActions({super.key});

  @override
  State<HomeRecentActions> createState() => _HomeRecentActionsState();
}

class _HomeRecentActionsState extends State<HomeRecentActions> with RouteAware {
  late Future<List<RecentAction>> _actionsFuture;

  @override
  void initState() {
    super.initState();
    _actionsFuture = RecentActionsManager.getActions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      tarteel.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    tarteel.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _reloadActions();
  }

  Future<void> _reloadActions() async {
    if (!mounted) return;
    setState(() {
      _actionsFuture = RecentActionsManager.getActions();
    });
  }

  Future<void> _resumeQuran(
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

  Future<void> _resumeAzkar(BuildContext context, String categoryTitle) async {
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

  Future<void> _resumeHisn(BuildContext context, String categoryTitle) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final categories = await HisnService.loadHisn();
      final category = categories.firstWhere((c) => c.title == categoryTitle);

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        await Navigator.pushNamed(
          context,
          AppRoutes.hisnDetails,
          arguments: category,
        );
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح حصن المسلم')));
      }
    }
  }

  Future<void> _resumeHadith(BuildContext context, int hadithNumber) async {
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

  Future<void> _resumeProphetStory(BuildContext context, int storyId) async {
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

  Future<void> _handleRecentActionTap(
    BuildContext context,
    RecentAction action,
  ) async {
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

    await _reloadActions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return FutureBuilder<List<RecentAction>>(
      future: _actionsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final actions = snapshot.data!;
        return Container(
          margin: EdgeInsets.only(bottom: 15.h),
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isDark
                  ? AppColors.greenBorder.withOpacity(0.50)
                  : AppColors.disabled,
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 3.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: actions
                    .map((action) => _buildRecentButton(context, action))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentButton(BuildContext context, RecentAction action) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    IconData getIcon() {
      switch (action.category) {
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
          return Icons.history_toggle_off_rounded;
      }
    }

    Color getCategoryColor(ColorScheme colorScheme) {
      //   switch (action.category) {
      //     case 'quran':
      //       return Colors.greenAccent;
      //     case 'azkar':
      //       return Colors.amberAccent;
      //     case 'hadith':
      //       return Colors.orangeAccent;
      //     case 'names_of_allah':
      //       return Colors.cyanAccent;
      //     default:
      //       return Colors.white;
      //   }

      // switch (action.category) {
      //   case 'quran':
      //     return Colors.white;
      //   case 'azkar':
      //     return Colors.white;
      //   case 'hadith':
      //     return Colors.white;
      //   case 'names_of_allah':
      //     return Colors.white;
      //   default:
      //     return Colors.white;
      // }

      switch (action.category) {
        case 'quran':
          return Colors.black;
        case 'azkar':
          return Colors.black;
        case 'hadith':
          return Colors.black;
        case 'names_of_allah':
          return Colors.black;
        default:
          return Colors.black;
      }
    }

    return Expanded(
      child: InkWell(
        onTap: () => _handleRecentActionTap(context, action),
        borderRadius: BorderRadius.circular(8.r),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? AppColors.goldAccent : AppColors.goldAccent,
                ),
                color: isDark
                    ? AppColors.primary.withOpacity(0.25)
                    : AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                getIcon(),
                size: 14.sp,
                color: isDark ? Colors.white : colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              action.title.replaceAll('سورة ', '').replaceAll('قصص الأنبياء - ', ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 6.5.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
