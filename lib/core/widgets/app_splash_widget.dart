import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import 'app_logo_widget.dart';

/// The app's splash while it starts up: the logo on the same black as the
/// native splash it replaces (so there is no visible jump), the brand
/// slogan under it. It shows for as long as the startup work (restoring the
/// session, the version check) takes. The slogan is the same in every language, so it needs no
/// localization.
class AppSplashWidget extends StatelessWidget {
  static const double _logoSize = 144;
  static const double _sloganBoxHeight = 56;

  const AppSplashWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.black,
      child: Stack(
        children: [
          // An empty box above the logo as tall as the slogan's below it
          // keeps the logo dead center, where the native splash drew it.
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: _sloganBoxHeight),
                const AppLogoWidget(size: _logoSize),
                SizedBox(
                  height: _sloganBoxHeight,
                  child: Center(
                    child: Text(
                      AppConstants.appSlogan,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
