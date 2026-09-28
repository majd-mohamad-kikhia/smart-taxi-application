import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../theme/app_colors.dart';

/// Renders an image from a `photo_url`-style API path (relative or
/// absolute, resolved via [ApiClient.resolveMediaUrl]). Shows
/// [placeholderIcon] while there's no path, while it's loading, or if it
/// fails to load.
class NetworkPhotoWidget extends StatelessWidget {
  final String? imagePath;
  final double width;
  final double height;
  final double borderRadius;
  final IconData placeholderIcon;

  const NetworkPhotoWidget({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.placeholderIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final url = ApiClient.resolveMediaUrl(imagePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: url == null
          ? _placeholder()
          : Image.network(
              url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _placeholder(loading: true);
              },
            ),
    );
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      width: width,
      height: height,
      color: AppColors.backgroundGray,
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(placeholderIcon, color: AppColors.textSecondary),
    );
  }
}
