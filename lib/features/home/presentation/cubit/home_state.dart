import 'package:equatable/equatable.dart';
import '../../data/models/picked_location_model.dart';

/// Immutable state for the "إنشاء طلب" (create request) screen.
class HomeState extends Equatable {
  final String greeting;
  final String userName;
  final PickedLocationModel? fromLocation;
  final PickedLocationModel? toLocation;
  final bool isSearching;
  final String? searchErrorMessage;

  const HomeState({
    required this.greeting,
    required this.userName,
    this.fromLocation,
    this.toLocation,
    required this.isSearching,
    this.searchErrorMessage,
  });

  factory HomeState.initial() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'صباح الخير'
        : hour < 17
            ? 'مساء الخير'
            : 'مساء النور';

    return HomeState(
      greeting: greeting,
      userName: '',
      isSearching: false,
    );
  }

  /// Both pickup and dropoff must be picked before "بحث" is enabled.
  bool get canSearch => fromLocation != null && toLocation != null;

  HomeState copyWith({
    String? greeting,
    String? userName,
    PickedLocationModel? fromLocation,
    PickedLocationModel? toLocation,
    bool? isSearching,
    String? searchErrorMessage,
    bool clearSearchError = false,
  }) {
    return HomeState(
      greeting: greeting ?? this.greeting,
      userName: userName ?? this.userName,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      isSearching: isSearching ?? this.isSearching,
      searchErrorMessage: clearSearchError
          ? null
          : (searchErrorMessage ?? this.searchErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
        greeting,
        userName,
        fromLocation,
        toLocation,
        isSearching,
        searchErrorMessage,
      ];
}
