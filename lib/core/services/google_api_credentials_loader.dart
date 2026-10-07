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

  const GoogleApiCredentials({required this.apiKey, this.appHeaders = const {}});

  static const GoogleApiCredentials none = GoogleApiCredentials(apiKey: '');

  @override
  List<Object?> get props => [apiKey, appHeaders];
}

/// Works out, once per app run, the key and identity headers for this
/// platform:
///
/// - **Android**: the maps key from the manifest (`GOOGLE_MAPS_API_KEY` in
///   `android/local.properties`, the key the map itself uses) with the
///   package name and the SHA-1 of the certificate the running build is
///   signed with, read natively (`MainActivity`). Those are what an
///   Android-restricted key checks, and they follow the build — debug,
///   upload and Play signing each carry their own SHA-1.
/// - **iOS**: the `.env` key with the bundle identifier.
/// - Anywhere else: the `.env` key, no identity.
class GoogleApiCredentialsLoader {
  static const MethodChannel _defaultChannel = MethodChannel('smart_taxi/google_api');

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
  })  : _envKey = envKey,
        _channel = channel ?? _defaultChannel,
        _platform = platform ?? defaultTargetPlatform,
        _bundleId = bundleId ?? _packageName;

  static Future<String> _packageName() async => (await PackageInfo.fromPlatform()).packageName;

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
    switch (_platform) {
      case TargetPlatform.android:
        return _android();
      case TargetPlatform.iOS:
        if (_envKey.isEmpty) return _missing('GOOGLE_MAPS_API_KEY is missing from .env');
        return GoogleApiCredentials(
          apiKey: _envKey,
          appHeaders: {'X-Ios-Bundle-Identifier': await _bundleId()},
        );
      default:
        if (_envKey.isEmpty) return _missing('GOOGLE_MAPS_API_KEY is missing from .env');
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

    final key = identity?['apiKey'] as String? ?? '';
    final package = identity?['packageName'] as String? ?? '';
    final sha1 = identity?['certSha1'] as String? ?? '';
    if (key.isEmpty) {
      return _missing('no maps key in the build — set GOOGLE_MAPS_API_KEY in android/local.properties');
    }
    return GoogleApiCredentials(
      apiKey: key,
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
