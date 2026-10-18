import 'package:flutter/material.dart';
import '../../../../core/services/photo_picker_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/photo_source_sheet.dart';

/// Makes the photo in [child] changeable: a small camera badge in its corner,
/// and a tap offers the camera or the gallery. While [isUploading] the photo
/// is dimmed under a spinner and ignores taps. [borderRadius] must match the
/// photo's so the dimming follows its shape (a circle: half its size).
class EditablePhotoWidget extends StatelessWidget {
  final Widget child;
  final bool isUploading;
  final double borderRadius;
  final String semanticLabel;
  final ValueChanged<PhotoSource> onPick;

  const EditablePhotoWidget({
    super.key,
    required this.child,
    required this.isUploading,
    required this.borderRadius,
    required this.semanticLabel,
    required this.onPick,
  });

  Future<void> _choose(BuildContext context) async {
    final source = await showPhotoSourceSheet(context);
    if (source != null) onPick(source);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      enabled: !isUploading,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: isUploading ? null : () => _choose(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (isUploading)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    color: colors.backgroundWhite.withValues(alpha: 0.7),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            PositionedDirectional(
              end: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primaryContent,
                  border: Border.all(color: colors.backgroundWhite, width: 2),
                ),
                child: Icon(
                  Icons.photo_camera_rounded,
                  size: 14,
                  color: colors.backgroundWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
