import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/network_photo_widget.dart';
import '../../../driver_auth/data/models/driver_status.dart';
import '../../../driver_auth/data/models/driver_user_model.dart';

/// The top of the profile: photo, name and account status. The status is an
/// icon and a word on its wash, and a status that needs the driver to do
/// something (under review, suspended, rejected) says what it means in a line
/// below, so it is never a mystery why trips aren't coming.
class ProfileHeaderWidget extends StatelessWidget {
  final DriverUserModel driver;

  const ProfileHeaderWidget({super.key, required this.driver});

  IconData get _icon => switch (driver.status) {
    DriverStatus.active => Icons.check_circle_rounded,
    DriverStatus.pending => Icons.schedule_rounded,
    DriverStatus.suspended => Icons.pause_circle_rounded,
    DriverStatus.rejected => Icons.cancel_rounded,
  };

  Color get _color => switch (driver.status) {
    DriverStatus.active => AppColors.success,
    DriverStatus.pending => AppColors.accent,
    DriverStatus.suspended || DriverStatus.rejected => AppColors.error,
  };

  Color get _wash => switch (driver.status) {
    DriverStatus.active => AppColors.successSurface,
    DriverStatus.pending => AppColors.accentSurface,
    DriverStatus.suspended || DriverStatus.rejected => AppColors.errorSurface,
  };

  String? _note(BuildContext context) {
    final l10n = context.l10n;
    return switch (driver.status) {
      DriverStatus.active => null,
      DriverStatus.pending => l10n.errAccountPending,
      DriverStatus.suspended => l10n.errAccountSuspended,
      DriverStatus.rejected => l10n.profileStatusRejectedNote,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final note = _note(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NetworkPhotoWidget(
                imagePath: driver.photoUrl,
                width: 72,
                height: 72,
                borderRadius: 36,
                placeholderIcon: Icons.person_rounded,
              ),
              const SizedBox(width: AppConstants.paddingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.fullName, style: textTheme.headlineSmall),
                    const SizedBox(height: AppConstants.paddingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingM,
                        vertical: AppConstants.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: _wash,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusFull,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_icon, size: 14, color: _color),
                          const SizedBox(width: AppConstants.paddingXS),
                          Flexible(
                            child: Text(
                              driver.status.label(l10n),
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: AppConstants.paddingM),
            Semantics(
              liveRegion: true,
              child: Text(note, style: textTheme.bodyMedium),
            ),
          ],
        ],
      ),
    );
  }
}
