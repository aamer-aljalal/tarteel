import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tarteel/core/dialogs/exit_confirmation_dialog.dart';
import 'package:tarteel/features/home/data/home_actions.dart';
import 'package:tarteel/features/home/widgets/home_header/home_header.dart';
import 'package:tarteel/features/home/widgets/home_recent_actions.dart';
import 'package:tarteel/core/widgets/grids/access_list_grid.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:tarteel/core/providers/prayer_provider.dart';

import 'package:tarteel/core/widgets/backgrounds/islamic_pattern_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int adhkarCount = 120;
  int adhkarTarget = 300;
  int pagesRead = 5;
  int pagesTarget = 20;

  double get adhkarProgress => adhkarCount / adhkarTarget;
  double get readingProgress => pagesRead / pagesTarget;

  late AnimationController _progressController;
  late AnimationController _gridAnimationController;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressController.forward();

    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _gridAnimationController.forward();

    // تشغيل التحقق من صلاحيات الموقع وجلب الإحداثيات بطريقة متجاوبة وأنيقة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<PrayerProvider>(
          context,
          listen: false,
        ).checkAndPromptLocation(context);
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _gridAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await ExitConfirmationDialog(context);
        if (shouldExit) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HomeHeader(),
            Expanded(
              child: IslamicPatternBackground(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0.w,
                    vertical: 20.0.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HomeRecentActions(),
                      AccessListGrid(
                        actions: HomeActions.quickActionsList,
                        controller: _gridAnimationController,
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
