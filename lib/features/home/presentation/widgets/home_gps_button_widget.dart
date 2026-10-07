import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';

/// The square GPS button next to the home search bar. Shows a spinner while
/// a fix is being found; `null` [onTap] disables it.
class HomeGpsButtonWidget extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const HomeGpsButtonWidget({
    super.key,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.useMyLocation;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: AppColors.neutralSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: isLoading ? null : onTap,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            ),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
