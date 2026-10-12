import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_palette.dart';

/// The app's basic card: a white (surface) rounded block with a hairline
/// border and no shadow, sitting flat on the page. Every list card, info
/// block and form group is built from it so they all share one shape.
///
/// [color] swaps the fill for an inset block on top of a surface (a
/// `primarySurface` highlight, a `backgroundMuted` field). With [onTap] the
/// whole card is a button with a ripple clipped to its shape; its screen
/// reader name comes from its content, so give [child] its own `Semantics`
/// if it needs a different one.
class AppSurfaceCardWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final bool bordered;
  final VoidCallback? onTap;

  const AppSurfaceCardWidget({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppConstants.paddingL),
    this.color,
    this.radius = AppConstants.radiusLarge,
    this.bordered = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: bordered
          ? BorderSide(color: context.colors.borderLight)
          : BorderSide.none,
    );
    return Material(
      color: color ?? context.colors.backgroundWhite,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
