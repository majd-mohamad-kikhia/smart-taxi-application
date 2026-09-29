import 'package:flutter/material.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/theme/app_colors.dart';

/// Call / Chat / Share action row for contacting the captain.
class TrackingActionsWidget extends StatelessWidget {
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final VoidCallback? onShare;

  const TrackingActionsWidget({
    super.key,
    this.onCall,
    this.onChat,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _ActionButton(
            label: context.l10n.actionCall,
            icon: Icons.phone_rounded,
            background: AppColors.primary,
            foreground: Colors.white,
            onTap: onCall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: _ActionButton(
            label: context.l10n.actionChat,
            icon: Icons.chat_bubble_outline_rounded,
            background: const Color(0xFFE8EEF8),
            foreground: AppColors.primary,
            onTap: onChat,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: _ActionButton(
            label: context.l10n.actionShare,
            icon: Icons.ios_share_rounded,
            background: const Color(0xFFE8EEF8),
            foreground: AppColors.primary,
            onTap: onShare,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
