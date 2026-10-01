import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/widgets/vehicle_type_icon_widget.dart';

void main() {
  test('maps vehicle type names to distinct icons', () {
    expect(
      VehicleTypeIconWidget.iconFor('economy'),
      Icons.directions_car_rounded,
    );
    expect(
      VehicleTypeIconWidget.iconFor('Comfort'),
      Icons.airline_seat_recline_extra_rounded,
    );
    expect(
      VehicleTypeIconWidget.iconFor('VIP'),
      Icons.workspace_premium_rounded,
    );
    expect(
      VehicleTypeIconWidget.iconFor('Family XL'),
      Icons.airport_shuttle_rounded,
    );
    expect(VehicleTypeIconWidget.iconFor('Bike'), Icons.two_wheeler_rounded);
    expect(
      VehicleTypeIconWidget.iconFor('delivery'),
      Icons.local_shipping_rounded,
    );
  });

  test('understands Arabic names', () {
    expect(
      VehicleTypeIconWidget.iconFor('اقتصادي'),
      Icons.directions_car_rounded,
    );
    expect(
      VehicleTypeIconWidget.iconFor('مريح'),
      Icons.airline_seat_recline_extra_rounded,
    );
    expect(
      VehicleTypeIconWidget.iconFor('عائلي'),
      Icons.airport_shuttle_rounded,
    );
  });

  test('falls back to a taxi for unknown names', () {
    expect(VehicleTypeIconWidget.iconFor('spaceship'), Icons.local_taxi_rounded);
    expect(VehicleTypeIconWidget.iconFor(''), Icons.local_taxi_rounded);
  });
}
