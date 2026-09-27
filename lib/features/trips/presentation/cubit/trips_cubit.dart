import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/trip_history_model.dart';
import 'trips_state.dart';

/// Cubit managing the My Trips screen state.
class TripsCubit extends Cubit<TripsState> {
  TripsCubit() : super(TripsState.initial());

  void initialize() {
    if (!isClosed) emit(TripsState.initial());
  }

  void selectTab(TripsTab tab) {
    if (isClosed || state.selectedTab == tab) return;
    emit(state.copyWith(selectedTab: tab));
  }

  void selectFilter(TripFilter filter) {
    if (isClosed || state.selectedFilter == filter) return;
    emit(state.copyWith(selectedFilter: filter));
  }

  void updateSearch(String query) {
    if (isClosed) return;
    emit(state.copyWith(searchQuery: query));
  }

  void reorderTrip(String tripId) {
    // Navigate to booking – handled by UI layer
  }

  void showInvoice(String tripId) {
    // Placeholder for invoice screen
  }
}
