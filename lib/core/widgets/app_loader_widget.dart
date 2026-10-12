import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// The app's full-screen/full-section loading indicator: a circular progress
/// indicator in the brand color. Use for a standalone loading state (a whole
/// screen or a whole section); small inline spinners (buttons, "load more"
/// rows) use a plain `CircularProgressIndicator`.
///
/// [size] is the diameter of the box the indicator is centered in; the ring
/// itself is a sensible fraction of it so the old call sites (80, 100, 160)
/// all look right.
class AppLoaderWidget extends StatelessWidget {
  final double size;

  const AppLoaderWidget({super.key, this.size = 160});

  @override
  Widget build(BuildContext context) {
    final ring = (size * 0.25).clamp(24.0, 40.0);
    return Center(
      child: SizedBox(
        width: ring,
        height: ring,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: context.colors.primaryContent,
        ),
      ),
    );
  }
}
