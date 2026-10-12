import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';

/// Round "locate me" button over the route map: tapping it finds the
/// driver and centres the map on the green pin.
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
      color: context.colors.neutralPage,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: context.colors.shadowMedium,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isLoading ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.primaryContent,
                  ),
                )
              : Icon(
                  Icons.my_location_rounded,
                  color: context.colors.primaryContent,
                  size: 22,
                ),
        ),
      ),
    );
  }
}
