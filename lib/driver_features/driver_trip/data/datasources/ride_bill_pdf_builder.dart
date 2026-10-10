import 'dart:typed_data';
import 'dart:ui' show Locale;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/utils/format_price.dart';
import '../models/ride_bill_model.dart';

/// Draws a ride's bill as a one-page A5 PDF in English and Arabic side by
/// side, with every amount in new pounds and in old pounds. The fonts are
/// bundled (Tajawal covers both scripts) so the bill looks the same on any
/// phone, offline too.
class RideBillPdfBuilder {
  static const String _regularFont = 'assets/fonts/Tajawal-Regular.ttf';
  static const String _boldFont = 'assets/fonts/Tajawal-Bold.ttf';

  static final PdfColor _brand = PdfColor.fromInt(0xFFFFD600);
  static final PdfColor _ink = PdfColor.fromInt(0xFF111111);
  static final PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static final PdfColor _line = PdfColor.fromInt(0xFFE5E7EB);
  static final PdfColor _wash = PdfColor.fromInt(0xFFF7F7F8);
  static final RegExp _arabic = RegExp(r'[\u0600-\u06FF]');

  const RideBillPdfBuilder();

  Future<Uint8List> build(RideBillModel bill) async {
    final en = lookupAppLocalizations(const Locale('en'));
    final ar = lookupAppLocalizations(const Locale('ar'));
    final regular = pw.Font.ttf(await rootBundle.load(_regularFont));
    final bold = pw.Font.ttf(await rootBundle.load(_boldFont));
    final logo = pw.MemoryImage(
      (await rootBundle.load(AppConstants.logoPath)).buffer.asUint8List(),
    );

    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      title: '${en.billTitle} #${bill.rideId}',
      author: en.appName,
    );
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _header(en, logo),
            pw.SizedBox(height: 14),
            _bilingualTitle(en.billTitle, ar.billTitle),
            pw.SizedBox(height: 10),
            ..._details(bill, en, ar),
            pw.SizedBox(height: 14),
            _fareTable(bill, en, ar),
            pw.Spacer(),
            _footer(en, ar),
          ],
        ),
      ),
    );
    return document.save();
  }

  pw.Widget _header(AppLocalizations en, pw.ImageProvider logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _brand,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(logo, width: 40, height: 40),
          ),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                en.appName,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _ink),
              ),
              pw.Text(
                AppConstants.appSlogan,
                style: pw.TextStyle(fontSize: 9, color: _ink),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _bilingualTitle(String english, String arabic) {
    final style = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _ink);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(english, style: style),
        _text(arabic, style: style),
      ],
    );
  }

  List<pw.Widget> _details(RideBillModel bill, AppLocalizations en, AppLocalizations ar) {
    final distance = en.distanceKm(bill.distanceKm.toStringAsFixed(1));
    return [
      _detailRow(en.billNumber, ar.billNumber, ['#${bill.rideId}']),
      _detailRow(en.billDate, ar.billDate, [_date(bill.issuedAt)]),
      if (bill.customerName != null)
        _detailRow(en.billCustomer, ar.billCustomer, [bill.customerName!]),
      if (bill.driverName != null)
        _detailRow(en.billDriver, ar.billDriver, [bill.driverName!]),
      _detailRow(en.fromLabel, ar.fromLabel, [bill.pickupAddress]),
      _detailRow(en.toLabel, ar.toLabel, [bill.dropoffAddress]),
      _detailRow(en.fareDistanceDriven, ar.fareDistanceDriven, [distance]),
      _detailRow(en.billPayment, ar.billPayment, [en.billPaidCash, ar.billPaidCash]),
    ];
  }

  /// English label | value(s) | Arabic label.
  pw.Widget _detailRow(String english, String arabic, List<String> values) {
    final labelStyle = pw.TextStyle(fontSize: 9, color: _muted);
    final valueStyle = pw.TextStyle(fontSize: 10, color: _ink, fontWeight: pw.FontWeight.bold);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.6)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 3, child: pw.Text(english, style: labelStyle)),
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              children: [
                for (final value in values)
                  _text(value, style: valueStyle, textAlign: pw.TextAlign.center),
              ],
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: _text(arabic, style: labelStyle, textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }

  pw.Widget _fareTable(RideBillModel bill, AppLocalizations en, AppLocalizations ar) {
    final fare = bill.breakdown;
    final passengers = fare.passengersCount;
    String withPassengers(AppLocalizations l10n) => passengers == null
        ? l10n.farePassengersFee
        : '${l10n.farePassengersFee} (${l10n.passengersCount(passengers)})';
    final lines = <(String, String, double)>[
      if (fare.baseFare > 0) (en.fareBaseFare, ar.fareBaseFare, fare.baseFare),
      // The bill doesn't list stops or pauses: their prices are inside the
      // distance line, so the lines still add up to the total.
      (
        en.fareDistanceFare,
        ar.fareDistanceFare,
        fare.distanceFare + fare.stopsFeeTotal + fare.pauseFeeTotal,
      ),
      if (fare.passengersFee > 0) (withPassengers(en), withPassengers(ar), fare.passengersFee),
      if (fare.waitingFee > 0) (en.fareWaiting, ar.fareWaiting, fare.waitingFee),
      if (fare.rounding != 0) (en.fareRounding, ar.fareRounding, fare.rounding),
    ];
    final headStyle = pw.TextStyle(fontSize: 8, color: _muted, fontWeight: pw.FontWeight.bold);
    final cellStyle = pw.TextStyle(fontSize: 10, color: _ink);
    final totalStyle = pw.TextStyle(fontSize: 11, color: _ink, fontWeight: pw.FontWeight.bold);

    pw.TableRow row(String english, String arabic, double amount, pw.TextStyle style, {PdfColor? color}) {
      return pw.TableRow(
        decoration: pw.BoxDecoration(color: color),
        children: [
          _cell(pw.Text(english, style: style)),
          _cell(_text(arabic, style: style, textAlign: pw.TextAlign.right)),
          _cell(pw.Text(formatPrice(amount), style: style, textAlign: pw.TextAlign.right)),
          _cell(pw.Text(
            formatPrice(amount * oldPoundsPerNewPound),
            style: style.copyWith(color: _muted),
            textAlign: pw.TextAlign.right,
          )),
        ],
      );
    }

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(2.4),
        3: pw.FlexColumnWidth(3),
      },
      border: pw.TableBorder(horizontalInside: pw.BorderSide(color: _line, width: 0.6)),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _wash),
          children: [
            _cell(pw.Text(en.billItem, style: headStyle)),
            _cell(_text(ar.billItem, style: headStyle, textAlign: pw.TextAlign.right)),
            _cell(_stacked(en.priceSypNewCurrency, ar.priceSypNewCurrency, headStyle)),
            _cell(_stacked(en.billOldSyp, ar.billOldSyp, headStyle)),
          ],
        ),
        for (final (english, arabic, amount) in lines) row(english, arabic, amount, cellStyle),
        row(en.fareTotal, ar.fareTotal, fare.finalPrice, totalStyle, color: _brand),
      ],
    );
  }

  pw.Widget _footer(AppLocalizations en, AppLocalizations ar) {
    final style = pw.TextStyle(fontSize: 9, color: _muted);
    return pw.Column(
      children: [
        pw.Divider(color: _line, thickness: 0.6),
        pw.Text(en.billThanks, style: style, textAlign: pw.TextAlign.center),
        _text(ar.billThanks, style: style, textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 4),
        pw.Text(
          AppConstants.appSlogan,
          style: pw.TextStyle(fontSize: 9, color: _ink, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  /// "2026-10-04  21:30", in Latin digits for both languages.
  static String _date(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)}  ${two(time.hour)}:${two(time.minute)}';
  }

  pw.Widget _cell(pw.Widget child) =>
      pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5), child: child);

  pw.Widget _stacked(String english, String arabic, pw.TextStyle style) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Text(english, style: style, textAlign: pw.TextAlign.right),
      _text(arabic, style: style, textAlign: pw.TextAlign.right),
    ],
  );

  /// Text that runs right to left when it holds Arabic (names and addresses
  /// may be in either script).
  pw.Widget _text(String value, {required pw.TextStyle style, pw.TextAlign? textAlign}) {
    return pw.Text(
      value,
      style: style,
      textAlign: textAlign,
      textDirection: _arabic.hasMatch(value) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
    );
  }
}
