import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Status of an active live trip.
enum LiveTripStatus { captainOnTheWay, arrived, inProgress, completed }

/// Model representing live trip tracking data.
class LiveTripModel extends Equatable {
  final String id;
  final LiveTripStatus status;
  final int etaMinutes;
  final LatLng captainLatLng;
  final LatLng pickupLatLng;
  final String pickupTitle;
  final String pickupSubtitle;
  final String paymentMethod;
  final double fare;
  final bool isTrackingEnabled;
  final bool isLocationSharingEnabled;

  const LiveTripModel({
    required this.id,
    required this.status,
    required this.etaMinutes,
    required this.captainLatLng,
    required this.pickupLatLng,
    required this.pickupTitle,
    required this.pickupSubtitle,
    required this.paymentMethod,
    required this.fare,
    required this.isTrackingEnabled,
    required this.isLocationSharingEnabled,
  });

  String get statusTitle {
    return switch (status) {
      LiveTripStatus.captainOnTheWay => 'الكابتن في الطريق إليك',
      LiveTripStatus.arrived => 'الكابتن وصل لنقطة الالتقاء',
      LiveTripStatus.inProgress => 'أنت في الطريق إلى الوجهة',
      LiveTripStatus.completed => 'وصلت إلى وجهتك',
    };
  }

  String get statusSubtitle {
    return switch (status) {
      LiveTripStatus.captainOnTheWay =>
        'الوصول المتوقع: $etaMinutes دقائق فقط',
      LiveTripStatus.arrived => 'الكابتن بانتظارك عند نقطة الالتقاء',
      LiveTripStatus.inProgress => 'المدة المتبقية: $etaMinutes دقائق',
      LiveTripStatus.completed => 'شكراً لاستخدامك مشوار',
    };
  }

  String get etaShortLabel => '$etaMinutes د';

  String get fareLabel => '${fare.toStringAsFixed(2)} ريال';

  LiveTripModel copyWith({
    String? id,
    LiveTripStatus? status,
    int? etaMinutes,
    LatLng? captainLatLng,
    LatLng? pickupLatLng,
    String? pickupTitle,
    String? pickupSubtitle,
    String? paymentMethod,
    double? fare,
    bool? isTrackingEnabled,
    bool? isLocationSharingEnabled,
  }) {
    return LiveTripModel(
      id: id ?? this.id,
      status: status ?? this.status,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      captainLatLng: captainLatLng ?? this.captainLatLng,
      pickupLatLng: pickupLatLng ?? this.pickupLatLng,
      pickupTitle: pickupTitle ?? this.pickupTitle,
      pickupSubtitle: pickupSubtitle ?? this.pickupSubtitle,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      fare: fare ?? this.fare,
      isTrackingEnabled: isTrackingEnabled ?? this.isTrackingEnabled,
      isLocationSharingEnabled:
          isLocationSharingEnabled ?? this.isLocationSharingEnabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        etaMinutes,
        captainLatLng,
        pickupLatLng,
        pickupTitle,
        pickupSubtitle,
        paymentMethod,
        fare,
        isTrackingEnabled,
        isLocationSharingEnabled,
      ];
}
