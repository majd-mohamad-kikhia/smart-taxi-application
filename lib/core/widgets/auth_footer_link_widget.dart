import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Row pairing a plain text prompt with a tappable action label, used to
/// switch between sign in and sign up.
class AuthFooterLinkWidget extends StatelessWidget {
  final String text;
  final String actionLabel;
  final VoidCallback onTap;

  const AuthFooterLinkWidget({
    super.key,
    required this.text,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              actionLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
