import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

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
  static const double _accentWidth = 4;
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
    final style = _SnackBarTone(type);
    final radius = BorderRadius.circular(AppConstants.radiusMedium);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.neutralSurface,
            borderRadius: radius,
            border: Border.all(color: AppColors.neutralBorder),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowStrong,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ColoredBox(
                    color: style.color,
                    child: const SizedBox(width: _accentWidth),
                  ),
                  Expanded(
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
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
        borderRadius: BorderRadius.circular(10),
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

  factory _SnackBarTone(AppSnackBarType type) => switch (type) {
    AppSnackBarType.success => const _SnackBarTone._(
      AppColors.success,
      AppColors.successSurface,
      Icons.check_rounded,
    ),
    AppSnackBarType.error => const _SnackBarTone._(
      AppColors.error,
      AppColors.errorSurface,
      Icons.priority_high_rounded,
    ),
    AppSnackBarType.warning => const _SnackBarTone._(
      AppColors.accent,
      AppColors.accentSurface,
      Icons.warning_amber_rounded,
    ),
    AppSnackBarType.info => const _SnackBarTone._(
      AppColors.primary,
      AppColors.primarySurface,
      Icons.info_outline_rounded,
    ),
  };
}
