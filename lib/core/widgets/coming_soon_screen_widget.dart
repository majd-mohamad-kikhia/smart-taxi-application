import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../theme/app_colors.dart';
import '../../features/home/presentation/widgets/home_app_bar_widget.dart';

/// Generic placeholder screen shown for features that are not yet available.
class ComingSoonScreenWidget extends StatelessWidget {
  final String label;
  final IconData icon;

  const ComingSoonScreenWidget({
    super.key,
    required this.label,
    this.icon = Icons.hourglass_empty_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: HomeAppBarWidget(),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              context.l10n.comingSoon(label),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
