import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_palette.dart';

/// Tonal pill in neutral colors for the safe way out of a decision
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

  /// A different solid fill, for a button that sits on a surface the default
  /// muted fill would blend into (the map, a muted card).
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
    final fill = backgroundColor ?? context.colors.backgroundMuted;
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: fill,
        disabledBackgroundColor: fill,
        foregroundColor: context.colors.textPrimary,
        disabledForegroundColor: isLoading ? context.colors.textPrimary : null,
        side: BorderSide.none,
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
                color: context.colors.textPrimary,
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
