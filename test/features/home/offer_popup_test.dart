import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/theme/app_palette.dart';
import 'package:mshoar/features/home/data/models/offer_popup_model.dart';
import 'package:mshoar/features/home/data/models/ride_quote_model.dart';
import 'package:mshoar/features/home/presentation/widgets/offer_congrats_dialog_widget.dart';

Widget _app(OfferPopupModel offer) => MaterialApp(
  locale: const Locale('ar'),
  theme: ThemeData(extensions: [AppPalette.dark]),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: OfferCongratsDialogWidget(offer: offer))),
);

void main() {
  group('OfferPopupModel.tryParse', () {
    test('reads the manager\'s text and picture', () {
      final offer = OfferPopupModel.tryParse({
        'active': true,
        'text': ' ديمة دالاتي ',
        'image_url': '/uploads/offers/a.png',
      })!;
      expect(offer.text, 'ديمة دالاتي');
      expect(offer.imageUrl, '/uploads/offers/a.png');
    });

    test('a missing, null or blank text / picture stays null (app default)', () {
      final offer = OfferPopupModel.tryParse({
        'active': true,
        'text': '',
        'image_url': null,
      })!;
      expect(offer.text, isNull);
      expect(offer.imageUrl, isNull);
    });

    test('off: null offer or active false means no pop-up', () {
      expect(OfferPopupModel.tryParse(null), isNull);
      expect(OfferPopupModel.tryParse({'active': false, 'text': 'x'}), isNull);
    });
  });

  test('the quote carries the offer, and none when it is hidden', () {
    Map<String, dynamic> quote(Object? offer) => {
      'distance_km': 8.7,
      'offer': offer,
      'vehicle_types': [],
    };
    expect(
      RideQuoteModel.fromJson(quote({'active': true, 'text': 'x'})).offer!.text,
      'x',
    );
    expect(RideQuoteModel.fromJson(quote(null)).hasOffer, isFalse);
    expect(
      RideQuoteModel.fromJson(quote({'active': false})).hasOffer,
      isFalse,
    );
  });

  testWidgets('the pop-up shows the manager\'s text in place of the name', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const OfferPopupModel(text: 'اسم جديد')));
    await tester.pump();
    expect(find.text('اسم جديد'), findsOneWidget);
    expect(find.text('(ديمة دالاتي)'), findsNothing);
  });

  testWidgets('without a text it keeps the app\'s own name', (tester) async {
    await tester.pumpWidget(_app(const OfferPopupModel()));
    await tester.pump();
    expect(find.text('(ديمة دالاتي)'), findsOneWidget);
  });
}
