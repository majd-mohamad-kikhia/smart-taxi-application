import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Places a dialog body in the middle of the screen: inside the safe area,
/// above the keyboard, and scrollable when it is taller than the space left,
/// so a focused text field is never hidden behind it.
class AppDialogLayoutWidget extends StatelessWidget {
  final Widget child;

  const AppDialogLayoutWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: AppConstants.animFast,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Center(child: SingleChildScrollView(child: child)),
      ),
    );
  }
}
