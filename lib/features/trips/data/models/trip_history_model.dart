import 'package:equatable/equatable.dart';

/// Status of a historical trip.
enum TripHistoryStatus { completed, cancelled, business }

/// Filter chips available on the trips screen.
enum TripFilter { all, completed, cancelled, business }

/// Tab switcher on the trips screen.
enum TripsTab { past, scheduled }

/// Model representing a past / cancelled trip card.
class TripHistoryModel extends Equatable {
  final String id;
  final TripHistoryStatus status;
  final DateTime dateTime;
  final String categoryName;
  final String vehicleDetails;
  final String pickupAddress;
  final String destinationAddress;
  final double price;
  final double? distanceKm;
  final int? durationMinutes;
  final String? paymentMethod;
  final String? captainName;
  final double? captainRating;
  final String? cancelReason;
  final bool isDimmed;

  const TripHistoryModel({
    required this.id,
    required this.status,
    required this.dateTime,
    required this.categoryName,
    required this.vehicleDetails,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.price,
    this.distanceKm,
    this.durationMinutes,
    this.paymentMethod,
    this.captainName,
    this.captainRating,
    this.cancelReason,
    this.isDimmed = false,
  });

  String get statusLabel {
    return switch (status) {
      TripHistoryStatus.completed => 'مكتملة بنجاح',
      TripHistoryStatus.cancelled => 'ملغاة بدون رسوم',
      TripHistoryStatus.business => 'رحلة عمل',
    };
  }

  String get priceLabel => '${price.toStringAsFixed(2)} ل.س';

  String get metricsLabel {
    if (distanceKm != null && durationMinutes != null) {
      return '${distanceKm!.toStringAsFixed(1)} كم • $durationMinutes د';
    }
    if (captainName != null && captainRating != null) {
      return '${captainRating!.toStringAsFixed(1)} ★ ($captainName)';
    }
    return '';
  }

  @override
  List<Object?> get props => [
    id,
    status,
    dateTime,
    categoryName,
    vehicleDetails,
    pickupAddress,
    destinationAddress,
    price,
    distanceKm,
    durationMinutes,
    paymentMethod,
    captainName,
    captainRating,
    cancelReason,
    isDimmed,
  ];
}

/// A date-grouped section of trip cards.
class TripDayGroup extends Equatable {
  final String title;
  final double totalPrice;
  final List<TripHistoryModel> trips;

  const TripDayGroup({
    required this.title,
    required this.totalPrice,
    required this.trips,
  });

  String get totalLabel => '${totalPrice.toStringAsFixed(2)} ل.س';

  String get countLabel {
    final count = trips.length;
    if (count == 1) return 'رحلة واحدة';
    return '$count رحلات';
  }

  @override
  List<Object?> get props => [title, totalPrice, trips];
}
