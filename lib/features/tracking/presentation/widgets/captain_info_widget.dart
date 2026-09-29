import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/captain_model.dart';

/// Driver photo, name, rating, vehicle info and Saudi license plate.
class CaptainInfoWidget extends StatelessWidget {
  final CaptainModel captain;

  const CaptainInfoWidget({super.key, required this.captain});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // License plate
        _SaudiPlate(
          number: captain.plateNumber,
          letters: captain.plateLetters,
        ),
        const SizedBox(width: 12),
        // Captain details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      captain.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (captain.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.success,
                      size: 16,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                captain.tripsLabel(context.l10n),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                captain.vehicleLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Avatar + rating
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundMuted,
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.textSecondary,
                size: 30,
              ),
            ),
            Positioned(
              bottom: -4,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        captain.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.star_rounded, color: Colors.white, size: 10),
                    ],
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

/// Simplified Saudi Arabia license plate graphic.
class _SaudiPlate extends StatelessWidget {
  final String number;
  final String letters;

  const _SaudiPlate({required this.number, required this.letters});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.textPrimary, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
              ),
              Container(width: 1, height: 16, color: AppColors.textPrimary),
              Expanded(
                child: Text(
                  letters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 1),
            color: AppColors.primary,
            child: const Text(
              'KSA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
