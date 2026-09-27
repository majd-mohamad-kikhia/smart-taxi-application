import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
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
    return BookingState(
      route: BookingRouteModel(
        pickupAddress: 'حي الصحافة، طريق العليا العام',
        destinationAddress: 'واجهة الرياض (Riyadh Front) - بوابة 4',
        pickupLatLng: const LatLng(24.7550, 46.6550),
        destinationLatLng: const LatLng(24.7800, 46.6200),
        durationMinutes: 18,
        distanceKm: 14.2,
        viaRoad: 'طريق الثمامة',
      ),
      categories: const [
        RideCategoryModel(
          id: 'economy',
          type: RideCategoryType.economy,
          name: 'اقتصادي',
          badge: 'الأكثر توفيراً',
          etaMinutes: 3,
          price: 28,
          icon: Icons.directions_car_rounded,
        ),
        RideCategoryModel(
          id: 'comfort',
          type: RideCategoryType.comfort,
          name: 'مريح',
          etaMinutes: 5,
          price: 42,
          icon: Icons.airline_seat_recline_extra_rounded,
        ),
        RideCategoryModel(
          id: 'family_xl',
          type: RideCategoryType.familyXl,
          name: 'عائلي XL',
          etaMinutes: 7,
          price: 65,
          passengerCapacity: 6,
          icon: Icons.airport_shuttle_rounded,
        ),
      ],
      selectedCategoryId: 'economy',
      paymentMethod: 'محفظة',
      walletBalance: 120,
      captainNote: 'بدون اتصال - التك...',
      promoDiscount: 5,
      promoLabel: 'تم تطبيق كود ترحيبي مشوار (خصم 15%)',
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
