import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/features/azkar/model/zekr_category.dart';
import 'package:tarteel/features/azkar/services/azkar_service.dart';
import 'package:tarteel/routes/AppRoutes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeAzkarPromptCard extends StatefulWidget {
  const HomeAzkarPromptCard({super.key});

  @override
  State<HomeAzkarPromptCard> createState() => _HomeAzkarPromptCardState();
}

class _HomeAzkarPromptCardState extends State<HomeAzkarPromptCard> {
  ZekrCategory? _category;
  _AzkarPrompt? _prompt;
  bool _isLoading = true;
  bool _isHidden = false;

  @override
  void initState() {
    super.initState();
    _loadPrompt();
  }

  Future<void> _loadPrompt() async {
    final prompt = _AzkarPrompt.forNow(DateTime.now());
    if (prompt == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isHidden = true;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hiddenKey = _hiddenKey(prompt);
    final isHidden = prefs.getBool(hiddenKey) ?? false;

    if (isHidden) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isHidden = true;
      });
      return;
    }

    final categories = await AzkarService.loadAzkar();
    final category = categories.firstWhere(
      (item) => item.title == prompt.categoryTitle,
      orElse: () => categories.first,
    );

    if (!mounted) return;
    setState(() {
      _prompt = prompt;
      _category = category;
      _isLoading = false;
    });
  }

  Future<void> _openAzkar() async {
    final prompt = _prompt;
    final category = _category;
    if (prompt == null || category == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hiddenKey(prompt), true);

    if (!mounted) return;
    setState(() => _isHidden = true);

    await Navigator.pushNamed(
      context,
      AppRoutes.zkarDetails,
      arguments: category,
    );
  }

  String _hiddenKey(_AzkarPrompt prompt) {
    final now = DateTime.now();
    final date = '${now.year}-${now.month}-${now.day}';
    return 'home_azkar_prompt_${prompt.categoryTitle}_$date';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isHidden || _prompt == null || _category == null) {
      return const SizedBox.shrink();
    }

    return _PromptCard(prompt: _prompt!, onTap: _openAzkar);
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt, required this.onTap});

  final _AzkarPrompt prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(top: 3.h),
        child: Material(
          color: Colors.transparent,

          child: InkWell(
            onTap: onTap,

            borderRadius: BorderRadius.circular(7.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
              decoration: BoxDecoration(
                // color: colorScheme.surface.withValues(alpha: 0.15),
                color: Colors.black.withOpacity(0.15),

                borderRadius: BorderRadius.circular(7.r),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      // border: Border.all(
                      //   color: AppColors.goldAccent.withValues(alpha: 0.5),
                      //   width: 1.w,
                      // ),
                    ),
                    child: Icon(prompt.icon, color: Colors.white, size: 14.sp),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      prompt.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.sp,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white70,
                    size: 12.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AzkarPrompt {
  const _AzkarPrompt({
    required this.categoryTitle,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String categoryTitle;
  final String title;
  final String subtitle;
  final IconData icon;

  static _AzkarPrompt? forNow(DateTime now) {
    final hour = now.hour;

    if (hour >= 4 && hour < 12) {
      return const _AzkarPrompt(
        categoryTitle: 'أذكار الصباح',
        title: 'حان وقت قراءة أذكار الصباح',
        subtitle: 'ابدأ يومك بذكر الله واطمئنان القلب.',
        icon: Icons.wb_sunny_outlined,
      );
    }

    if (hour >= 16 && hour < 21) {
      return const _AzkarPrompt(
        categoryTitle: 'أذكار المساء',
        title: 'حان وقت قراءة أذكار المساء',
        subtitle: 'اختم يومك بسكينة وذكر قبل المساء.',
        icon: Icons.nights_stay_outlined,
      );
    }

    if (hour >= 21 || hour < 4) {
      return const _AzkarPrompt(
        categoryTitle: 'أذكار النوم',
        title: 'حان وقت قراءة أذكار النوم',
        subtitle: 'اقرأ ورد النوم قبل أن تستريح.',
        icon: Icons.bedtime_outlined,
      );
    }

    return null;
  }
}
