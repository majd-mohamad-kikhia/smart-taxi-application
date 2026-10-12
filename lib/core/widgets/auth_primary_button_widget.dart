import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// Full-width main button (sign in, sign up, search, request…): a tall solid
/// brand-green pill with the label in the middle and an arrow in a soft
/// circle at its end edge, and a loading spinner state.
///
/// While [isLoading] the button keeps its full color so the spinner remains
/// visible; when it is disabled for any other reason ([onPressed] is null)
/// it shows in the dimmed green. [showArrow] false drops the arrow, for a
/// button that does not move the user forward.
class AuthPrimaryButtonWidget extends StatelessWidget {
  static const double _arrowSize = 40;

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool showArrow;

  const AuthPrimaryButtonWidget({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = isLoading || onPressed != null;
    final foreground = enabled
        ? AppColors.textOnPrimary
        : context.colors.textOnPrimaryDisabled;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: isLoading
              ? AppColors.primary
              : AppColors.primaryDisabled,
          foregroundColor: AppColors.textOnPrimary,
          disabledForegroundColor: foreground,
          minimumSize: const Size(0, 58),
          // With the arrow, the start side is padded by the arrow's width so the
          // label stays centered; the spinner has no arrow beside it, so it
          // gets even padding to sit in the true center.
          padding: showArrow && !isLoading
              ? const EdgeInsetsDirectional.only(start: _arrowSize + 16, end: 8)
              : const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.textOnPrimary,
                  // Keeps the button's name for screen readers while the
                  // label text is swapped for the spinner.
                  semanticsLabel: label,
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showArrow) ...[
                    const SizedBox(width: 8),
                    _ArrowCircle(size: _arrowSize, color: foreground),
                  ],
                ],
              ),
      ),
    );
  }
}

/// The arrow at the button's end edge, pointing the way the text reads.
class _ArrowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _ArrowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white.withValues(alpha: 0.18),
        ),
        child: Icon(
          isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
          color: color,
          size: 20,
        ),
      ),
    );
  }
}
