import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/place_accent.dart';
import '../data/models/saved_address_model.dart';
import '../data/models/saved_place_preset.dart';

extension SavedAddressTypeUi on SavedAddressType {
  IconData get icon => switch (this) {
        SavedAddressType.home => Icons.home_rounded,
        SavedAddressType.work => Icons.work_rounded,
        SavedAddressType.other => Icons.place_rounded,
      };

  PlaceAccent get accent => switch (this) {
        SavedAddressType.home => PlaceAccent.home,
        SavedAddressType.work => PlaceAccent.work,
        SavedAddressType.other => PlaceAccent.custom,
      };

  String name(AppLocalizations l10n) => switch (this) {
        SavedAddressType.home => l10n.savedAddressHome,
        SavedAddressType.work => l10n.savedAddressWork,
        SavedAddressType.other => l10n.savedAddressOther,
      };
}

extension SavedPlacePresetUi on SavedPlacePreset {
  IconData get icon => switch (this) {
        SavedPlacePreset.gym => Icons.fitness_center_rounded,
        SavedPlacePreset.school => Icons.school_rounded,
        SavedPlacePreset.university => Icons.account_balance_rounded,
        SavedPlacePreset.family => Icons.family_restroom_rounded,
      };

  PlaceAccent get accent => switch (this) {
        SavedPlacePreset.gym => PlaceAccent.gym,
        SavedPlacePreset.school => PlaceAccent.school,
        SavedPlacePreset.university => PlaceAccent.university,
        SavedPlacePreset.family => PlaceAccent.family,
      };

  String name(AppLocalizations l10n) => switch (this) {
        SavedPlacePreset.gym => l10n.savedPlaceGym,
        SavedPlacePreset.school => l10n.savedPlaceSchool,
        SavedPlacePreset.university => l10n.savedPlaceUniversity,
        SavedPlacePreset.family => l10n.savedPlaceFamily,
      };
}

/// Each preset's name in every supported language: a place saved while the
/// app was in Arabic is still recognised after switching to English.
final Map<SavedPlacePreset, Set<String>> _presetNames = {
  for (final preset in SavedPlacePreset.values)
    preset: {
      for (final locale in AppLocalizations.supportedLocales)
        preset.name(lookupAppLocalizations(locale)).toLowerCase(),
    },
};

extension SavedAddressUi on SavedAddressModel {
  /// The preset this `other` place was saved as, matched by its label.
  SavedPlacePreset? get preset {
    final custom = label?.trim().toLowerCase();
    if (type != SavedAddressType.other || custom == null) return null;
    for (final entry in _presetNames.entries) {
      if (entry.value.contains(custom)) return entry.key;
    }
    return null;
  }

  IconData get icon => preset?.icon ?? type.icon;

  PlaceAccent get accent => preset?.accent ?? type.accent;

  /// A preset in the app's language, else the customer's own label, else
  /// "Home" / "Work".
  String title(AppLocalizations l10n) {
    final preset = this.preset;
    if (preset != null) return preset.name(l10n);
    final custom = label?.trim();
    return custom != null && custom.isNotEmpty ? custom : type.name(l10n);
  }
}
