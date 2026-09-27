import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Side-by-side payment method and captain note action cards.
class PaymentAndNotesWidget extends StatelessWidget {
  final String paymentMethod;
  final double walletBalance;
  final String? captainNote;
  final VoidCallback? onPaymentTap;
  final VoidCallback? onNoteTap;

  const PaymentAndNotesWidget({
    super.key,
    required this.paymentMethod,
    required this.walletBalance,
    this.captainNote,
    this.onPaymentTap,
    this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'طريقة الدفع',
            subtitle:
                '$paymentMethod (${walletBalance.toStringAsFixed(0)} ر.س)',
            onTap: onPaymentTap,
            showChevron: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'ملاحظة للكابتن',
            subtitle: captainNote ?? 'أضف ملاحظة...',
            onTap: onNoteTap,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.backgroundMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}
