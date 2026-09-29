import 'dart:ui';

import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';

/// Visual tone for branded dialogs.
enum AppDialogTone { destructive, primary, success, warning }

/// Shows a beautiful scale+fade animated dialog with brand colors.
///
/// Pass [content] to render custom widgets (e.g. a form) below the title
/// instead of/alongside [message]. Set [showActions] to false to hide the
/// built-in Cancel/Confirm row when [content] renders its own actions.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  IconData icon = Icons.info_rounded,
  AppDialogTone tone = AppDialogTone.primary,
  VoidCallback? onConfirm,
  bool barrierDismissible = true,
  Widget? content,
  bool showActions = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      );

      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0).animate(curved),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Center(
              child: AppAnimatedDialog(
                title: title,
                message: message,
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel ?? context.l10n.goBack,
                icon: icon,
                tone: tone,
                content: content,
                showActions: showActions,
                onConfirm: () {
                  Navigator.of(context).pop();
                  onConfirm?.call();
                },
                onCancel: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Polished centered dialog card used by [showAppDialog].
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
        ),
      AppDialogTone.primary => const _DialogPalette(
          accent: AppColors.primary,
          surface: AppColors.primarySurface,
          gradient: AppColors.primaryGradient,
        ),
      AppDialogTone.success => const _DialogPalette(
          accent: AppColors.success,
          surface: AppColors.successSurface,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
        ),
      AppDialogTone.warning => const _DialogPalette(
          accent: AppColors.accent,
          surface: AppColors.accentSurface,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6535), Color(0xFFE5521E)],
          ),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    final width = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width * 0.86,
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: palette.accent.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            const BoxShadow(
              color: AppColors.shadowStrong,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Colored top strip
              Container(
                height: 6,
                decoration: BoxDecoration(gradient: palette.gradient),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(
                  children: [
                    // Animated icon badge
                    _PulseIconBadge(
                      icon: icon,
                      palette: palette,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    if (content != null) ...[
                      const SizedBox(height: 16),
                      content!,
                    ],
                    if (showActions) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _DialogButton(
                              label: cancelLabel,
                              filled: false,
                              accent: palette.accent,
                              surface: palette.surface,
                              onTap: onCancel,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DialogButton(
                              label: confirmLabel ?? '',
                              filled: true,
                              accent: palette.accent,
                              surface: palette.surface,
                              gradient: palette.gradient,
                              onTap: onConfirm,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogPalette {
  final Color accent;
  final Color surface;
  final Gradient gradient;

  const _DialogPalette({
    required this.accent,
    required this.surface,
    required this.gradient,
  });
}

/// Soft pulsing icon circle at the top of the dialog.
class _PulseIconBadge extends StatefulWidget {
  final IconData icon;
  final _DialogPalette palette;

  const _PulseIconBadge({
    required this.icon,
    required this.palette,
  });

  @override
  State<_PulseIconBadge> createState() => _PulseIconBadgeState();
}

class _PulseIconBadgeState extends State<_PulseIconBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: widget.palette.gradient,
          boxShadow: [
            BoxShadow(
              color: widget.palette.accent.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(widget.icon, color: Colors.white, size: 32),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final bool filled;
  final Color accent;
  final Color surface;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const _DialogButton({
    required this.label,
    required this.filled,
    required this.accent,
    required this.surface,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: filled ? gradient : null,
            color: filled ? null : surface,
            borderRadius: BorderRadius.circular(14),
            border: filled
                ? null
                : Border.all(color: accent.withValues(alpha: 0.25)),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
