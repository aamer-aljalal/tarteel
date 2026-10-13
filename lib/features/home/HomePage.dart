/// ==============================================================================
///  وصف الملف: HomePage.dart
/// ==============================================================================
/// الصفحة الرئيسية لتطبيق ترتيل.
///
///  التصميم المعماري:
/// - StatelessWidget نقية تماماً بنمط BLoC / Cubit.
/// - تستخدم `BlocBuilder<HomeCubit, HomeState>` للاستماع لحالة الأزرار وإعادة رسمها فوراً
///   دون الحاجة لأي Stateful Lifecycle أو متغيرات تحكم يدوية.
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // التحقق من صلاحيات الموقع لجلب مواقيت الصلاة في أول ظهور
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrayerProvider>().checkAndPromptLocation(context);
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
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0.w,
                      vertical: 20.0.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BlocBuilder<HomeCubit, HomeState>(
                          builder: (context, state) {
                            if (state.isLoading && state.actions.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return AccessListGrid(actions: state.actions);
                          },
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
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
