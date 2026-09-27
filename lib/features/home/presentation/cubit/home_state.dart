import 'package:equatable/equatable.dart';
import '../../data/models/offer_model.dart';
import '../../data/models/saved_destination_model.dart';
import '../../data/models/trip_model.dart';

/// Immutable state for the Home screen.
class HomeState extends Equatable {
  final String greeting;
  final String userName;
  final String currentArea;
  final int nearestCaptainMinutes;
  final bool isCaptainAvailable;
  final List<SavedDestinationModel> savedDestinations;
  final TripModel? lastTrip;
  final OfferModel? weeklyOffer;
  final bool isLoading;

  const HomeState({
    required this.greeting,
    required this.userName,
    required this.currentArea,
    required this.nearestCaptainMinutes,
    required this.isCaptainAvailable,
    required this.savedDestinations,
    this.lastTrip,
    this.weeklyOffer,
    required this.isLoading,
  });

  /// Builds the initial state with mock data matching the design.
  factory HomeState.initial() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'صباح الخير'
        : hour < 17
            ? 'مساء الخير'
            : 'مساء النور';

    return HomeState(
      greeting: greeting,
      userName: 'أحمد',
      currentArea: 'حي العليا، الرياض',
      nearestCaptainMinutes: 2,
      isCaptainAvailable: true,
      savedDestinations: const [
        SavedDestinationModel(
          id: 'home',
          name: 'المنزل',
          address: 'شارع الأمير سلطان',
          type: DestinationType.home,
          estimatedMinutes: 12,
        ),
        SavedDestinationModel(
          id: 'work',
          name: 'العمل',
          address: 'برج المملكة',
          type: DestinationType.work,
          estimatedMinutes: 25,
        ),
      ],
      lastTrip: const TripModel(
        id: 'trip_1',
        destinationName: 'مطار الملك خالد الدولي',
        destinationDetail: 'صالة 3',
        price: 48,
      ),
      weeklyOffer: const OfferModel(
        id: 'offer_1',
        badgeLabel: 'عرض عطلة الأسبوع',
        title: 'خصم 20% على مشاويرك',
        description:
            'استخدم الرمز الترويجي عند الحجز وإستمتع برحلتك بأقل تكلفة.',
        promoCode: 'مشوار20',
        discountPercent: 20,
      ),
      isLoading: false,
    );
  }

  HomeState copyWith({
    String? greeting,
    String? userName,
    String? currentArea,
    int? nearestCaptainMinutes,
    bool? isCaptainAvailable,
    List<SavedDestinationModel>? savedDestinations,
    TripModel? lastTrip,
    OfferModel? weeklyOffer,
    bool? isLoading,
  }) {
    return HomeState(
      greeting: greeting ?? this.greeting,
      userName: userName ?? this.userName,
      currentArea: currentArea ?? this.currentArea,
      nearestCaptainMinutes:
          nearestCaptainMinutes ?? this.nearestCaptainMinutes,
      isCaptainAvailable: isCaptainAvailable ?? this.isCaptainAvailable,
      savedDestinations: savedDestinations ?? this.savedDestinations,
      lastTrip: lastTrip ?? this.lastTrip,
      weeklyOffer: weeklyOffer ?? this.weeklyOffer,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        greeting,
        userName,
        currentArea,
        nearestCaptainMinutes,
        isCaptainAvailable,
        savedDestinations,
        lastTrip,
        weeklyOffer,
        isLoading,
      ];
}
