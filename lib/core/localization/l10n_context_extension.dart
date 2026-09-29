import 'package:flutter/widgets.dart';
import '../l10n/generated/app_localizations.dart';

extension L10nContextExtension on BuildContext {
  /// The app's translated strings for the active locale.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
