import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The app's full-screen/full-section loading indicator — a circular progress
/// indicator in the app's primary color. Use for a standalone loading state
/// (a whole screen or a whole section); small inline spinners (buttons,
/// "load more" rows) use a plain `CircularProgressIndicator` sized to fit.
class AppLoaderWidget extends StatelessWidget {
  final double size;

  const AppLoaderWidget({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
