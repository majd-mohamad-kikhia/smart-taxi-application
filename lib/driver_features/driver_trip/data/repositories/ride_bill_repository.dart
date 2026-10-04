import 'dart:ui' show Locale, Rect;
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/whatsapp_file_sender.dart';
import '../datasources/ride_bill_pdf_builder.dart';
import '../models/ride_bill_model.dart';

class RideBillException implements Exception {
  final String message;
  final Object? cause;

  const RideBillException(this.message, {this.cause});

  @override
  String toString() => cause == null ? message : '$message ($cause)';
}

/// Builds a ride's PDF bill and hands it to the customer's WhatsApp chat.
class RideBillRepository {
  final RideBillPdfBuilder _builder;
  final WhatsAppFileSender _sender;

  const RideBillRepository(this._builder, this._sender);

  /// Throws [RideBillException] when the bill can't be built or handed over.
  Future<void> sendOnWhatsApp(RideBillModel bill, {Rect? origin}) async {
    try {
      final bytes = await _builder.build(bill);
      final number = '${bill.rideId}';
      await _sender.send(
        bytes: bytes,
        fileName: bill.fileName,
        mimeType: 'application/pdf',
        phone: bill.customerPhone,
        text: [
          lookupAppLocalizations(const Locale('ar')).billMessage(number),
          lookupAppLocalizations(const Locale('en')).billMessage(number),
        ].join('\n'),
        origin: origin,
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        RideBillException(AppStrings.current.billSendFailed, cause: error),
        stackTrace,
      );
    }
  }
}
