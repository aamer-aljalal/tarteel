import 'package:flutter/material.dart';

class QuranContinuousScrollView extends StatelessWidget {
  const QuranContinuousScrollView({
    super.key,
    required this.scrollController,
    required this.centerSliverKey,
    required this.centerPage,
    required this.totalPages,
    required this.buildPageSliver,
    required this.onScrollEnd,
  });

  final ScrollController scrollController;
  final GlobalKey centerSliverKey;
  final int centerPage;
  final int totalPages;
  final Widget Function(int index) buildPageSliver;
  final VoidCallback onScrollEnd;

  @override
  Widget build(BuildContext context) {
    final safeCenterPage = centerPage.clamp(0, totalPages > 0 ? totalPages - 1 : 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          onScrollEnd();
        }
        return false;
      },
      child: CustomScrollView(
        controller: scrollController,
        center: centerSliverKey,
        physics: const ClampingScrollPhysics(),
        slivers: [
          if (safeCenterPage > 0)
            SliverList(
              delegate: SliverChildBuilderDelegate((
                context,
                index,
              ) {
                final actualIndex = safeCenterPage - 1 - index;
                return buildPageSliver(actualIndex);
              }, childCount: safeCenterPage),
            ),
          SliverList(
            key: centerSliverKey,
            delegate: SliverChildBuilderDelegate((
              context,
              index,
            ) {
              final actualIndex = safeCenterPage + index;
              return buildPageSliver(actualIndex);
            }, childCount: (totalPages - safeCenterPage).clamp(0, totalPages)),
          ),
        ],
      ),
    );
  }
}
