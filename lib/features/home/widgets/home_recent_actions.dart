import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/services/recent_actions_navigator.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/main.dart';

class HomeRecentActions extends StatefulWidget {
  const HomeRecentActions({super.key});

  @override
  State<HomeRecentActions> createState() => _HomeRecentActionsState();
}

class _HomeRecentActionsState extends State<HomeRecentActions> with RouteAware {
  late Future<List<RecentAction>> _actionsFuture;

  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
    _pageController?.dispose();
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

  Future<void> _handleRecentActionTap(
    BuildContext context,
    RecentAction action,
  ) async {
    await RecentActionNavigator.resume(context, action);
    await _reloadActions();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RecentAction>>(
      future: _actionsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final actions = snapshot.data!;

        if (actions.length == 1) {
          return _buildActionCard(context, actions.first);
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            height: 46.h,
            child: PageView.builder(
              controller: _pageController,
              itemCount: actions.length,
              itemBuilder: (context, index) {
                return _buildActionCard(
                  context,
                  actions[index],
                  currentPage: index,
                  totalPages: actions.length,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    RecentAction action, {
    int? currentPage,
    int? totalPages,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(top: 3.h),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleRecentActionTap(context, action),
            borderRadius: BorderRadius.circular(7.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
              decoration: BoxDecoration(
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
                    ),
                    child: Icon(
                      _getCategoryIcon(action.category),
                      color: Colors.white,
                      size: 14.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getCategoryLabel(action.category),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Amiri',
                                height: 1.25,
                              ),
                            ),
                            if (action.subtitle.isNotEmpty &&
                                action.subtitle != action.title &&
                                !action.title.contains(action.subtitle)) ...[
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  '• ${action.subtitle}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 8.sp,
                                    fontFamily: 'Amiri',
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 2.5.h),
                        Text(
                          action.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9.5.sp,
                            fontFamily: 'Amiri',
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (totalPages != null && totalPages > 1) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        '${(currentPage ?? 0) + 1}/$totalPages',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 7.sp,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                  SizedBox(width: 4.w),
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

  IconData _getCategoryIcon(String category) =>
      RecentActionNavigator.getCategoryIcon(category);

  String _getCategoryLabel(String category) =>
      RecentActionNavigator.getCategoryLabel(category);
}
