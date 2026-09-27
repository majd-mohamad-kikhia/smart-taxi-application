import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';

/// Cubit managing the Home screen state.
/// Follows the principle of keeping business logic out of the UI layer.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState.initial());

  /// Called when the screen first loads.
  void initialize() {
    // In production this would fetch real data.
    // For now the initial state carries mock data.
    if (!isClosed) emit(HomeState.initial());
  }

  /// Updates the greeting based on the current time of day.
  void refreshGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'صباح الخير'
        : hour < 17
            ? 'مساء الخير'
            : 'مساء النور';

    if (!isClosed && state.greeting != greeting) {
      emit(state.copyWith(greeting: greeting));
    }
  }

  /// Simulates requesting a ride from a saved destination.
  void requestRideToDestination(String destinationId) {
    // TODO: navigate to booking screen in next iterations
  }

  /// Simulates repeating the last trip.
  void repeatLastTrip() {
    // TODO: navigate to booking screen pre-filled
  }

  /// Applies a promo code from the offer banner.
  void applyPromoCode(String code) {
    // TODO: navigate to booking screen with code applied
  }
}
