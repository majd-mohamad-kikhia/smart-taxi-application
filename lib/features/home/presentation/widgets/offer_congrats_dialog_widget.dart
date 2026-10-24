import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/auth_primary_button_widget.dart';

/// Opens the "congratulations, you won" pop-up shown when the prices open
/// while the manager has the offer on. It changes no price.
Future<void> showOfferCongratsDialog(BuildContext context) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.scrim,
    transitionDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 550),
    pageBuilder: (context, _, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: const OfferCongratsDialogWidget(),
      ),
    ),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
      child: ScaleTransition(
        scale: animation.drive(CurveTween(curve: Curves.elasticOut)),
        child: child,
      ),
    ),
  );
}

/// A big celebration card: a glowing trophy among twinkling stars, "مبروك!",
/// and "you won with us", with one button to carry on.
class OfferCongratsDialogWidget extends StatefulWidget {
  const OfferCongratsDialogWidget({super.key});

  @override
  State<OfferCongratsDialogWidget> createState() =>
      _OfferCongratsDialogWidgetState();
}

class _OfferCongratsDialogWidgetState extends State<OfferCongratsDialogWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _twinkle.stop();
    } else if (!_twinkle.isAnimating) {
      _twinkle.repeat();
    }
  }

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Material(
        color: colors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Hero(twinkle: _twinkle),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingXL,
                  AppConstants.paddingL,
                  AppConstants.paddingXL,
                  AppConstants.paddingXL,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.offerCongratsTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colors.primaryContent,
                          ),
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      l10n.offerCongratsMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXL),
                    AuthPrimaryButtonWidget(
                      label: l10n.continueLabel,
                      isLoading: false,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
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

/// The green banner on top: a pulsing trophy with stars around it.
class _Hero extends StatelessWidget {
  final Animation<double> twinkle;

  const _Hero({required this.twinkle});

  static const _stars = <({double x, double y, double size, double phase})>[
    (x: 0.14, y: 0.22, size: 22, phase: 0.0),
    (x: 0.84, y: 0.18, size: 28, phase: 0.3),
    (x: 0.24, y: 0.72, size: 16, phase: 0.6),
    (x: 0.78, y: 0.70, size: 20, phase: 0.15),
    (x: 0.50, y: 0.08, size: 14, phase: 0.45),
    (x: 0.92, y: 0.52, size: 14, phase: 0.75),
    (x: 0.06, y: 0.52, size: 14, phase: 0.9),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryBright, AppColors.primary],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) => AnimatedBuilder(
          animation: twinkle,
          builder: (context, _) {
            final pulse = 1 + 0.06 * math.sin(twinkle.value * 2 * math.pi);
            return Stack(
              alignment: Alignment.center,
              children: [
                for (final star in _stars)
                  Positioned(
                    left: box.maxWidth * star.x - star.size / 2,
                    top: 190 * star.y - star.size / 2,
                    child: Opacity(
                      opacity:
                          0.35 +
                          0.65 *
                              (0.5 +
                                  0.5 *
                                      math.sin(
                                        (twinkle.value + star.phase) *
                                            2 *
                                            math.pi,
                                      )),
                      child: Icon(
                        Icons.star_rounded,
                        size: star.size,
                        color: const Color(0xFFFFE08A),
                      ),
                    ),
                  ),
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white.withValues(alpha: 0.18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFFE08A,
                          ).withValues(alpha: 0.45),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 68,
                      color: Color(0xFFFFD25A),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
