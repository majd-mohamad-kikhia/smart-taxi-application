import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/auth_primary_button_widget.dart';
import '../cubit/app_version_cubit.dart';

/// The maintenance screen's "Try again": it shows a spinner while it asks and
/// then says what it found, still under maintenance or no connection.
/// Without that the button would do something and show nothing, and "still
/// down" would look the same as "couldn't ask".
class MaintenanceRecheckButtonWidget extends StatefulWidget {
  final Future<AppVersionRecheckResult> Function() onRecheck;

  const MaintenanceRecheckButtonWidget({super.key, required this.onRecheck});

  @override
  State<MaintenanceRecheckButtonWidget> createState() =>
      _MaintenanceRecheckButtonWidgetState();
}

class _MaintenanceRecheckButtonWidgetState
    extends State<MaintenanceRecheckButtonWidget> {
  bool _isRetrying = false;
  AppVersionRecheckResult? _result;

  Future<void> _retry() async {
    setState(() {
      _isRetrying = true;
      _result = null;
    });
    final result = await widget.onRecheck();
    if (mounted) {
      setState(() {
        _isRetrying = false;
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = _result;
    final message = switch (result) {
      AppVersionRecheckResult.stillDown => l10n.appMaintenanceStillDown,
      AppVersionRecheckResult.noConnection => l10n.errNoInternet,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message != null) ...[
          Semantics(
            liveRegion: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  result == AppVersionRecheckResult.noConnection
                      ? Icons.wifi_off_rounded
                      : Icons.build_circle_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppConstants.paddingS),
                Flexible(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
        ],
        AuthPrimaryButtonWidget(
          label: l10n.retry,
          isLoading: _isRetrying,
          onPressed: _retry,
        ),
      ],
    );
  }
}
