import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../cubit/map_pick_cubit.dart';
import '../cubit/map_pick_state.dart';

/// What sits at the center of the home map: a quiet dot normally, and while a
/// point is being placed a pin (green for pickup, teal for destination)
/// with the address under it in a small bubble.
class MapCenterMarkerWidget extends StatelessWidget {
  const MapCenterMarkerWidget({super.key});

  static const _pinWidth = 40.0;
  static const _pinHeight = 54.0;
  static const _glowSize = 72.0;
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
            : AppColors.accent;
        final bubbleWidth = MediaQuery.sizeOf(context).width * 0.7;
        // A zero-size anchor at the map's center: the pin's tip sits on it
        // and the bubble floats above the pin, so the bubble appearing never
        // shifts the pin off the spot it marks.
        return Center(
          child: SizedBox.shrink(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Soft glow on the ground under the pin's tip.
                Positioned(
                  bottom: -_glowSize / 2,
                  left: -_glowSize / 2,
                  width: _glowSize,
                  height: _glowSize,
                  child: _PinGlowWidget(color: color),
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

/// A teardrop pin: lighter at the top, a white ring for the logo, a soft shadow. Its tip is
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
    final light = Color.lerp(color, Colors.white, 0.35)!;
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [light, color],
        ).createShader(Offset.zero & size),
    );
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

/// A small glow that breathes under the pin's tip: a steady soft halo and a
/// ring that grows and fades. Still when the system asks for reduced motion.
class _PinGlowWidget extends StatefulWidget {
  final Color color;

  const _PinGlowWidget({required this.color});

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
      _controller.stop();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_controller.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.color.withValues(alpha: 0.45),
                    widget.color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            Container(
              width: 16 + 56 * t,
              height: 16 + 56 * t,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.55 * (1 - t)),
                  width: 2,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
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
        border: Border.all(color: context.colors.border),
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
