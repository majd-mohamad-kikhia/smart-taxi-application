import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_palette.dart';

/// What the search tells the customer when it found nothing (or could not
/// look): a short message above the card, e.g. to place the pin by hand.
class PlaceSearchMessageWidget extends StatelessWidget {
  final String message;

  const PlaceSearchMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: context.colors.neutralSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: context.colors.border),
      ),
      child: Text(
        message,
        style: TextStyle(color: context.colors.errorText, fontSize: 13),
      ),
    );
  }
}
