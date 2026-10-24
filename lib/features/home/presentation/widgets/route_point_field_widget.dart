import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';

/// One row of the From / To card: a marker, the row's name and a text field
/// that shows the point's address and is also where a place is searched for.
///
/// The row that is being placed on the map is [isActive]: it is tinted, its
/// name takes the brand color, and typing in it searches. A row that is not
/// active shows its point, and tapping it ([onTap]) makes it the active one;
/// its map button ([onPickOnMap]) does the same without the keyboard. A
/// [isLocked] row (a quote, a booking or a ride is live) only shows.
///
/// Purely presentational: the text, the focus and the search belong to the
/// card that owns this row.
class RoutePointFieldWidget extends StatelessWidget {
  final String label;
  final Widget marker;
  final TextEditingController controller;
  final FocusNode focusNode;

  /// What the empty field says: where to go, or that the address is being
  /// looked up.
  final String hint;

  /// The extra directions typed for the point (building, floor, landmark…),
  /// shown under the address while the row is not being edited.
  final String? details;

  final bool isActive;
  final bool isLocked;

  /// A search or an address lookup is running for this row.
  final bool isBusy;

  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onPickOnMap;

  const RoutePointFieldWidget({
    super.key,
    required this.label,
    required this.marker,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.details,
    required this.isActive,
    required this.isLocked,
    required this.isBusy,
    required this.onTap,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onPickOnMap,
  });

  static const _noBorder = InputBorder.none;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final details = this.details;
    return AnimatedContainer(
      duration: AppConstants.animFast,
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsetsDirectional.only(
        start: AppConstants.paddingM,
        end: AppConstants.paddingXS,
        top: AppConstants.paddingXS,
        bottom: AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: isActive ? colors.primarySurface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Row(
        children: [
          SizedBox(width: 24, child: Center(child: marker)),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? colors.primaryContent
                        : colors.textSecondary,
                  ),
                ),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: isLocked,
                  enableInteractiveSelection: !isLocked,
                  maxLines: 1,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.search,
                  onTap: onTap,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    hintText: hint,
                    hintMaxLines: 1,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textTertiary,
                    ),
                    border: _noBorder,
                    enabledBorder: _noBorder,
                    focusedBorder: _noBorder,
                    disabledBorder: _noBorder,
                    errorBorder: _noBorder,
                    focusedErrorBorder: _noBorder,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
                if (details != null && !isActive)
                  Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
          _Trailing(
            controller: controller,
            focusNode: focusNode,
            isActive: isActive,
            isLocked: isLocked,
            isBusy: isBusy,
            onClear: onClear,
            onSubmit: onSubmitted == null
                ? null
                : () => onSubmitted!(controller.text),
            onPickOnMap: onPickOnMap,
          ),
        ],
      ),
    );
  }
}

/// What sits at the end of a row: a spinner while it works; while it is being
/// typed in, clear and search; on a row that is not active, the map button.
class _Trailing extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final bool isLocked;
  final bool isBusy;
  final VoidCallback? onClear;
  final VoidCallback? onSubmit;
  final VoidCallback? onPickOnMap;

  const _Trailing({
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.isLocked,
    required this.isBusy,
    required this.onClear,
    required this.onSubmit,
    required this.onPickOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (isBusy) {
      return SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: colors.primaryContent,
              semanticsLabel: context.l10n.loading,
            ),
          ),
        ),
      );
    }
    if (isActive) {
      // Only the typing state listens to the text and the focus, so nothing
      // else rebuilds as the customer types.
      return ListenableBuilder(
        listenable: Listenable.merge([controller, focusNode]),
        builder: (context, _) {
          if (!focusNode.hasFocus || controller.text.isEmpty) {
            return const SizedBox.shrink();
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: colors.textTertiary,
                ),
                onPressed: onClear,
              ),
              IconButton(
                tooltip: context.l10n.search,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: colors.primaryContent,
                  foregroundColor: colors.backgroundWhite,
                ),
                icon: const Icon(Icons.search_rounded, size: 20),
                onPressed: onSubmit,
              ),
            ],
          );
        },
      );
    }
    if (isLocked || onPickOnMap == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: context.l10n.savedAddressPickOnMap,
      icon: Icon(Icons.pin_drop_outlined, color: colors.primaryContent),
      onPressed: onPickOnMap,
    );
  }
}
