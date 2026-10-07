import 'package:equatable/equatable.dart';
import '../../../../core/models/picked_location_model.dart';
import '../../data/models/place_suggestion_model.dart';

/// Which of the two trip points the customer is placing on the home map.
enum PickTarget { from, to }

/// The home map's "pick a point" mode: a pin at the map's center, the
/// address under it, and a search for places. [target] is null while the
/// screen is in its normal state.
class MapPickState extends Equatable {
  final PickTarget? target;

  /// Open the search field with the keyboard up (entered from the search bar).
  final bool autofocusSearch;

  /// The address under the pin; null while the map moves or it is looked up.
  final String? address;
  final bool isResolving;

  final List<PlaceSuggestionModel> suggestions;
  final bool isSearching;
  final String? searchError;

  /// A request for the map to move: only meaningful together with
  /// [moveCount], so asking for the same spot twice still moves it.
  final PickedLocationModel? moveTarget;
  final double moveZoom;
  final int moveCount;

  const MapPickState({
    this.target,
    this.autofocusSearch = false,
    this.address,
    this.isResolving = false,
    this.suggestions = const [],
    this.isSearching = false,
    this.searchError,
    this.moveTarget,
    this.moveZoom = 16,
    this.moveCount = 0,
  });

  bool get isPicking => target != null;

  /// Confirming needs a real, resolved address — never a bare coordinate
  /// pair, and never one left over from a previous pin position.
  bool get canConfirm => isPicking && address != null && !isResolving;

  MapPickState copyWith({
    PickTarget? target,
    String? address,
    bool? isResolving,
    List<PlaceSuggestionModel>? suggestions,
    bool? isSearching,
    String? searchError,
    PickedLocationModel? moveTarget,
    double? moveZoom,
    int? moveCount,
    bool clearAddress = false,
    bool clearSearchError = false,
  }) {
    return MapPickState(
      target: target ?? this.target,
      autofocusSearch: autofocusSearch,
      address: clearAddress ? null : (address ?? this.address),
      isResolving: isResolving ?? this.isResolving,
      suggestions: suggestions ?? this.suggestions,
      isSearching: isSearching ?? this.isSearching,
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
      moveTarget: moveTarget ?? this.moveTarget,
      moveZoom: moveZoom ?? this.moveZoom,
      moveCount: moveCount ?? this.moveCount,
    );
  }

  @override
  List<Object?> get props => [
        target,
        autofocusSearch,
        address,
        isResolving,
        suggestions,
        isSearching,
        searchError,
        moveTarget,
        moveZoom,
        moveCount,
      ];
}
