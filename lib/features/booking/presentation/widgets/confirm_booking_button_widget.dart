import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Primary CTA to confirm the selected ride category booking.
class ConfirmBookingButtonWidget extends StatelessWidget {
  final String categoryName;
  final double price;
  final bool isLoading;
  final VoidCallback? onConfirm;

  const ConfirmBookingButtonWidget({
    super.key,
    required this.categoryName,
    required this.price,
    required this.isLoading,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Trust badges
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 13, color: AppColors.success),
            SizedBox(width: 4),
            Text(
              'كبائن معتمدون ومرخصون',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            SizedBox(width: 12),
            Icon(Icons.bolt_rounded, size: 13, color: AppColors.primary),
            SizedBox(width: 4),
            Text(
              'تأكيد ومطابقة فورية',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Confirm button
        GestureDetector(
          onTap: isLoading ? null : onConfirm,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isLoading
                  ? AppColors.primary.withValues(alpha: 0.7)
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowStrong,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      const Icon(
                        Icons.directions_car_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'تأكيد طلب مشوار $categoryName',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${price.toStringAsFixed(0)} ر.س',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        // Legal footer
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
              height: 1.4,
            ),
            children: const [
              TextSpan(text: 'بالضغط على تأكيد، أنت توافق على '),
              TextSpan(
                text: 'شروط الخدمة',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(text: ' و'),
              TextSpan(
                text: 'سياسة الخصوصية',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(text: ' لمشوار'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
