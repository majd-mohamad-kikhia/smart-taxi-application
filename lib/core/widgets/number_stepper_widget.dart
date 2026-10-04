import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// A whole number between [min] and [max] with − / + buttons on each side.
/// Keeps its own value and reports every change through [onChanged].
/// Screen readers get one adjustable control named [label].
class NumberStepperWidget extends StatefulWidget {
  final int initialValue;
  final int min;
  final int max;
  final String label;
  final ValueChanged<int> onChanged;

  const NumberStepperWidget({
    super.key,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
  }) : assert(min <= max);

  @override
  State<NumberStepperWidget> createState() => _NumberStepperWidgetState();
}

class _NumberStepperWidgetState extends State<NumberStepperWidget> {
  late int _value = widget.initialValue.clamp(widget.min, widget.max);

  bool get _canDecrease => _value > widget.min;
  bool get _canIncrease => _value < widget.max;

  void _change(int delta) {
    final next = (_value + delta).clamp(widget.min, widget.max);
    if (next == _value) return;
    setState(() => _value = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      value: '$_value',
      increasedValue: _canIncrease ? '${_value + 1}' : null,
      decreasedValue: _canDecrease ? '${_value - 1}' : null,
      onIncrease: _canIncrease ? () => _change(1) : null,
      onDecrease: _canDecrease ? () => _change(-1) : null,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onPressed: _canDecrease ? () => _change(-1) : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72),
            child: Text(
              '$_value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onPressed: _canIncrease ? () => _change(1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 28,
      constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primarySurface,
        foregroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.backgroundMuted,
        disabledForegroundColor: AppColors.textTertiary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        ),
      ),
    );
  }
}
