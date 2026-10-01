import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_loader_widget.dart';
import 'app_logo_widget.dart';

/// The app's splash while it starts up: the logo on the same black as the
/// native splash it replaces (so there is no visible jump), with the taxi
/// loading animation under it. It shows for as long as the startup work
/// (restoring the session, the version check) takes, and carries no text, so
/// it needs no localization.
class AppSplashWidget extends StatelessWidget {
  const AppSplashWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.black,
      child: Stack(
        children: [
          Center(child: AppLogoWidget(size: 144)),
          // A fixed box: the loader centers itself in whatever space it is
          // given, so without one it would fill the screen and sit on the
          // logo instead of under it.
          Align(
            alignment: Alignment(0, 0.62),
            child: SizedBox(
              width: 140,
              height: 140,
              child: AppLoaderWidget(size: 140),
            ),
          ),
        ],
      ),
    );
  }
}
