import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// Full-width destructive action button (cancel, delete, …) with a
/// loading spinner state: a soft red pill, the calm counterpart to
/// [AuthPrimaryButtonWidget] that still reads as "danger" by its label and
/// color.
///
/// While [isLoading] the button stays at full strength so the spinner stays
/// visible, and the spinner keeps the button's label as its screen-reader
/// name; when it is disabled for any other reason ([onPressed] is null) it is
/// dimmed.
class AppDestructiveButtonWidget extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AppDestructiveButtonWidget({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.errorSurface,
          foregroundColor: colors.errorText,
          disabledBackgroundColor: isLoading
              ? colors.errorSurface
              : colors.errorSurface.withValues(alpha: 0.5),
          disabledForegroundColor: isLoading
              ? colors.errorText
              : colors.errorText.withValues(alpha: 0.6),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: colors.errorText,
                  semanticsLabel: label,
                ),
              )
            : Text(label),
      ),
    );
  }
}
