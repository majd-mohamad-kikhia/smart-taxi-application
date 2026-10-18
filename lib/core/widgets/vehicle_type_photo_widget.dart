import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../theme/app_palette.dart';
import 'vehicle_type_icon_widget.dart';

/// The picture of a car type (`image_url`, a path on the server) in a rounded
/// frame. While it loads, when it can't be loaded, and when the type has no
/// picture, the frame shows the icon that fits the type's [name] on a soft
/// wash instead, so a card never has a hole in it.
///
/// Pictures are fetched through Flutter's image cache, keyed by their
/// address: the same car shown in the price list and again in its details
/// is downloaded once while the app runs.
class VehicleTypePhotoWidget extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final double iconSize;

  /// The fill behind the icon; defaults to the muted surface.
  final Color? background;

  const VehicleTypePhotoWidget({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.iconSize = 30,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final url = ApiClient.resolveMediaUrl(imageUrl);
    final fallback = Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: background ?? context.colors.backgroundMuted,
      child: Icon(
        VehicleTypeIconWidget.iconFor(name),
        size: iconSize,
        color: context.colors.primaryContent,
      ),
    );
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: url == null
            ? fallback
            : Image.network(
                url,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : fallback,
              ),
      ),
    );
  }
}
