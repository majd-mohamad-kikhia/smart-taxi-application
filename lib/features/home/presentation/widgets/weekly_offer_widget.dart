import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/offer_model.dart';

/// Rich promotional banner card with a discount offer and promo code.
/// Uses the primary gradient background with an illustration placeholder.
class WeeklyOfferWidget extends StatelessWidget {
  final OfferModel offer;
  final VoidCallback? onApplyTapped;

  const WeeklyOfferWidget({
    super.key,
    required this.offer,
    this.onApplyTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowStrong,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Decorative circles ─────────────────────
            Positioned(
              top: -20,
              left: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              right: -10,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            // ── Content ────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(child: _OfferTextColumn(offer: offer, onApplyTapped: onApplyTapped)),
                  const SizedBox(width: 12),
                  _OfferIllustration(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferTextColumn extends StatelessWidget {
  final OfferModel offer;
  final VoidCallback? onApplyTapped;

  const _OfferTextColumn({required this.offer, this.onApplyTapped});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Badge ──────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎫', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              Text(
                offer.badgeLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ── Title ──────────────────────────────────
        Text(
          offer.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        // ── Description ────────────────────────────
        Text(
          offer.description,
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.white.withValues(alpha: 0.8),
            height: 1.4,
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 14),
        // ── Promo Code + Apply Button ───────────────
        Row(
          children: [
            // Promo code chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                offer.promoCode,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Apply button
            GestureDetector(
              onTap: onApplyTapped,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'تطبيق',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Placeholder illustration on the right side of the offer banner.
class _OfferIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_car_rounded,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 4),
          Text(
            '20%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
