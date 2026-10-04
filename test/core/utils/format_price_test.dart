import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/utils/format_price.dart';

String _plain(String text) => text.replaceAll(RegExp('[\u2066\u2069]'), '');

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ar = lookupAppLocalizations(const Locale('ar'));

  test('an API price shows in new pounds with old pounds (×100) after it', () {
    expect(formatSyp(en, 300), '300 new SYP (30,000 old)');
    expect(formatSyp(ar, 300), '300 ل.س جديدة (30,000 قديمة)');
    expect(formatSyp(en, 2500.4), '2,500 new SYP (250,040 old)');
  });

  test('new and old prices on their own', () {
    expect(formatNewSyp(en, 300), '300 new SYP');
    expect(formatOldSyp(ar, 300), '30,000 ل.س قديمة');
  });

  test('a signed price carries its sign on both amounts', () {
    expect(_plain(formatSignedPrice(en, -50)), '−50 new SYP (−5,000 old)');
    expect(_plain(formatSignedPrice(en, 50, showPlus: true)), '+50 new SYP (+5,000 old)');
    expect(_plain(formatOldSyp(en, -50)), '−5,000 old SYP');
    expect(formatSignedPrice(en, 0, showPlus: true), '0 new SYP (0 old)');
  });
}
