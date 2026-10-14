import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';

/// The full-width Next / Get started button: the theme's content green as
/// the fill (deep green on light, bright green on dark) with the surface
/// color as its label, so it reads in both themes.
class OnboardingActionButtonWidget extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const OnboardingActionButtonWidget({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryContent,
          foregroundColor: colors.backgroundWhite,
          minimumSize: const Size(0, 58),
        ),
        child: Text(label),
      ),
    );
  }
}
