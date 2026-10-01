import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in whatever app handles it (`tel:` → dialer, `https://wa.me/…`
/// → WhatsApp or the browser). Returns false when nothing could open it, so
/// the caller can tell the user.
Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || url.isEmpty) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    return false;
  }
}
