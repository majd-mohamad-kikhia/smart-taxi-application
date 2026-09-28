import 'package:flutter/material.dart';
import '../../../../core/widgets/app_brand_bar_widget.dart';

/// Rider app bar — the shared [AppBrandBarWidget] with notifications
/// enabled. Kept as its own file/name since it's already wired into five
/// call sites across the home/trips/settings features.
class HomeAppBarWidget extends StatelessWidget {
  const HomeAppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppBrandBarWidget(showNotifications: true);
  }
}
