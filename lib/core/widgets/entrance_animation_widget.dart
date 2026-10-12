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

  final Widget child;
  final int index;
  final bool play;

  const EntranceAnimationWidget({
    super.key,
    required this.child,
    this.index = 0,
    this.play = true,
  });

  @override
  State<EntranceAnimationWidget> createState() =>
      _EntranceAnimationWidgetState();
}

class _EntranceAnimationWidgetState extends State<EntranceAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final Duration _delay =
      widget.index < EntranceAnimationWidget.maxStaggered
      ? EntranceAnimationWidget.stagger * widget.index
      : Duration.zero;
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = EntranceAnimationWidget.duration + _delay;
    _controller = AnimationController(vsync: this, duration: total);
    // The delay is the first part of the timeline, the motion the rest.
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        _delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
    _fade = curve;
    _slide = Tween(
      begin: const Offset(0, EntranceAnimationWidget._rise),
      end: Offset.zero,
    ).animate(curve);
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
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(offset: _slide.value, child: child),
      ),
    );
  }
}
