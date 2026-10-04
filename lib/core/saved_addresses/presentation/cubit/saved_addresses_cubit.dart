import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../network/api_exception.dart';
import '../../data/models/saved_address_model.dart';
import '../../data/repositories/saved_addresses_repository.dart';
import 'saved_addresses_state.dart';

/// The signed-in customer's saved places, shared by the order screen's
/// quick chips and the "Saved places" screen — one singleton (see
/// injection.dart), so an edit on one shows on the other at once. Loaded
/// when a customer signs in, cleared on logout.
class SavedAddressesCubit extends Cubit<SavedAddressesState> {
  final SavedAddressesRepository _repository;

  SavedAddressesCubit(this._repository) : super(const SavedAddressesState());

  Future<void> load() async {
    if (isClosed || state.isLoading) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final addresses = await _repository.getAll();
      if (isClosed) return;
      emit(state.copyWith(
        addresses: _sorted(addresses),
        isLoading: false,
        isLoaded: true,
      ));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  void clear() {
    if (!isClosed) emit(const SavedAddressesState());
  }

  /// Puts a created or edited address in the list. A home / work replaces
  /// the old one of its type, as the server did.
  void upsert(SavedAddressModel address) {
    if (isClosed) return;
    final keepsOthers = state.addresses.where((a) {
      if (a.id == address.id) return false;
      return address.type == SavedAddressType.other || a.type != address.type;
    });
    emit(state.copyWith(addresses: _sorted([...keepsOthers, address])));
  }

  /// Returns the server's message on failure, null on success.
  Future<String?> delete(int id) async {
    if (isClosed || state.deletingId != null) return null;
    emit(state.copyWith(deletingId: id));
    try {
      await _repository.delete(id);
      if (isClosed) return null;
      emit(state.copyWith(
        addresses: state.addresses.where((a) => a.id != id).toList(),
        clearDeleting: true,
      ));
      return null;
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(clearDeleting: true));
      return e.message;
    }
  }

  static List<SavedAddressModel> _sorted(List<SavedAddressModel> addresses) {
    int rank(SavedAddressModel a) => a.type.index;
    final indexed = addresses.asMap().entries.toList()
      ..sort((x, y) {
        final byType = rank(x.value).compareTo(rank(y.value));
        return byType != 0 ? byType : x.key.compareTo(y.key);
      });
    return [for (final entry in indexed) entry.value];
  }
}
