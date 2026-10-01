import 'package:flutter/material.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../widgets/auth_primary_button_widget.dart';

/// "Try again" button that shows a spinner while [onRetry] runs.
class AppVersionRetryButtonWidget extends StatefulWidget {
  final Future<void> Function() onRetry;

  const AppVersionRetryButtonWidget({super.key, required this.onRetry});

  @override
  State<AppVersionRetryButtonWidget> createState() =>
      _AppVersionRetryButtonWidgetState();
}

class _AppVersionRetryButtonWidgetState
    extends State<AppVersionRetryButtonWidget> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPrimaryButtonWidget(
      label: context.l10n.retry,
      isLoading: _isRetrying,
      onPressed: _retry,
    );
  }
}
