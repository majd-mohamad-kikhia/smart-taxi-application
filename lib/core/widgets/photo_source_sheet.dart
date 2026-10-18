import 'package:flutter/material.dart';
import '../localization/l10n_context_extension.dart';
import '../services/photo_picker_service.dart';

/// Asks whether a photo comes from the camera or the gallery. Null when the
/// user closes the sheet.
Future<PhotoSource?> showPhotoSourceSheet(BuildContext context) {
  final l10n = context.l10n;
  return showModalBottomSheet<PhotoSource>(
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
}
