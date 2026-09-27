import 'package:equatable/equatable.dart';
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
    return const FavoritesState(
      addresses: [
        FavoriteAddressModel(
          id: 'home',
          name: 'المنزل',
          address: 'حي العليا، شارع الأمير سلطان، فيلا 14، الرياض',
          note: 'البوابة الجانبية الرمادية',
          type: FavoritePlaceType.home,
          isDefault: true,
        ),
        FavoriteAddressModel(
          id: 'work',
          name: 'العمل',
          address: 'برج المملكة، طريق الملك فهد، الرياض',
          note: 'موقف قبو P2',
          type: FavoritePlaceType.work,
        ),
        FavoriteAddressModel(
          id: 'gym',
          name: 'النادي الرياضي',
          address: 'حي الملقا، شارع أنس بن مالك، الرياض',
          type: FavoritePlaceType.gym,
        ),
        FavoriteAddressModel(
          id: 'mom',
          name: 'بيت الوالدة',
          address: 'حي الياسمين، شارع التخصصي، الرياض',
          type: FavoritePlaceType.family,
        ),
      ],
      currentAreaLabel: 'مجمع السدرة، الرياض',
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
