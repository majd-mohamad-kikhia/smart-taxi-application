import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/services/photo_picker_service.dart';
import '../../../../core/theme/app_colors.dart';

/// One photo of the signup form: shows the chosen image (or a prompt) and,
/// on tap, offers the camera or the gallery. [error] is shown under it.
class SignupPhotoTileWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? photoPath;
  final String? error;
  final ValueChanged<PhotoSource> onPick;

  const SignupPhotoTileWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.photoPath,
    required this.error,
    required this.onPick,
  });

  Future<void> _choose(BuildContext context) async {
    final l10n = context.l10n;
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.driverSignupPhotoCamera),
              onTap: () => Navigator.of(sheet).pop(PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.driverSignupPhotoGallery),
              onTap: () => Navigator.of(sheet).pop(PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) onPick(source);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppConstants.radiusLarge);
    final path = photoPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: label,
          child: Material(
            color: AppColors.backgroundWhite,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: error == null ? AppColors.border : AppColors.error),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _choose(context),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: path == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 32, color: AppColors.textSecondary),
                          const SizedBox(height: AppConstants.paddingS),
                          Text(label, style: textTheme.titleSmall),
                          Text(
                            l10n.driverSignupPhotoAdd,
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      )
                    : Image.file(File(path), fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.paddingXS),
            child: Text(
              error!,
              style: textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
