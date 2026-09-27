import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Banner shown below the map indicating the nearest available captain.
/// Features a pulsing orange status dot and estimated arrival time.
class NearestCaptainBannerWidget extends StatelessWidget {
  final int minutesAway;
  final bool isAvailable;

  const NearestCaptainBannerWidget({
    super.key,
    required this.minutesAway,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // ── Status dot ──────────────────────────────────
          _PulsingDot(active: isAvailable),
          const SizedBox(width: 10),
          // ── Message ─────────────────────────────────────
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
                children: [
                  const TextSpan(
                    text: 'أقرب كابتن بعد ',
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                  TextSpan(
                    text: '$minutesAway دقيقتين',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const TextSpan(
                    text: ' فقط',
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated pulsing dot indicating live availability.
class _PulsingDot extends StatefulWidget {
  final bool active;
  const _PulsingDot({required this.active});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? AppColors.accent : AppColors.textTertiary;
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
