import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// The app's full-screen/full-section loading indicator — the taxi
/// animation at `assets/loader/taxi_loader_yellow.json`. Use for a standalone
/// loading state (a whole screen or a whole section); small inline
/// spinners (buttons, "load more" rows) keep the plain
/// `CircularProgressIndicator`.
class AppLoaderWidget extends StatelessWidget {
  final double size;

  const AppLoaderWidget({super.key, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/loader/taxi_loader_yellow.json',
        width: size,
        height: size,
      ),
    );
  }
}
