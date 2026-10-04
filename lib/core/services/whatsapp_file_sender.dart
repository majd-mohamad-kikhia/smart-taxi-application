import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/whatsapp_number.dart';

/// Puts a file into one person's WhatsApp chat.
///
/// On Android the chat of [send]'s `phone` opens straight away with the file
/// attached (WhatsApp, or WhatsApp Business). iOS can't target a chat, and
/// without WhatsApp or a usable number there is no chat to open — then the
/// system share sheet comes up instead, so the file can still be sent.
class WhatsAppFileSender {
  static const MethodChannel _channel = MethodChannel('smart_taxi/whatsapp');

  const WhatsAppFileSender();

  /// [origin] is where the share sheet's popover points on an iPad.
  Future<void> send({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? phone,
    String? text,
    Rect? origin,
  }) async {
    final number = phone == null ? null : whatsAppNumber(phone);
    if (Platform.isAndroid && number != null) {
      final opened = await _channel.invokeMethod<bool>('sendFile', {
        'bytes': bytes,
        'fileName': fileName,
        'mimeType': mimeType,
        'phone': number,
        'text': ?text,
      });
      if (opened ?? false) return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: fileName, mimeType: mimeType)],
        fileNameOverrides: [fileName],
        text: text,
        sharePositionOrigin: origin,
      ),
    );
  }
}
