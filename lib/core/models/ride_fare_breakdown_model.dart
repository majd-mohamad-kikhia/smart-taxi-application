import 'package:equatable/equatable.dart';
import 'ride_waiting_model.dart';

/// The bill lines of a finished ride — the `fare` object on the
/// `completed` status event and the driver's `finish` reply:
/// `final_price = base_fare + distance_fare + stops_fee_total + waiting_fee
/// + pause_fee_total`.
class RideFareBreakdownModel extends Equatable {
  final double baseFare;
  final double distanceFare;
  final double stopsFeeTotal;
  final double waitingFee;
  final RideWaitingModel? waiting;

  /// All pause fees, and how many pauses / how long they lasted in total.
  final double pauseFeeTotal;
  final int pauseCount;
  final int pauseTotalSeconds;
  final double finalPrice;

  const RideFareBreakdownModel({
    required this.baseFare,
    required this.distanceFare,
    required this.stopsFeeTotal,
    required this.waitingFee,
    required this.waiting,
    this.pauseFeeTotal = 0,
    this.pauseCount = 0,
    this.pauseTotalSeconds = 0,
    required this.finalPrice,
  });

  /// [fare] is the `fare` object; [fallbackFinalPrice] is used when the
  /// server omitted `final_price` from it.
  factory RideFareBreakdownModel.fromJson(
    Map<String, dynamic> fare, {
    double fallbackFinalPrice = 0,
  }) {
    double number(String key) => (fare[key] as num?)?.toDouble() ?? 0;
    final pauses = fare['pauses'] is Map ? fare['pauses'] as Map : const {};
    return RideFareBreakdownModel(
      baseFare: number('base_fare'),
      distanceFare: number('distance_fare'),
      stopsFeeTotal: number('stops_fee_total'),
      waitingFee: number('waiting_fee'),
      waiting: RideWaitingModel.fromParent(fare),
      pauseFeeTotal: number('pause_fee_total'),
      pauseCount: (pauses['count'] as num?)?.toInt() ?? 0,
      pauseTotalSeconds: (pauses['total_seconds'] as num?)?.toInt() ?? 0,
      finalPrice:
          (fare['final_price'] as num?)?.toDouble() ?? fallbackFinalPrice,
    );
  }

  /// Parses `json['fare']`, or returns null when it is absent.
  static RideFareBreakdownModel? fromParent(
    Map<String, dynamic> json, {
    double fallbackFinalPrice = 0,
  }) {
    final fare = json['fare'];
    return fare is Map
        ? RideFareBreakdownModel.fromJson(
            Map<String, dynamic>.from(fare),
            fallbackFinalPrice: fallbackFinalPrice,
          )
        : null;
  }

  @override
  List<Object?> get props => [
    baseFare,
    distanceFare,
    stopsFeeTotal,
    waitingFee,
    waiting,
    pauseFeeTotal,
    pauseCount,
    pauseTotalSeconds,
    finalPrice,
  ];
}
