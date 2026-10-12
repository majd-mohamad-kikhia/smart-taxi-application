import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// The small grabber bar at the top of a bottom sheet. Purely decorative, so
/// it is hidden from screen readers.
class AppSheetHandleWidget extends StatelessWidget {
  const AppSheetHandleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
