import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_palette.dart';

/// An icon inside a tinted rounded square: the leading mark of a settings
/// row, a payment method, a pickup or destination. The icon is decorative —
/// the text next to it carries the meaning — so it is hidden from screen
/// readers.
///
/// By default the tile is a `primarySurface` wash with a `primaryContent`
/// icon; pass [background] and [foreground] for another tone (a warning, a
/// destination).
class AppIconTileWidget extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? background;
  final Color? foreground;

  const AppIconTileWidget({
    super.key,
    required this.icon,
    this.size = 40,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background ?? colors.primarySurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        ),
        child: Icon(
          icon,
          size: size * 0.5,
          color: foreground ?? colors.primaryContent,
        ),
      ),
    );
  }
}
