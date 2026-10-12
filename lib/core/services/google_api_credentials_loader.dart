import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The key and app identity to call Google's web APIs (Routes) with.
class GoogleApiCredentials extends Equatable {
  /// Empty when there is no usable key.
  final String apiKey;

  /// Tells Google which app is calling. A key restricted to Android or iOS
  /// apps is rejected without these ("Requests from this Android client
  /// application [empty] are blocked").
  final Map<String, String> appHeaders;

  const GoogleApiCredentials({
    required this.apiKey,
    this.appHeaders = const {},
  });

  static const GoogleApiCredentials none = GoogleApiCredentials(apiKey: '');

  @override
  List<Object?> get props => [apiKey, appHeaders];
}

/// Works out, once per app run, the key and identity headers for this
/// platform. The key is the one that platform's app is restricted to: on
/// Android the maps key built into the manifest (the Android key, the very
/// one the map uses), elsewhere `GOOGLE_MAPS_API_KEY` from `.env` (the iOS
/// key on iOS). The identity is what a key restricted to apps checks:
///
/// - **Android**: the package name and the SHA-1 of the certificate the
///   running build is signed with, read natively (`MainActivity`). They
///   follow the build — debug, upload and Play signing each carry their own
///   SHA-1. The `.env` key is only a fallback when the manifest has none.
/// - **iOS**: the bundle identifier.
/// - Anywhere else: no identity.
class GoogleApiCredentialsLoader {
  static const MethodChannel _defaultChannel = MethodChannel(
    'smart_taxi/google_api',
  );

  final String _envKey;
  final MethodChannel _channel;
  final TargetPlatform _platform;
  final Future<String> Function() _bundleId;
  GoogleApiCredentials? _loaded;

  GoogleApiCredentialsLoader({
    required String envKey,
    MethodChannel? channel,
    TargetPlatform? platform,
    Future<String> Function()? bundleId,
  }) : _envKey = envKey,
       _channel = channel ?? _defaultChannel,
       _platform = platform ?? defaultTargetPlatform,
       _bundleId = bundleId ?? _packageName;

  static Future<String> _packageName() async =>
      (await PackageInfo.fromPlatform()).packageName;

  /// The credentials; [GoogleApiCredentials.none] (not remembered, so the
  /// next call tries again) when they can't be had.
  Future<GoogleApiCredentials> load() async {
    final loaded = _loaded;
    if (loaded != null) return loaded;
    final credentials = await _resolve();
    if (credentials != GoogleApiCredentials.none) _loaded = credentials;
    return credentials;
  }

  Future<GoogleApiCredentials> _resolve() async {
    // Android has its own key (the manifest's); every other platform needs
    // the one from `.env`.
    if (_platform == TargetPlatform.android) return _android();
    if (_envKey.isEmpty) {
      return _missing('GOOGLE_MAPS_API_KEY is missing from .env');
    }
    switch (_platform) {
      case TargetPlatform.iOS:
        return GoogleApiCredentials(
          apiKey: _envKey,
          appHeaders: {'X-Ios-Bundle-Identifier': await _bundleId()},
        );
      default:
        return GoogleApiCredentials(apiKey: _envKey);
    }
  }

  Future<GoogleApiCredentials> _android() async {
    final Map<Object?, Object?>? identity;
    try {
      identity = await _channel.invokeMapMethod<Object?, Object?>('identity');
    } on PlatformException catch (e) {
      return _missing('could not read the app identity: $e');
    } on MissingPluginException {
      return _missing('the app identity channel is not available');
    }

    final package = identity?['packageName'] as String? ?? '';
    final sha1 = identity?['certSha1'] as String? ?? '';
    // The `.env` key is restricted to iOS apps: Google refuses it from an
    // Android app (API_KEY_IOS_APP_BLOCKED), whatever headers come with it.
    final manifestKey = identity?['apiKey'] as String? ?? '';
    final apiKey = manifestKey.isNotEmpty ? manifestKey : _envKey;
    if (apiKey.isEmpty) {
      return _missing('no Google API key in the manifest or .env');
    }
    return GoogleApiCredentials(
      apiKey: apiKey,
      appHeaders: {
        if (package.isNotEmpty) 'X-Android-Package': package,
        if (sha1.isNotEmpty) 'X-Android-Cert': sha1,
      },
    );
  }

  GoogleApiCredentials _missing(String reason) {
    debugPrint('GoogleApiCredentialsLoader: $reason');
    return GoogleApiCredentials.none;
  }
}
