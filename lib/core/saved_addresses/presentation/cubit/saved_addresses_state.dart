import 'package:equatable/equatable.dart';
import '../../data/models/saved_address_model.dart';

class SavedAddressesState extends Equatable {
  /// Home first, then work, then the others in the server's order.
  final List<SavedAddressModel> addresses;
  final bool isLoading;

  /// Set once the list has loaded at least once.
  final bool isLoaded;
  final String? errorMessage;

  /// The address whose delete is in flight.
  final int? deletingId;

  const SavedAddressesState({
    this.addresses = const [],
    this.isLoading = false,
    this.isLoaded = false,
    this.errorMessage,
    this.deletingId,
  });

  SavedAddressModel? ofType(SavedAddressType type) {
    for (final address in addresses) {
      if (address.type == type) return address;
    }
    return null;
  }

  List<SavedAddressModel> get others =>
      addresses.where((a) => a.type == SavedAddressType.other).toList();

  SavedAddressesState copyWith({
    List<SavedAddressModel>? addresses,
    bool? isLoading,
    bool? isLoaded,
    String? errorMessage,
    int? deletingId,
    bool clearError = false,
    bool clearDeleting = false,
  }) {
    return SavedAddressesState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      deletingId: clearDeleting ? null : (deletingId ?? this.deletingId),
    );
  }

  @override
  List<Object?> get props =>
      [addresses, isLoading, isLoaded, errorMessage, deletingId];
}
