import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_palette.dart';

/// Rounded "search for a place" text field with a spinner while searching and
/// a clear button once something is typed. Nothing is searched while typing:
/// the keyboard's search key, or the search icon, hands the text to
/// [onSubmitted].
class PlaceSearchFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const PlaceSearchFieldWidget({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: context.colors.border),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: context.colors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: context.l10n.searchPlaceHint,
          hintStyle: TextStyle(
            color: context.colors.textTertiary,
            fontSize: 14,
          ),
          prefixIcon: IconButton(
            tooltip: context.l10n.search,
            icon: Icon(
              Icons.search_rounded,
              color: context.colors.textSecondary,
            ),
            onPressed: () => onSubmitted(controller.text),
          ),
          suffixIcon: isSearching
              ? Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.primaryContent,
                    ),
                  ),
                )
              : ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => controller.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: context.colors.textTertiary,
                            size: 18,
                          ),
                          onPressed: onClear,
                        ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppConstants.paddingM,
          ),
        ),
      ),
    );
  }
}
