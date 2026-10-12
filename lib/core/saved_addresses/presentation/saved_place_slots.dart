import '../data/models/saved_address_model.dart';
import '../data/models/saved_place_preset.dart';
import 'saved_address_type_ui.dart';

/// A customer's saved places split into the fixed slots (home, work and the
/// ready-made places, each filled or not) and the places they named
/// themselves.
class SavedPlaceSlots {
  final SavedAddressModel? home;
  final SavedAddressModel? work;

  /// The first place saved as each preset; a second place with the same name
  /// stays in [custom].
  final Map<SavedPlacePreset, SavedAddressModel> presets;
  final List<SavedAddressModel> custom;

  const SavedPlaceSlots._({
    required this.home,
    required this.work,
    required this.presets,
    required this.custom,
  });

  factory SavedPlaceSlots.from(List<SavedAddressModel> addresses) {
    SavedAddressModel? home;
    SavedAddressModel? work;
    final presets = <SavedPlacePreset, SavedAddressModel>{};
    final custom = <SavedAddressModel>[];
    for (final address in addresses) {
      switch (address.type) {
        case SavedAddressType.home:
          home ??= address;
        case SavedAddressType.work:
          work ??= address;
        case SavedAddressType.other:
          final preset = address.preset;
          if (preset != null && !presets.containsKey(preset)) {
            presets[preset] = address;
          } else {
            custom.add(address);
          }
      }
    }
    return SavedPlaceSlots._(home: home, work: work, presets: presets, custom: custom);
  }
}
