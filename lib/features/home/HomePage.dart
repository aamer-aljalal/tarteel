/// ==============================================================================
///  وصف الملف: HomePage.dart
/// ==============================================================================
/// الصفحة الرئيسية لتطبيق ترتيل.
///
///  التصميم المعماري:
/// - تستخدم `BlocBuilder<HomeCubit, HomeState>` للاستماع لحالة الأزرار وإعادة رسمها فوراً.
/// - تدعم `reassemble()` الذكية: لإعادة قراءة ملف الأزرار JSON فوراً بمجرد الضغط
///   على Ctrl + S (Hot Reload ) دون الحاجة لعمل Restart أخضر!
/// ==============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/dialogs/exit_confirmation_dialog.dart';
import 'package:tarteel/core/providers/prayer_provider.dart';
import 'package:tarteel/core/widgets/backgrounds/islamic_pattern_background.dart';
import 'package:tarteel/core/widgets/grids/access_list_grid.dart';
import 'package:tarteel/features/home/cubit/home_cubit.dart';
import 'package:tarteel/features/home/cubit/home_state.dart';
import 'package:tarteel/features/home/widgets/home_header/home_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void reassemble() {
    super.reassemble();
    // إعادة تحميل ومزامنة ملف الأزرار فوراً عند كل Hot Reload / Ctrl+S
    context.read<HomeCubit>().syncFromGithub(HomeCubit.githubActionsUrl);
  }

  @override
  Widget build(BuildContext context) {
    // التحقق من صلاحيات الموقع لجلب مواقيت الصلاة في أول ظهور
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PrayerProvider>().checkAndPromptLocation(context);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
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
                child: BlocBuilder<HomeCubit, HomeState>(
                  builder: (context, state) {
                    return AccessListGrid(
                      actions: state.actions,
                      isLoading: state.isLoading,
                      isRectangle: false,
                      padding: EdgeInsets.only(
                        left: 20.w,
                        right: 20.w,
                        top: 20.h,
                        bottom: 50.h,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
