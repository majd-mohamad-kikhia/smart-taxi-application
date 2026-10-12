import 'package:flutter/material.dart';

/// Brings [child] in with a short fade and a slide up, once, when it first
/// appears. For a list, give each row its [index]: the first [maxStaggered]
/// rows follow one another, [stagger] apart; later ones (scrolled into view,
/// or a next page) come in at once, without a wait.
///
/// Only the paint changes (opacity and a translation), never the layout, so
/// it costs one controller per row for under half a second. [play] false —
/// and a system that asks for reduced motion — shows the child at once.
class EntranceAnimationWidget extends StatefulWidget {
  static const Duration duration = Duration(milliseconds: 420);
  static const Duration stagger = Duration(milliseconds: 70);
  static const int maxStaggered = 7;
  static const double _rise = 24;

  /// The [EntranceAnimationWidget.slide] stagger.
  static const Duration slideStagger = Duration(milliseconds: 90);

  final Widget child;
  final int index;
  final bool play;

  /// A wait before the first row moves, e.g. while a sheet slides up.
  final Duration startDelay;

  /// How far apart the staggered rows start.
  final Duration staggerStep;

  /// Where the row starts, relative to its place (a rise by default).
  final Offset from;

  /// How big the row starts, growing to its full size.
  final double fromScale;

  /// The curve of the movement and scale (the fade always eases out).
  final Curve curve;

  /// [from] is in reading order: its x is mirrored in a right-to-left
  /// language, so "from the end edge" stays the end edge in Arabic.
  final bool directional;

  const EntranceAnimationWidget({
    super.key,
    required this.child,
    this.index = 0,
    this.play = true,
    this.startDelay = Duration.zero,
    this.staggerStep = stagger,
    this.from = const Offset(0, _rise),
    this.fromScale = 1,
    this.curve = Curves.easeOutCubic,
  }) : directional = false;

  /// The livelier entrance of the car-type sheet and the trips list: each
  /// row slides in from the end edge in turn and grows from a little smaller,
  /// settling with a small overshoot.
  const EntranceAnimationWidget.slide({
    super.key,
    required this.child,
    this.index = 0,
    this.play = true,
    this.startDelay = Duration.zero,
  }) : staggerStep = slideStagger,
       from = const Offset(72, 0),
       fromScale = 0.92,
       curve = Curves.easeOutBack,
       directional = true;

  @override
  State<EntranceAnimationWidget> createState() =>
      _EntranceAnimationWidgetState();
}

class _EntranceAnimationWidgetState extends State<EntranceAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final Duration _delay =
      widget.startDelay +
      (widget.index < EntranceAnimationWidget.maxStaggered
          ? widget.staggerStep * widget.index
          : Duration.zero);
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _motion;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = EntranceAnimationWidget.duration + _delay;
    _controller = AnimationController(vsync: this, duration: total);
    // The delay is the first part of the timeline, the motion the rest.
    final start = _delay.inMilliseconds / total.inMilliseconds;
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOut),
    );
    _motion = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: widget.curve),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decided once, when the row first appears; a later rebuild of the same
    // row never restarts it.
    if (_started) return;
    _started = true;
    if (widget.play && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward();
    } else {
      _controller.value = 1;
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
      child: widget.child,
      builder: (context, child) {
        final t = _motion.value;
        final from = widget.directional &&
                Directionality.of(context) == TextDirection.rtl
            ? Offset(-widget.from.dx, widget.from.dy)
            : widget.from;
        return Opacity(
          opacity: _fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: from * (1 - t),
            child: Transform.scale(
              scale: widget.fromScale + (1 - widget.fromScale) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
