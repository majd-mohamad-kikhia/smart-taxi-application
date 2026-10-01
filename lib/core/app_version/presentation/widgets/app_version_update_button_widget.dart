import 'package:flutter/material.dart';
import '../../../localization/app_strings.dart';
import '../../../localization/l10n_context_extension.dart';
import '../../../utils/open_store.dart';
import '../../../widgets/app_snack_bar_widget.dart';
import '../../../widgets/auth_primary_button_widget.dart';

/// Full-width "Update" button that opens the store page ([storeUrl], else the
/// built-in link).
class AppVersionUpdateButtonWidget extends StatelessWidget {
  final String? storeUrl;

  const AppVersionUpdateButtonWidget({super.key, required this.storeUrl});

  /// Opens the store and tells the user through [messenger] when nothing
  /// could. Takes the messenger (not a context) so callers may use it after
  /// the widget that started it is gone.
  static Future<void> launch(
    ScaffoldMessengerState messenger,
    String? storeUrl,
  ) async {
    final opened = await openStore(storeUrl);
    if (!opened) {
      showAppSnackBarOn(
        messenger,
        AppStrings.current.appUpdateStoreFailed,
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPrimaryButtonWidget(
      label: context.l10n.appUpdateAction,
      isLoading: false,
      onPressed: () => launch(ScaffoldMessenger.of(context), storeUrl),
    );
  }
}
