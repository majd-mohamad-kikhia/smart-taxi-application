import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/features/home/data/datasources/recent_places_local_data_source.dart';
import 'package:mshoar/features/home/data/models/place_suggestion_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const source = RecentPlacesLocalDataSource();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nothing saved is an empty list', () async {
    expect(await source.load(), isEmpty);
  });

  test('saved places come back in order, flagged as recent, without distance', () async {
    await source.save(const [
      PlaceSuggestionModel(description: 'جامع الروضة، اللاذقية', latitude: 35.52, longitude: 35.79, distanceMeters: 120),
      PlaceSuggestionModel(description: 'مشفى الأسد، اللاذقية', latitude: 35.54, longitude: 35.78),
    ]);

    final loaded = await source.load();

    expect([for (final p in loaded) p.description], ['جامع الروضة، اللاذقية', 'مشفى الأسد، اللاذقية']);
    expect(loaded.first.latitude, 35.52);
    expect(loaded.first.longitude, 35.79);
    expect(loaded.every((p) => p.isRecent), isTrue);
    expect(loaded.first.distanceMeters, isNull);
  });

  test('a corrupt value is dropped and reads as empty', () async {
    SharedPreferences.setMockInitialValues({'recent_places': '{not json'});

    expect(await source.load(), isEmpty);
    expect((await SharedPreferences.getInstance()).containsKey('recent_places'), isFalse);
  });

  test('clear forgets the places', () async {
    await source.save(const [
      PlaceSuggestionModel(description: 'مكان', latitude: 35.5, longitude: 35.8),
    ]);

    await source.clear();

    expect(await source.load(), isEmpty);
  });
}
