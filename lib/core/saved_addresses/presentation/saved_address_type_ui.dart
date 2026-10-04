import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../data/models/saved_address_model.dart';

extension SavedAddressTypeUi on SavedAddressType {
  IconData get icon => switch (this) {
        SavedAddressType.home => Icons.home_rounded,
        SavedAddressType.work => Icons.work_rounded,
        SavedAddressType.other => Icons.place_rounded,
      };

  String name(AppLocalizations l10n) => switch (this) {
        SavedAddressType.home => l10n.savedAddressHome,
        SavedAddressType.work => l10n.savedAddressWork,
        SavedAddressType.other => l10n.savedAddressOther,
      };
}

extension SavedAddressUi on SavedAddressModel {
  /// The customer's own label, else "Home" / "Work".
  String title(AppLocalizations l10n) {
    final custom = label?.trim();
    return custom != null && custom.isNotEmpty ? custom : type.name(l10n);
  }
}
