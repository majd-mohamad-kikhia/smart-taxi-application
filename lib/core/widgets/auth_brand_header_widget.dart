import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import 'auth_header_widget.dart';
import 'auth_language_toggle_widget.dart';

/// The solid brand-green header at the top of the screens before sign-in:
/// rounded bottom corners, the language switch at the end edge, the logo,
/// the title and subtitle in white, and an optional [below] widget (the role
/// badge). It runs under the status bar, so the screen should set light
/// status bar icons.
///
/// [overlap] is extra space at the bottom for the card that rides up over
/// the header's edge.
class AuthBrandHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? below;
  final double overlap;

  const AuthBrandHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.below,
    this.overlap = 0,
  });

  @override
  Widget build(BuildContext context) {
    final below = this.below;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingXXL,
        MediaQuery.paddingOf(context).top + AppConstants.paddingS,
        AppConstants.paddingXXL,
        overlap + AppConstants.paddingXL,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AuthLanguageToggleWidget(onBrand: true),
          ),
          const SizedBox(height: AppConstants.paddingS),
          AuthHeaderWidget(title: title, subtitle: subtitle, onBrand: true),
          if (below != null) ...[
            const SizedBox(height: AppConstants.paddingL),
            Center(child: below),
          ],
        ],
      ),
    );
  }
}
