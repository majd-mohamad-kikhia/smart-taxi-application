import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/localization/l10n_context_extension.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/open_external_url.dart';
import '../../../../core/widgets/app_snack_bar_widget.dart';

/// Two tonal buttons side by side under the driver: call the driver (opens
/// the phone's dialer) and contact us. With no phone number for the driver
/// only "Contact us" is shown, full width.
class RideContactActionsWidget extends StatelessWidget {
  final String driverPhone;

  const RideContactActionsWidget({super.key, required this.driverPhone});

  Future<void> _call(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = context.l10n.callNotAvailable;
    final opened = await openExternalUrl('tel:$driverPhone');
    if (!opened) {
      showAppSnackBarOn(messenger, failure, type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasPhone = driverPhone.trim().isNotEmpty;
    return Row(
      children: [
        if (hasPhone) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _call(context),
              icon: const Icon(Icons.call_rounded, size: 18),
              label: Text(l10n.callDriver, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(
              AppRouter.contactUs,
              arguments: UserRole.customer,
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: context.colors.backgroundMuted,
              foregroundColor: context.colors.textPrimary,
            ),
            icon: const Icon(Icons.support_agent_rounded, size: 18),
            label: Text(l10n.contactUs, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}
