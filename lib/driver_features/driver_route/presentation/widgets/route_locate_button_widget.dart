import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Round "locate me" button over the route map: tapping it finds the
/// driver and centres the map on the yellow pin.
class RouteLocateButtonWidget extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const RouteLocateButtonWidget({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutralPage,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: AppColors.shadowMedium,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isLoading ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
        ),
      ),
    );
  }
}
