import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';

/// The square "use my location" GPS button. Shows a spinner while a fix is
/// being found; `null` [onTap] disables it. With [glow] a soft green halo
/// breathes slowly around it (still when the system asks for reduced motion).
class HomeGpsButtonWidget extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onTap;
  final double size;
  final bool glow;

  const HomeGpsButtonWidget({
    super.key,
    required this.isLoading,
    required this.onTap,
    this.size = 52,
    this.glow = false,
  });

  @override
  State<HomeGpsButtonWidget> createState() => _HomeGpsButtonWidgetState();
}

class _HomeGpsButtonWidgetState extends State<HomeGpsButtonWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = widget.glow && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.useMyLocation;
    final radius = BorderRadius.circular(AppConstants.radiusLarge);
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = widget.glow ? Curves.easeInOut.transform(_controller.value) : 0.0;
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: widget.glow
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25 + 0.3 * t),
                          blurRadius: 10 + 12 * t,
                          spreadRadius: 1 + 2 * t,
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
          child: Material(
            color: context.colors.neutralSurface,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: widget.glow ? AppColors.primary : context.colors.border,
              ),
            ),
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onTap,
              customBorder: RoundedRectangleBorder(borderRadius: radius),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: widget.size * 0.4,
                          height: widget.size * 0.4,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: context.colors.primaryContent,
                          ),
                        )
                      : Icon(
                          Icons.my_location_rounded,
                          color: context.colors.primaryContent,
                          size: widget.size * 0.5,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
