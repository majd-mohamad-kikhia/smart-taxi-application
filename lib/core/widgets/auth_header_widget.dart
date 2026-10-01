import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'app_logo_widget.dart';

class AuthHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppLogoWidget(size: 84),
        const SizedBox(height: AppConstants.paddingL),
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: AppConstants.paddingXS),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
