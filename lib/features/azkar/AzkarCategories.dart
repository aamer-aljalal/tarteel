import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/features/Azkar/services/azkar_service.dart';
import 'package:tarteel/core/widgets/grids/access_list_grid.dart';
import 'package:tarteel/core/widgets/backgrounds/islamic_pattern_background.dart';

/// UI ONLY — No navigation, no logic, only visual design.
/// Displays a grid of azkar categories with animations.
class AzkarCategoriesScreen extends StatefulWidget {
  const AzkarCategoriesScreen({super.key});

  @override
  State<AzkarCategoriesScreen> createState() => _AzkarCategoriesScreenState();
}

class _AzkarCategoriesScreenState extends State<AzkarCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: tarteelAppBar(
        titleText: 'الأذكار',
        elevation: 0,
        toolbarHeight: 90,
        // We already listen to the controller in initState, so onSearchChanged is optional
      ),

      body: IslamicPatternBackground(
        child: FutureBuilder<List<AccessListModel>>(
          future: AzkarService.loadAzkarAsActions(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              children: [
                AccessListGrid(
                  actions: snapshot.data!,
                  controller: _animationController,
                ),
                SizedBox(height: 32.h),
              ],
            ),
          );
        },
      ),
    ),
  );
}
}
