import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';
import 'app_dialog_layout_widget.dart';
import 'app_neutral_button_widget.dart';

/// Visual tone for branded dialogs.
enum AppDialogTone { destructive, primary, success, warning }

/// Shows the app's branded confirm dialog: a flat card with an icon, a
/// title, an optional message and a confirm / "go back" pair.
///
/// Pass [content] to render custom widgets (e.g. a form) below the title
/// instead of/alongside [message]. Set [showActions] to false to hide the
/// built-in Cancel/Confirm row when [content] renders its own actions.
///
/// With [barrierDismissible] false the dialog can be left only through its
/// own buttons: the Android back button is blocked as well as scrim taps.
/// The entrance is a quick fade and is skipped when the system asks for
/// reduced motion.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  IconData icon = Icons.info_rounded,
  AppDialogTone tone = AppDialogTone.primary,
  VoidCallback? onConfirm,

  /// Runs when the dialog's own "go back" button is pressed — not when it is
  /// dismissed any other way (scrim, Back, or the route being removed).
  VoidCallback? onCancel,
  bool barrierDismissible = true,
  Widget? content,
  bool showActions = true,
}) {
  // The buttons stay tappable while the dialog animates out, so a quick
  // second tap would otherwise pop the screen underneath (and run the
  // confirm action twice). Only the first tap counts.
  var handled = false;
  void once(VoidCallback action) {
    if (handled) return;
    handled = true;
    action();
  }

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.scrim,
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppConstants.animFast,
    pageBuilder: (context, animation, secondaryAnimation) {
      return PopScope(
        canPop: barrierDismissible,
        child: Semantics(
          namesRoute: true,
          label: title,
          child: AppDialogLayoutWidget(
            child: AppAnimatedDialog(
              title: title,
              message: message,
              confirmLabel: confirmLabel,
              cancelLabel: cancelLabel ?? context.l10n.goBack,
              icon: icon,
              tone: tone,
              content: content,
              showActions: showActions,
              onConfirm: () => once(() {
                Navigator.of(context).pop();
                onConfirm?.call();
              }),
              onCancel: () => once(() {
                Navigator.of(context).pop();
                onCancel?.call();
              }),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final eased = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: eased,
        child: ScaleTransition(
          scale: eased.drive(Tween<double>(begin: 0.96, end: 1.0)),
          child: child,
        ),
      );
    },
  );
}

class AppAnimatedDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String? confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final AppDialogTone tone;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Widget? content;
  final bool showActions;

  const AppAnimatedDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.tone,
    this.onConfirm,
    this.onCancel,
    this.content,
    this.showActions = true,
  });

  _DialogPalette get _palette {
    return switch (tone) {
      AppDialogTone.destructive => const _DialogPalette(
          accent: AppColors.error,
          surface: AppColors.errorSurface,
          solid: AppColors.errorDark,
          onSolid: AppColors.white,
        ),
      AppDialogTone.primary => const _DialogPalette(
          accent: AppColors.primary,
          surface: AppColors.primarySurface,
          solid: AppColors.primary,
          onSolid: AppColors.textOnPrimary,
        ),
      AppDialogTone.success => const _DialogPalette(
          accent: AppColors.success,
          surface: AppColors.successSurface,
          solid: AppColors.success,
          onSolid: AppColors.textOnSuccess,
        ),
      AppDialogTone.warning => const _DialogPalette(
          accent: AppColors.accent,
          surface: AppColors.accentSurface,
          solid: AppColors.accent,
          onSolid: AppColors.textOnPrimary,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.transparent,
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.86,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingXXL,
          AppConstants.paddingXXL,
          AppConstants.paddingXXL,
          AppConstants.paddingXL,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowStrong,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogBadge(icon: icon, palette: palette),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: AppConstants.paddingM),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: AppConstants.paddingL),
              content!,
            ],
            if (showActions) ...[
              const SizedBox(height: AppConstants.paddingXXL),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: AppNeutralButtonWidget(
                        label: cancelLabel,
                        onPressed: onCancel,
                      ),
                    ),
                    if (confirmLabel != null) ...[
                      const SizedBox(width: AppConstants.paddingM),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.solid,
                            foregroundColor: palette.onSolid,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingM,
                              vertical: 14,
                            ),
                          ),
                          child: Text(confirmLabel!, textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The colors of one [AppDialogTone]. The confirm button is a solid fill
/// ([solid]) with a foreground ([onSolid]) chosen for contrast, so white is
/// used only on the dark red and never on yellow, amber or green.
class _DialogPalette {
  final Color accent;
  final Color surface;
  final Color solid;
  final Color onSolid;

  const _DialogPalette({
    required this.accent,
    required this.surface,
    required this.solid,
    required this.onSolid,
  });
}

/// Flat round icon tile: the accent icon on its wash. Decorative, so it is
/// hidden from screen readers (the title names the dialog).
class _DialogBadge extends StatelessWidget {
  final IconData icon;
  final _DialogPalette palette;

  const _DialogBadge({required this.icon, required this.palette});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(color: palette.surface, shape: BoxShape.circle),
        child: Icon(icon, color: palette.accent, size: 30),
      ),
    );
  }
}
