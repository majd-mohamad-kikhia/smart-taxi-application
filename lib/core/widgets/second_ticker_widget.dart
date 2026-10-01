import 'dart:async';
import 'package:flutter/widgets.dart';

/// Rebuilds [builder] every second while [active], and only [builder] — so a
/// live timer repaints itself without rebuilding the screen around it. The
/// numbers themselves come from the model (server value + local count-up);
/// this only triggers the repaint.
class SecondTickerWidget extends StatefulWidget {
  final bool active;
  final WidgetBuilder builder;

  const SecondTickerWidget({
    super.key,
    required this.active,
    required this.builder,
  });

  @override
  State<SecondTickerWidget> createState() => _SecondTickerWidgetState();
}

class _SecondTickerWidgetState extends State<SecondTickerWidget> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant SecondTickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    if (widget.active) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
