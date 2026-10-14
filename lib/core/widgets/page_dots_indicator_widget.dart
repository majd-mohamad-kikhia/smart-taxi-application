import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_palette.dart';

/// A row of [count] dots for a paged screen, the one at [index] stretched
/// into a brand-green pill. Decorative: the page itself says where the user
/// is, so it is hidden from screen readers.
class PageDotsIndicatorWidget extends StatelessWidget {
  static const double _dotSize = 6;
  static const double _activeWidth = 20;
  static const double _gap = 6;

  final int count;
  final int index;

  const PageDotsIndicatorWidget({
    super.key,
    required this.count,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _gap,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppConstants.animFast,
              curve: Curves.easeOut,
              width: i == index ? _activeWidth : _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                color: i == index
                    ? colors.primaryContent
                    : colors.borderStrong.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
            ),
        ],
      ),
    );
  }
}
