import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/features/home/data/models/place_suggestion_model.dart';
import 'package:mshoar/features/home/data/place_search_ranker.dart';

PlaceSuggestionModel _place(String description, double lat, double lng) =>
    PlaceSuggestionModel(description: description, latitude: lat, longitude: lng);

// The customer is in Damascus.
const _lat = 33.5138;
const _lng = 36.2765;

List<String> _rank(String query, List<PlaceSuggestionModel> places, {int limit = 8}) => [
      for (final p in PlaceSearchRanker.rank(
        query,
        places,
        fromLatitude: _lat,
        fromLongitude: _lng,
        limit: limit,
      ))
        p.description,
    ];

void main() {
  final idlib = _place('جامع الروضة، سنجار، محافظة إدلب', 35.4, 36.7);
  final aleppo = _place('جامع الروضة، حلب', 36.2, 37.1);
  final damascus = _place('جامع الروضة، بلدية المهاجرين، دمشق', 33.52, 36.28);

  test('the nearest match comes first, whatever order the service gave', () {
    expect(_rank('جامع الروضة', [idlib, aleppo, damascus]), [
      damascus.description,
      idlib.description,
      aleppo.description,
    ]);
  });

  test('a match far away still beats a loosely related place next door', () {
    final nextDoor = _place('جامع النور، دمشق', 33.514, 36.277);

    expect(_rank('جامع الروضة', [nextDoor, aleppo]), [
      aleppo.description,
      nextDoor.description,
    ]);
  });

  test('Arabic spelling variants, the article and diacritics do not matter', () {
    final nextDoor = _place('جامع النور، دمشق', 33.514, 36.277);

    for (final query in ['جامع الروضه', 'جامع روضة', 'جَامِع الرَّوْضَة', 'الروضة']) {
      expect(_rank(query, [nextDoor, aleppo]).first, aleppo.description, reason: query);
    }
    expect(_rank('أبو', [_place('ابو رمانة', 33.52, 36.28), nextDoor]).first, 'ابو رمانة');
  });

  test('a half-typed last word already matches', () {
    final nextDoor = _place('جامع النور، دمشق', 33.514, 36.277);

    expect(_rank('جامع الرو', [nextDoor, aleppo]).first, aleppo.description);
  });

  test('the same place mapped twice shows once; the same name in another city stays', () {
    final twin = _place(damascus.description, 33.5201, 36.2801);

    final ranked = _rank('جامع الروضة', [damascus, twin, idlib]);

    expect(ranked, [damascus.description, idlib.description]);
  });

  test('every result carries its distance, nearest first', () {
    final ranked = PlaceSearchRanker.rank(
      'جامع الروضة',
      [idlib, damascus],
      fromLatitude: _lat,
      fromLongitude: _lng,
    );

    expect(ranked.first.distanceMeters, inInclusiveRange(500, 2000));
    expect(ranked.last.distanceMeters, greaterThan(200000));
  });

  test('keeps only the limit, and equal distances keep the service order', () {
    final a = _place('مطعم أ', 33.6, 36.3);
    final b = _place('مطعم ب', 33.6, 36.3);
    final c = _place('مطعم ج', 33.7, 36.3);

    expect(_rank('مطعم', [c, a, b], limit: 2), ['مطعم أ', 'مطعم ب']);
  });

  test('countMatches counts what was asked for, not what is merely close', () {
    final nextDoor = _place('جامع النور، دمشق', 33.514, 36.277);

    expect(PlaceSearchRanker.countMatches('جامع الروضة', [nextDoor, damascus, idlib]), 2);
    expect(PlaceSearchRanker.countMatches('   ', [damascus]), 0);
  });
}
