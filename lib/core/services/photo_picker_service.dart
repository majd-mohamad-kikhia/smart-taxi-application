import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Where a photo comes from.
enum PhotoSource { camera, gallery }

/// A photo the user chose. [tooLarge] when it is over
/// [PhotoPickerService.maxBytes] even after downscaling (the server refuses
/// it), so [path] must not be sent.
class PickedPhoto {
  final String path;
  final bool tooLarge;

  const PickedPhoto(this.path, {this.tooLarge = false});
}

/// Picks one photo from the camera or the gallery, downscaled, or null when
/// the user backed out or nothing could be opened. Wrapped so screens and
/// cubits never touch the plugin directly.
class PhotoPickerService {
  /// The server takes images up to 5 MB.
  static const int maxBytes = 5 * 1024 * 1024;

  final ImagePicker _picker;

  PhotoPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<PickedPhoto?> pick(PhotoSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null) return null;
      return PickedPhoto(file.path, tooLarge: await File(file.path).length() > maxBytes);
    } catch (e) {
      debugPrint('PhotoPickerService: could not pick a photo: $e');
      return null;
    }
  }
}
