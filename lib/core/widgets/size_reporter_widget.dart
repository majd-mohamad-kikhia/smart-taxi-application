import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Tells its parent how big [child] is, every time that size changes — also
/// when the child grows or shrinks by itself without this widget being
/// rebuilt. For a map that has to know how much of itself the panels on top
/// of it cover, so that what it frames is never hidden behind them.
///
/// [onSize] is called after the frame that changed the size, so it may call
/// `setState`.
class SizeReporterWidget extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onSize;

  const SizeReporterWidget({
    super.key,
    required this.onSize,
    required Widget super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderSizeReporter renderObject,
  ) {
    renderObject.onSize = onSize;
  }
}

/// The render object behind [SizeReporterWidget].
class RenderSizeReporter extends RenderProxyBox {
  ValueChanged<Size> onSize;
  Size? _reported;

  RenderSizeReporter(this.onSize);

  @override
  void performLayout() {
    super.performLayout();
    final current = size;
    if (current == _reported) return;
    _reported = current;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onSize(current);
    });
  }
}
