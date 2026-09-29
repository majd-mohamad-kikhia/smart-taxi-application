import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/models/favorite_address_model.dart';
import 'favorites_state.dart';

/// Cubit managing the Favorite Addresses screen state.
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit() : super(FavoritesState.initial());

  void initialize() {
    if (!isClosed) emit(FavoritesState.initial());
  }

  void deleteAddress(String id) {
    if (isClosed) return;
    final updated =
        state.addresses.where((address) => address.id != id).toList();
    emit(state.copyWith(addresses: updated, deletedId: id));
  }

  void clearDeletedFlag() {
    if (isClosed) return;
    emit(state.copyWith(clearDeletedId: true));
  }

  Future<void> saveCurrentLocation() async {
    if (isClosed || state.isSavingCurrent) return;
    emit(state.copyWith(isSavingCurrent: true));

    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (isClosed) return;

    final newPlace = FavoriteAddressModel(
      id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
      name: AppStrings.current.favMyCurrentLocation,
      address: state.currentAreaLabel,
      type: FavoritePlaceType.custom,
    );

    emit(
      state.copyWith(
        isSavingCurrent: false,
        addresses: [...state.addresses, newPlace],
      ),
    );
  }

  void sortByName() {
    if (isClosed) return;
    final sorted = [...state.addresses]
      ..sort((a, b) => a.name.compareTo(b.name));
    emit(state.copyWith(addresses: sorted));
  }
}
