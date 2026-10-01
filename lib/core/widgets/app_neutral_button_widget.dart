import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Outlined button in neutral colors for the safe way out of a decision
/// ("Go back", "Not now") or a calm, reversible action ("Log out"). It never
/// takes the accent or danger color, so it can sit beside a destructive or
/// primary action without competing with it. Width comes from the parent
/// (wrap in a `SizedBox` or `Expanded`).
///
/// With [icon] the label gets a leading icon; while [isLoading] a spinner
/// replaces the label (which stays as the button's screen-reader name) and
/// taps are ignored.
class AppNeutralButtonWidget extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  /// A solid fill, for a button that sits on the map where a transparent
  /// outlined button would let the map show through.
  final Color? backgroundColor;

  const AppNeutralButtonWidget({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        disabledBackgroundColor: backgroundColor,
        foregroundColor: AppColors.textPrimary,
        disabledForegroundColor: isLoading ? AppColors.textPrimary : null,
        side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: 14,
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.textPrimary,
                semanticsLabel: label,
              ),
            )
          : (icon == null
              ? Text(label, textAlign: TextAlign.center)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: AppConstants.paddingS),
                    Flexible(child: Text(label, textAlign: TextAlign.center)),
                  ],
                )),
    );
  }
}
