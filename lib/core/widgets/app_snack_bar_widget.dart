import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// What a snack bar is telling the user. Drives its accent color and icon.
enum AppSnackBarType { success, error, warning, info }

/// Shows the app's one snack bar, replacing any that is still on screen.
///
/// Use [showAppSnackBarOn] instead when the [ScaffoldMessengerState] was
/// captured before an `await` or a navigation and [context] may be gone.
void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackBarType type = AppSnackBarType.info,
}) => showAppSnackBarOn(ScaffoldMessenger.of(context), message, type: type);

void showAppSnackBarOn(
  ScaffoldMessengerState messenger,
  String message, {
  AppSnackBarType type = AppSnackBarType.info,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: AppSnackBarWidget(message: message, type: type),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(AppConstants.paddingL),
        duration: const Duration(seconds: 4),
      ),
    );
}

/// The visual body of the app's snack bar: a solid surface card with a
/// thin accent edge and a tinted icon tile. Rendered inside a transparent
/// [SnackBar] by [showAppSnackBar], which owns the slide/dismiss behavior.
class AppSnackBarWidget extends StatelessWidget {
  static const double _maxWidth = 480;
  static const double _iconTileSize = 36;

  final String message;
  final AppSnackBarType type;

  const AppSnackBarWidget({
    super.key,
    required this.message,
    this.type = AppSnackBarType.info,
  });

  @override
  Widget build(BuildContext context) {
    final style = _SnackBarTone(context, type);
    final radius = BorderRadius.circular(AppConstants.radiusMedium);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.neutralSurface,
            borderRadius: radius,
            border: Border.all(color: context.colors.neutralBorder),
            boxShadow: [
              BoxShadow(
                color: context.colors.shadowMedium,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Row(
              children: [
                _IconTile(style: style, size: _iconTileSize),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final _SnackBarTone style;
  final double size;

  const _IconTile({required this.style, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Icon(style.icon, color: style.color, size: 20),
    );
  }
}

/// Accent color, tinted fill and icon for one [AppSnackBarType].
class _SnackBarTone {
  final Color color;
  final Color surface;
  final IconData icon;

  const _SnackBarTone._(this.color, this.surface, this.icon);

  factory _SnackBarTone(BuildContext context, AppSnackBarType type) =>
      switch (type) {
        AppSnackBarType.success => _SnackBarTone._(
          AppColors.success,
          context.colors.successSurface,
          Icons.check_rounded,
        ),
        AppSnackBarType.error => _SnackBarTone._(
          AppColors.error,
          context.colors.errorSurface,
          Icons.priority_high_rounded,
        ),
        AppSnackBarType.warning => _SnackBarTone._(
          AppColors.warning,
          context.colors.warningSurface,
          Icons.warning_amber_rounded,
        ),
        AppSnackBarType.info => _SnackBarTone._(
          AppColors.primary,
          context.colors.primarySurface,
          Icons.info_outline_rounded,
        ),
      };
}
