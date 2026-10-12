import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../cubit/map_pick_cubit.dart';
import '../cubit/map_pick_state.dart';

/// What sits at the center of the home map: a quiet dot normally, and while a
/// point is being placed a pin (green for pickup, ink green for destination)
/// with the address under it in a small bubble.
class MapCenterMarkerWidget extends StatelessWidget {
  const MapCenterMarkerWidget({super.key});

  static const _pinWidth = 40.0;
  static const _pinHeight = 54.0;
  // The glow layer around the pin's tip.
  static const _glowWidth = 110.0;
  static const _glowBelowTip = 34.0;
  static const _glowAboveTip = 34.0;
  static const _logoSize = 26.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapPickCubit, MapPickState>(
      buildWhen: (previous, current) =>
          previous.target != current.target ||
          previous.address != current.address,
      builder: (context, state) {
        final target = state.target;
        if (target == null) return const Center(child: _DotWidget());
        final color = target == PickTarget.from
            ? AppColors.primaryBright
            : context.colors.accentContent;
        final bubbleWidth = MediaQuery.sizeOf(context).width * 0.7;
        // A zero-size anchor at the map's center: the pin's tip sits on it
        // and the bubble floats above the pin, so the bubble appearing never
        // shifts the pin off the spot it marks.
        return Center(
          child: SizedBox.shrink(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The glow on the ground under the pin's tip, painted behind the
                // pin.
                Positioned(
                  bottom: -_glowBelowTip,
                  left: -_glowWidth / 2,
                  width: _glowWidth,
                  height: _glowAboveTip + _glowBelowTip,
                  child: IgnorePointer(
                    child: _PinGlowWidget(
                      // Always the bright green: an ink-green glow would read
                      // as a shadow on the light map.
                      color: AppColors.primaryBright,
                      tipFromBottom: _glowBelowTip,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: -_pinWidth / 2,
                  width: _pinWidth,
                  height: _pinHeight,
                  child: CustomPaint(
                    painter: _PinPainter(color),
                    // The app's logo in the pin's head.
                    child: Align(
                      alignment: const Alignment(0, -0.5),
                      child: Container(
                        width: _logoSize,
                        height: _logoSize,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.black,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          AppConstants.logoPath,
                          fit: BoxFit.cover,
                          cacheWidth: 96,
                        ),
                      ),
                    ),
                  ),
                ),
                if (state.address != null)
                  Positioned(
                    bottom: _pinHeight + AppConstants.paddingXS,
                    left: -bubbleWidth / 2,
                    width: bubbleWidth,
                    child: Center(
                      child: _AddressBubbleWidget(address: state.address!),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A flat teardrop pin: a white ring for the logo and a soft shadow. Its tip is
/// the bottom-center of the box, which sits on the point it marks.
class _PinPainter extends CustomPainter {
  final Color color;

  const _PinPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final radius = w / 2;
    final center = Offset(w / 2, radius);
    final path = Path()
      ..moveTo(w / 2, h)
      ..cubicTo(w * 0.12, h * 0.62, 0, h * 0.5, 0, radius)
      ..arcToPoint(
        Offset(w, radius),
        radius: Radius.circular(radius),
        clockwise: true,
      )
      ..cubicTo(w, h * 0.5, w * 0.88, h * 0.62, w / 2, h)
      ..close();
    canvas.drawShadow(path, Colors.black, 4, true);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.85),
    );
    // A white ring around where the logo sits.
    canvas.drawCircle(center, radius * 0.74, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) => oldDelegate.color != color;
}

/// The glow at the pin's base, breathing slowly: a soft light on the ground
/// under its tip, and a ring that grows from the tip and fades. Held still at mid-breath when the system asks for
/// reduced motion. Painted only (the animation never rebuilds widgets).
class _PinGlowWidget extends StatefulWidget {
  final Color color;

  /// How far the pin's tip is from the bottom of this box.
  final double tipFromBottom;

  const _PinGlowWidget({
    required this.color,
    required this.tipFromBottom,
  });

  @override
  State<_PinGlowWidget> createState() => _PinGlowWidgetState();
}

class _PinGlowWidgetState extends State<_PinGlowWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PinGlowPainter(
        animation: _controller,
        color: widget.color,
        tipFromBottom: widget.tipFromBottom,
      ),
    );
  }
}

class _PinGlowPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final double tipFromBottom;

  _PinGlowPainter({
    required this.animation,
    required this.color,
    required this.tipFromBottom,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    // 0 → 1 → 0 over one cycle, for the light's slow breathing.
    final breath = Curves.easeInOut.transform(1 - (2 * t - 1).abs());
    final tip = Offset(size.width / 2, size.height - tipFromBottom);

    // Soft light on the ground under the tip.
    canvas.drawOval(
      Rect.fromCenter(center: tip, width: 30, height: 12),
      Paint()
        ..color = color.withValues(alpha: 0.45 + 0.2 * breath)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // A ring that grows from the tip and fades out.
    final pulse = Curves.easeOut.transform(t);
    canvas.drawOval(
      Rect.fromCenter(
        center: tip,
        width: 12 + 80 * pulse,
        height: 5 + 30 * pulse,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.6 * (1 - pulse)),
    );

    // The exact spot: a small solid dot.
    canvas.drawCircle(tip, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PinGlowPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.tipFromBottom != tipFromBottom;
}

class _AddressBubbleWidget extends StatelessWidget {
  final String address;

  const _AddressBubbleWidget({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      decoration: BoxDecoration(
        color: context.colors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: context.colors.borderLight),
      ),
      child: Text(
        address,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }
}

class _DotWidget extends StatelessWidget {
  const _DotWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryBright.withValues(alpha: 0.2),
      ),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryBright,
          border: Border.all(color: context.colors.neutralPage, width: 2.5),
        ),
      ),
    );
  }
}
