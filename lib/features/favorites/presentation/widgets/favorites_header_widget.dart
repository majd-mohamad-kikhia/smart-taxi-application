import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Top bar for favorites: back + title + profile avatar.
class FavoritesHeaderWidget extends StatelessWidget {
  final VoidCallback? onBack;

  const FavoritesHeaderWidget({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundMuted,
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
            const Spacer(),
            const Text(
              'العناوين المفضلة',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.backgroundMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textPrimary,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
