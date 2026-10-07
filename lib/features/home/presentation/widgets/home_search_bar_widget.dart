import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';

/// The "search for a place" pill at the top of the home map. It is a button,
/// not a text field: tapping it opens the place picker, where the typing
/// happens. `null` [onTap] disables it.
class HomeSearchBarWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const HomeSearchBarWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hint = context.l10n.searchPlaceHint;
    return Semantics(
      button: true,
      label: hint,
      excludeSemantics: true,
      child: Material(
        color: AppColors.neutralSurface,
        shape: StadiumBorder(side: BorderSide(color: AppColors.border)),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingXL,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
