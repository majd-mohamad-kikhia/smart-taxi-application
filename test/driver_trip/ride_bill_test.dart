import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/models/order_offer_model.dart';
import 'package:mshoar/core/session/session_cubit.dart';
import 'package:mshoar/core/utils/whatsapp_number.dart';
import 'package:mshoar/driver_features/driver_trip/data/datasources/ride_bill_pdf_builder.dart';
import 'package:mshoar/driver_features/driver_trip/data/models/driver_ride_finish_model.dart';
import 'package:mshoar/driver_features/driver_trip/data/models/ride_order_source.dart';
import 'package:mshoar/driver_features/driver_trip/data/repositories/ride_bill_repository.dart';
import 'package:mshoar/driver_features/driver_trip/presentation/cubit/driver_trip_state.dart';
import 'package:mshoar/driver_features/driver_trip/presentation/cubit/ride_bill_cubit.dart';
import 'package:mshoar/core/services/whatsapp_file_sender.dart';

Map<String, dynamic> _finishedRide({String source = 'whatsapp'}) => {
  'id': 41,
  'status': 'completed',
  'order_source': source,
  'completed_at': '2026-10-04 18:30:00',
  'price': 12400,
  'passengers_count': 6,
  'customer': {'id': 4, 'first_name': 'أحمد', 'last_name': 'علي', 'phone_number': '0991234567'},
  'fare': {
    'final_price': 12400,
    'estimated_price': 10200,
    'actual_distance_km': 12.4,
    'base_fare': 500,
    'distance_fare': 10980,
    'stops_fee_total': 400,
    'passengers_fee': 20,
    'waiting_fee': 500,
    'commission_rate': 10,
    'admin_commission_amount': 1240,
    'driver_earning_amount': 11160,
  },
};

final _order = OrderOfferModel(
  rideId: 41,
  vehicleTypeId: 2,
  pickupLat: 33.51,
  pickupLng: 36.27,
  pickupAddress: 'ساحة الشهداء',
  dropoffLat: 33.41,
  dropoffLng: 36.51,
  dropoffAddress: 'Damascus Airport',
  distanceKm: 10.2,
  estimatedDurationMin: 18,
  estimatedPrice: 10200,
  priceIsEstimate: true,
  requestedAt: DateTime.utc(2026, 10, 4, 18),
  distanceToPickupKm: 0,
);

DriverTripState _paidTrip({String source = 'whatsapp', bool paid = true}) {
  final finish = DriverRideFinishModel.fromRideJson(_finishedRide(source: source));
  return DriverTripState.initial(_order).copyWith(
    status: DriverTripStatus.completed,
    fare: finish.fare,
    orderSource: finish.orderSource,
    customer: finish.customer,
    completedAt: finish.completedAt,
    isPaid: paid,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('whatsAppNumber', () {
    test('turns local Syrian numbers into international digits', () {
      expect(whatsAppNumber('0991234567'), '963991234567');
      expect(whatsAppNumber('0991 234 567'), '963991234567');
      expect(whatsAppNumber('991234567'), '963991234567');
      expect(whatsAppNumber('+963 991 234 567'), '963991234567');
      expect(whatsAppNumber('00963991234567'), '963991234567');
    });

    test('too short to be a phone number is null', () {
      expect(whatsAppNumber('12345'), isNull);
      expect(whatsAppNumber(''), isNull);
    });
  });

  group('DriverRideFinishModel', () {
    test('reads the fare, the order source, the customer and the end time', () {
      final finish = DriverRideFinishModel.fromRideJson(_finishedRide());
      expect(finish.fare.finalPrice, 12400);
      expect(finish.orderSource, RideOrderSource.whatsapp);
      expect(finish.customer?.fullName, 'أحمد علي');
      expect(finish.customer?.phoneNumber, '0991234567');
      expect(finish.completedAt, DateTime.utc(2026, 10, 4, 18, 30));
    });

    test('a ride without order_source or customer is an app order', () {
      final finish = DriverRideFinishModel.fromRideJson({'id': 1, 'price': 100});
      expect(finish.orderSource, RideOrderSource.app);
      expect(finish.customer, isNull);
    });
  });

  group('the bill', () {
    final cubit = RideBillCubit(
      const RideBillRepository(RideBillPdfBuilder(), WhatsAppFileSender()),
      SessionCubit(),
    );
    tearDownAll(cubit.close);

    test('is offered for paid office orders only', () {
      expect(_paidTrip().canSendBill, isTrue);
      expect(_paidTrip(source: 'call').canSendBill, isTrue);
      expect(_paidTrip(source: 'app').canSendBill, isFalse);
      expect(_paidTrip(paid: false).canSendBill, isFalse);
      expect(cubit.billOf(_paidTrip(source: 'app')), isNull);
    });

    test('carries the trip, the customer and the fare lines', () {
      final bill = cubit.billOf(_paidTrip())!;
      expect(bill.rideId, 41);
      expect(bill.customerName, 'أحمد علي');
      expect(bill.customerPhone, '0991234567');
      expect(bill.distanceKm, 12.4);
      expect(bill.breakdown.finalPrice, 12400);
      expect(bill.breakdown.passengersFee, 20);
      expect(bill.breakdown.passengersCount, 6);
      expect(bill.fileName, 'smart_taxi_bill_41.pdf');
    });

    test('builds a PDF', () async {
      final bill = cubit.billOf(_paidTrip())!;
      final bytes = await const RideBillPdfBuilder().build(bill);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      File('${Directory.systemTemp.path}/smart_taxi_bill_preview.pdf').writeAsBytesSync(bytes);
    });
  });
}
