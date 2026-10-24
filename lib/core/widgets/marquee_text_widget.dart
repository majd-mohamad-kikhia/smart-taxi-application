import 'package:flutter/material.dart';

/// One line of text that slides to show the rest of itself when it is too long
/// for its space, instead of being cut with "…".
///
/// Text that fits is a plain [Text]: nothing animates and nothing is held.
/// Text that does not fit rests, slides until its end is in view, rests, and
/// slides back, again and again. The slide follows the reading direction (it
/// starts at the right in Arabic) and is skipped altogether, leaving the "…",
/// when the system asks for reduced motion.
///
/// Cheap by design: the text is measured once per size, the slide is one
/// transform of an already laid out line inside its own repaint layer, and
/// the animation runs only while the text overflows.
class MarqueeTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;

  /// How fast the text slides, in logical pixels a second.
  final double velocity;

  /// How long it rests at each end.
  final Duration pause;

  const MarqueeTextWidget({
    super.key,
    required this.text,
    this.style,
    this.velocity = 36,
    this.pause = const Duration(milliseconds: 1400),
  });

  @override
  State<MarqueeTextWidget> createState() => _MarqueeTextWidgetState();
}

class _MarqueeTextWidgetState extends State<MarqueeTextWidget>
    with SingleTickerProviderStateMixin {
  /// A little room past the last letter, so it does not touch the edge.
  static const _endGap = 6.0;

  late final AnimationController _controller;

  /// What the running animation was set up for (how far, how fast, how long
  /// the rests); null while it is not running.
  (double, double, Duration)? _running;

  /// The measured size of the line, kept until what it depends on changes.
  Object? _measuredFor;
  Size _measured = Size.zero;

  @override
  void initState() {
    super.initState();
    // Made now, though text that fits never runs it: a controller first made
    // while the widget is being disposed would be an error.
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Size _measure(TextStyle style, TextDirection direction, TextScaler scaler) {
    final key = (widget.text, style, direction, scaler);
    if (_measuredFor == key) return _measured;
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    _measuredFor = key;
    _measured = painter.size;
    painter.dispose();
    return _measured;
  }

  /// Runs the slide for [distance], or stops it when null — only if that is
  /// a change. Done after the frame: the controller must not be touched while
  /// the tree builds.
  void _setSliding(double? distance) {
    final wanted = distance == null
        ? null
        : (distance, widget.velocity, widget.pause);
    if (_running == wanted) return;
    _running = wanted;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _running != wanted) return;
      if (distance == null) {
        _controller.stop();
        return;
      }
      final slide = Duration(
        milliseconds: (distance / widget.velocity * 1000).round(),
      );
      _controller
        ..duration = slide * 2 + widget.pause * 2
        ..repeat();
    });
  }

  /// Where the text is, as a share of the distance it slides, at [t] (0 to 1)
  /// of one round: rest, slide out, rest, slide back.
  double _position(double t, double distance) {
    final total = _controller.duration!.inMicroseconds;
    final pause = widget.pause.inMicroseconds / total;
    final slide = (total - 2 * widget.pause.inMicroseconds) / 2 / total;
    if (t < pause) return 0;
    if (t < pause + slide) {
      return Curves.easeInOut.transform((t - pause) / slide);
    }
    if (t < 2 * pause + slide) return 1;
    return 1 - Curves.easeInOut.transform((t - 2 * pause - slide) / slide);
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final size = _measure(style, direction, scaler);
        final overflow = size.width - available;
        if (!available.isFinite || overflow <= 0.5 || reduceMotion) {
          _setSliding(null);
          return Text(
            widget.text,
            style: style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          );
        }

        final distance = overflow + _endGap;
        _setSliding(distance);
        // The slide moves toward the end of the line: left in a left-to-right
        // language, right in Arabic.
        final sign = direction == TextDirection.rtl ? 1.0 : -1.0;
        return RepaintBoundary(
          child: ClipRect(
            child: SizedBox(
              width: available,
              height: size.height,
              child: OverflowBox(
                alignment: AlignmentDirectional.centerStart,
                minWidth: 0,
                maxWidth: double.infinity,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      sign *
                          distance *
                          (_controller.duration == null
                              ? 0
                              : _position(_controller.value, distance)),
                      0,
                    ),
                    child: child,
                  ),
                  child: Text(
                    widget.text,
                    style: style,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
