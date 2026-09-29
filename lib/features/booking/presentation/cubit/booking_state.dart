import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/models/booking_route_model.dart';
import '../../data/models/ride_category_model.dart';

/// Immutable state for the Booking / Confirm Ride screen.
class BookingState extends Equatable {
  final BookingRouteModel route;
  final List<RideCategoryModel> categories;
  final String selectedCategoryId;
  final String paymentMethod;
  final double walletBalance;
  final String? captainNote;
  final double promoDiscount;
  final String? promoLabel;
  final bool isConfirming;
  final bool isConfirmed;

  const BookingState({
    required this.route,
    required this.categories,
    required this.selectedCategoryId,
    required this.paymentMethod,
    required this.walletBalance,
    this.captainNote,
    required this.promoDiscount,
    this.promoLabel,
    required this.isConfirming,
    required this.isConfirmed,
  });

  RideCategoryModel get selectedCategory =>
      categories.firstWhere((c) => c.id == selectedCategoryId);

  double get finalPrice =>
      (selectedCategory.price - promoDiscount).clamp(0, double.infinity);

  factory BookingState.initial() {
    // Sample data, worded in the language active when the state is created.
    final l10n = AppStrings.current;
    return BookingState(
      route: BookingRouteModel(
        pickupAddress: l10n.bookingMockPickup,
        destinationAddress: l10n.bookingMockDestination,
        pickupLatLng: const LatLng(24.7550, 46.6550),
        destinationLatLng: const LatLng(24.7800, 46.6200),
        durationMinutes: 18,
        distanceKm: 14.2,
        viaRoad: l10n.bookingMockViaRoad,
      ),
      categories: [
        RideCategoryModel(
          id: 'economy',
          type: RideCategoryType.economy,
          name: l10n.catEconomy,
          badge: l10n.catEconomyBadge,
          etaMinutes: 3,
          price: 28,
          icon: Icons.directions_car_rounded,
        ),
        RideCategoryModel(
          id: 'comfort',
          type: RideCategoryType.comfort,
          name: l10n.catComfort,
          etaMinutes: 5,
          price: 42,
          icon: Icons.airline_seat_recline_extra_rounded,
        ),
        RideCategoryModel(
          id: 'family_xl',
          type: RideCategoryType.familyXl,
          name: l10n.catFamilyXl,
          etaMinutes: 7,
          price: 65,
          passengerCapacity: 6,
          icon: Icons.airport_shuttle_rounded,
        ),
      ],
      selectedCategoryId: 'economy',
      paymentMethod: l10n.bookingPaymentWallet,
      walletBalance: 120,
      captainNote: l10n.bookingMockNote,
      promoDiscount: 5,
      promoLabel: l10n.bookingMockPromo,
      isConfirming: false,
      isConfirmed: false,
    );
  }

  BookingState copyWith({
    BookingRouteModel? route,
    List<RideCategoryModel>? categories,
    String? selectedCategoryId,
    String? paymentMethod,
    double? walletBalance,
    String? captainNote,
    double? promoDiscount,
    String? promoLabel,
    bool? isConfirming,
    bool? isConfirmed,
  }) {
    return BookingState(
      route: route ?? this.route,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      walletBalance: walletBalance ?? this.walletBalance,
      captainNote: captainNote ?? this.captainNote,
      promoDiscount: promoDiscount ?? this.promoDiscount,
      promoLabel: promoLabel ?? this.promoLabel,
      isConfirming: isConfirming ?? this.isConfirming,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }

  @override
  List<Object?> get props => [
        route,
        categories,
        selectedCategoryId,
        paymentMethod,
        walletBalance,
        captainNote,
        promoDiscount,
        promoLabel,
        isConfirming,
        isConfirmed,
      ];
}
