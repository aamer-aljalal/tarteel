import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuranPageView extends StatefulWidget {
  const QuranPageView({
    super.key,
    required this.pageController,
    required this.totalPages,
    required this.buildPageSliver,
    required this.onPageChanged,
    this.initialPage = 0,
    this.pageIndicatorText,
    this.showPageIndicator = false,
  });

  final PageController pageController;
  final int totalPages;
  final Widget Function(int pageIndex) buildPageSliver;
  final ValueChanged<int> onPageChanged;
  final int initialPage;
  final String Function(int pageIndex)? pageIndicatorText;
  final bool showPageIndicator;

  @override
  State<QuranPageView> createState() => _QuranPageViewState();
}

class _QuranPageViewState extends State<QuranPageView> {
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: widget.pageController,
            itemCount: widget.totalPages,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              widget.onPageChanged(index);
            },
            itemBuilder: (context, index) {
              return widget.buildPageSliver(index);
            },
          ),
        ),
        if (widget.showPageIndicator) ...[
          SizedBox(height: 8.h),
          // Sleek page indicator badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2822).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text(
              widget.pageIndicatorText != null
                  ? widget.pageIndicatorText!(_currentPage)
                  : '${_currentPage + 1}',
              style: TextStyle(
                color: const Color(0xFF1E2822),
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Amiri',
              ),
            ),
          ),
        ],
      ],
    );
  }
}
