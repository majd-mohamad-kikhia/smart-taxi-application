import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Orange promo strip showing applied discount code and savings amount.
class PromoBannerWidget extends StatelessWidget {
  final String label;
  final double discountAmount;

  const PromoBannerWidget({
    super.key,
    required this.label,
    required this.discountAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_offer_rounded,
            color: AppColors.accent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.accentDark,
              ),
            ),
          ),
          Text(
            '-${discountAmount.toStringAsFixed(2)} ر.س',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
