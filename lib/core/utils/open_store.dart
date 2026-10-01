import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

/// Opens the app's store page — [storeUrl] from the version check, else the
/// built-in link for this platform. Returns false when there is no link or
/// nothing could open it, so the caller can tell the user.
Future<bool> openStore(String? storeUrl) async {
  final url = (storeUrl != null && storeUrl.isNotEmpty)
      ? storeUrl
      : (Platform.isIOS
            ? AppConstants.iosStoreUrl
            : AppConstants.androidStoreUrl);
  if (url.isEmpty) return false;
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
