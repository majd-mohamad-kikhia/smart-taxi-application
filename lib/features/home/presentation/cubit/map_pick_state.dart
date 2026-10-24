import 'package:equatable/equatable.dart';
import '../../../../core/geo/geo_models.dart';
import '../../../../core/models/picked_location_model.dart';

/// The server suggests another place for a search: the customer is asked
/// "did you mean …?". Yes continues with [aliasId]; no with Google's answer.
class DidYouMeanPrompt extends Equatable {
  final String query;
  final int aliasId;
  final String text;

  const DidYouMeanPrompt({
    required this.query,
    required this.aliasId,
    required this.text,
  });

  @override
  List<Object?> get props => [query, aliasId, text];
}

/// Which of the two trip points the customer is placing on the home map.
enum PickTarget { from, to }

/// The home map's "pick a point" mode: a pin at the map's center, the
/// address under it, and a search for places. [target] is null while the
/// screen is in its normal state.
class MapPickState extends Equatable {
  final PickTarget? target;

  /// The address under the pin; null while the map moves or it is looked up.
  final String? address;

  final bool isResolving;

  /// The pin has no address yet on purpose: the customer came in through the
  /// search box, so the spot under the pin is only named if they move the
  /// map or confirm it. Confirming is allowed meanwhile, and names it then.
  final bool addressDeferred;

  final bool isSearching;
  final String? searchError;

  /// The customer has typed in the field and not searched yet: the main
  /// button says Search. It ends when the pin is placed (a search result, a
  /// suggestion, a saved place, a dragged pin) or the field is emptied.
  final bool isTyping;

  /// Our places matching what is being typed (at most 5), under the field.
  final List<GeoSuggestionModel> suggestions;

  /// Set while the customer is asked "did you mean …?".
  final DidYouMeanPrompt? didYouMean;

  /// The place the server corrected the search to; shown once ("تم التصحيح
  /// إلى …"), then cleared.
  final String? correctedTo;

  /// A request for the map to move: only meaningful together with
  /// [moveCount], so asking for the same spot twice still moves it.
  final PickedLocationModel? moveTarget;
  final double moveZoom;
  final int moveCount;

  const MapPickState({
    this.target,
    this.address,
    this.isResolving = false,
    this.addressDeferred = false,
    this.isSearching = false,
    this.searchError,
    this.suggestions = const [],
    this.isTyping = false,
    this.didYouMean,
    this.correctedTo,
    this.moveTarget,
    this.moveZoom = 16,
    this.moveCount = 0,
    this.isDragging = false,
  });

  /// The map is being moved: the screen hides its controls so the customer
  /// sees only the map and the pin, and brings them back when it settles.
  final bool isDragging;

  bool get isPicking => target != null;

  /// Confirming needs a real, resolved address — never a bare coordinate
  /// pair, and never one left over from a previous pin position. A pin whose
  /// naming was put off ([addressDeferred]) is named when it is confirmed.
  bool get canConfirm =>
      isPicking && !isResolving && (address != null || addressDeferred);

  MapPickState copyWith({
    PickTarget? target,
    String? address,
    bool? isResolving,
    bool? addressDeferred,
    bool? isSearching,
    String? searchError,
    List<GeoSuggestionModel>? suggestions,
    bool? isTyping,
    DidYouMeanPrompt? didYouMean,
    String? correctedTo,
    PickedLocationModel? moveTarget,
    double? moveZoom,
    int? moveCount,
    bool? isDragging,
    bool clearAddress = false,
    bool clearSearchError = false,
    bool clearDidYouMean = false,
    bool clearCorrectedTo = false,
  }) {
    return MapPickState(
      target: target ?? this.target,
      address: clearAddress ? null : (address ?? this.address),
      isResolving: isResolving ?? this.isResolving,
      addressDeferred: addressDeferred ?? this.addressDeferred,
      isSearching: isSearching ?? this.isSearching,
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
      suggestions: suggestions ?? this.suggestions,
      isTyping: isTyping ?? this.isTyping,
      didYouMean: clearDidYouMean ? null : (didYouMean ?? this.didYouMean),
      correctedTo: clearCorrectedTo ? null : (correctedTo ?? this.correctedTo),
      moveTarget: moveTarget ?? this.moveTarget,
      moveZoom: moveZoom ?? this.moveZoom,
      moveCount: moveCount ?? this.moveCount,
      isDragging: isDragging ?? this.isDragging,
    );
  }

  @override
  List<Object?> get props => [
    target,
    address,
    isResolving,
    addressDeferred,
    isSearching,
    searchError,
    suggestions,
    isTyping,
    didYouMean,
    correctedTo,
    moveTarget,
    moveZoom,
    moveCount,
    isDragging,
  ];
}
