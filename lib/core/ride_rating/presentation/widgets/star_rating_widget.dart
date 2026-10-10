import 'package:flutter/material.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../theme/app_colors.dart';

/// Five stars. Read-only when [onChanged] is null; otherwise tapping a star
/// picks that many. [value] is 0–5 (a fraction, like an average, fills the
/// nearest half star).
class StarRatingWidget extends StatelessWidget {
  static const int starCount = 5;

  final double value;
  final double size;
  final ValueChanged<int>? onChanged;

  /// A face under each star, from very sad (1) to very happy (5). The face
  /// of the picked star is highlighted.
  final bool showFaces;

  const StarRatingWidget({
    super.key,
    required this.value,
    this.size = 20,
    this.onChanged,
    this.showFaces = false,
  });

  static const _faces = [
    Icons.sentiment_very_dissatisfied_rounded,
    Icons.sentiment_dissatisfied_rounded,
    Icons.sentiment_neutral_rounded,
    Icons.sentiment_satisfied_rounded,
    Icons.sentiment_very_satisfied_rounded,
  ];

  IconData _iconFor(int star) {
    if (value >= star - 0.25) return Icons.star_rounded;
    if (value >= star - 0.75) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final stars = [
      for (var star = 1; star <= starCount; star++)
        _Star(
          icon: _iconFor(star),
          size: size,
          face: showFaces ? _faces[star - 1] : null,
          faceSelected: value.round() == star,
          label: context.l10n.starsOutOfFive(star),
          onTap: onChanged == null ? null : () => onChanged!(star),
        ),
    ];
    final row = Row(mainAxisSize: MainAxisSize.min, children: stars);
    if (onChanged != null) return row;
    return Semantics(
      label: context.l10n.starsOutOfFive(value.round()),
      child: ExcludeSemantics(child: row),
    );
  }
}

class _Star extends StatelessWidget {
  final IconData icon;
  final double size;
  final IconData? face;
  final bool faceSelected;
  final String label;
  final VoidCallback? onTap;

  const _Star({
    required this.icon,
    required this.size,
    required this.face,
    required this.faceSelected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final starIcon = Icon(icon, size: size, color: AppColors.accent);
    final star = face == null
        ? starIcon
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              starIcon,
              const SizedBox(height: 2),
              AnimatedScale(
                scale: faceSelected ? 1.25 : 1,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  face,
                  size: size * 0.7,
                  color: faceSelected ? AppColors.accent : AppColors.textTertiary,
                ),
              ),
            ],
          );
    if (onTap == null) return star;
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: size,
        child: Padding(padding: const EdgeInsets.all(4), child: star),
      ),
    );
  }
}
