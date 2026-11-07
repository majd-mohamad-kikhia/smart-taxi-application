import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/driver_features/driver_home/presentation/widgets/vehicle_type_style.dart';

void main() {
  VehicleTypeStyle style(String name, [int id = 1]) =>
      VehicleTypeStyle.of(name: name, typeId: id);

  test('economy is yellow, public tourist orange, private tourist blue, VIP red', () {
    expect(style('اقتصادي').background, const Color(0xFFFACC15));
    expect(style('سياحية عامة').background, const Color(0xFFF97316));
    expect(style('سياحية خاصة').background, const Color(0xFF2563EB));
    expect(style('بلاتينيوم (VIP)').background, const Color(0xFFDC2626));
  });

  test('an unknown name gets the same colour every time, by its id', () {
    expect(style('كومفورت', 5).background, style('كومفورت', 5).background);
  });
}
