import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../features/home/presentation/widgets/home_app_bar_widget.dart';

/// Temporary placeholder shown for the Wallet tab until the
/// feature is implemented.
class WalletPlaceholderWidget extends StatelessWidget {
  const WalletPlaceholderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: HomeAppBarWidget(),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: 12),
            Text(
              'المحفظة قريباً',
              style: TextStyle(
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
