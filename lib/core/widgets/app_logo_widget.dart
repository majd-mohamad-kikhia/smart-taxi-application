import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// The Smart Taxi app logo as a rounded tile. The logo artwork has its own
/// dark background, so it is clipped to rounded corners rather than tinted.
class AppLogoWidget extends StatelessWidget {
  final double size;

  const AppLogoWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        AppConstants.logoPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      ),
    );
  }
}
