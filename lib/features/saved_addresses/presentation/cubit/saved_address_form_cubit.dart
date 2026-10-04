import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/saved_addresses/data/models/saved_address_model.dart';
import '../../../../core/saved_addresses/data/repositories/saved_addresses_repository.dart';
import '../../../../core/saved_addresses/presentation/cubit/saved_addresses_cubit.dart';
import 'saved_address_form_state.dart';

/// Adds or edits one saved place. A new address goes through
/// `POST /saved-addresses`, an edit sends only what changed through
/// `PUT /saved-addresses/{id}`; either way the shared
/// [SavedAddressesCubit] gets the result so every screen shows it.
class SavedAddressFormCubit extends Cubit<SavedAddressFormState> {
  final SavedAddressesRepository _repository;
  final SavedAddressesCubit _savedAddresses;
  final SavedAddressType type;
  final SavedAddressModel? existing;

  SavedAddressFormCubit(
    this._repository,
    this._savedAddresses, {
    required this.type,
    this.existing,
  }) : super(SavedAddressFormState(location: existing?.toPickedLocation()));

  void setLocation(PickedLocationModel location) {
    if (!isClosed) emit(state.copyWith(location: location, clearErrors: true));
  }

  /// [label] is only sent for an `other` place.
  Future<void> save({String? label}) async {
    final location = state.location;
    if (isClosed || state.isSaving || location == null) return;
    final trimmedLabel = type == SavedAddressType.other ? _textOrNull(label) : null;

    emit(state.copyWith(status: SavedAddressFormStatus.saving, clearErrors: true));
    try {
      final current = existing;
      if (current == null) {
        final result = await _repository.create(
          type: type,
          label: trimmedLabel,
          lat: location.latitude,
          lng: location.longitude,
          address: _textOrNull(location.address),
          addressDetails: _textOrNull(location.addressDetails),
        );
        _savedAddresses.upsert(result.address);
        if (!isClosed) {
          emit(state.copyWith(
            status: SavedAddressFormStatus.saved,
            replaced: result.replaced,
          ));
        }
        return;
      }

      final changes = _changes(current, location, trimmedLabel);
      if (changes.isNotEmpty) {
        _savedAddresses.upsert(await _repository.update(current.id, changes));
      }
      if (!isClosed) emit(state.copyWith(status: SavedAddressFormStatus.saved));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: SavedAddressFormStatus.editing,
        errorMessage: e.message,
        fieldErrors: e.fieldErrors,
      ));
    }
  }

  Map<String, dynamic> _changes(
    SavedAddressModel current,
    PickedLocationModel location,
    String? label,
  ) {
    final address = _textOrNull(location.address);
    final details = _textOrNull(location.addressDetails);
    return {
      if (location.latitude != current.lat || location.longitude != current.lng) ...{
        'lat': location.latitude,
        'lng': location.longitude,
      },
      if (address != current.address) 'address': address,
      if (details != current.addressDetails) 'address_details': details,
      if (type == SavedAddressType.other && label != current.label) 'label': label,
    };
  }

  static String? _textOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
