import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Hero card at the top of the wallet statement — the driver's current
/// wallet balance.
class WalletStatementSummaryCardWidget extends StatelessWidget {
  final String amountOwed;

  const WalletStatementSummaryCardWidget({super.key, required this.amountOwed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            amountOwed,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
