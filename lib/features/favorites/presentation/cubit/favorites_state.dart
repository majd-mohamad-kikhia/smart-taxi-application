import 'package:equatable/equatable.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/models/favorite_address_model.dart';

/// Immutable state for the Favorite Addresses screen.
class FavoritesState extends Equatable {
  final List<FavoriteAddressModel> addresses;
  final String currentAreaLabel;
  final bool isSavingCurrent;
  final String? deletedId;

  const FavoritesState({
    required this.addresses,
    required this.currentAreaLabel,
    required this.isSavingCurrent,
    this.deletedId,
  });

  int get count => addresses.length;

  factory FavoritesState.initial() {
    // Sample data, worded in the language active when the state is created.
    final l10n = AppStrings.current;
    return FavoritesState(
      addresses: [
        FavoriteAddressModel(
          id: 'home',
          name: l10n.favMockHomeName,
          address: l10n.favMockHomeAddress,
          note: l10n.favMockHomeNote,
          type: FavoritePlaceType.home,
          isDefault: true,
        ),
        FavoriteAddressModel(
          id: 'work',
          name: l10n.favMockWorkName,
          address: l10n.favMockWorkAddress,
          note: l10n.favMockWorkNote,
          type: FavoritePlaceType.work,
        ),
        FavoriteAddressModel(
          id: 'gym',
          name: l10n.favMockGymName,
          address: l10n.favMockGymAddress,
          type: FavoritePlaceType.gym,
        ),
        FavoriteAddressModel(
          id: 'mom',
          name: l10n.favMockMomName,
          address: l10n.favMockMomAddress,
          type: FavoritePlaceType.family,
        ),
      ],
      currentAreaLabel: l10n.favMockCurrentArea,
      isSavingCurrent: false,
    );
  }

  FavoritesState copyWith({
    List<FavoriteAddressModel>? addresses,
    String? currentAreaLabel,
    bool? isSavingCurrent,
    String? deletedId,
    bool clearDeletedId = false,
  }) {
    return FavoritesState(
      addresses: addresses ?? this.addresses,
      currentAreaLabel: currentAreaLabel ?? this.currentAreaLabel,
      isSavingCurrent: isSavingCurrent ?? this.isSavingCurrent,
      deletedId: clearDeletedId ? null : (deletedId ?? this.deletedId),
    );
  }

  @override
  List<Object?> get props =>
      [addresses, currentAreaLabel, isSavingCurrent, deletedId];
}
