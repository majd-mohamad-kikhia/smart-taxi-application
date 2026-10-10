import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/services/google_api_credentials_loader.dart';

const _channel = MethodChannel('test/google_api');

void _answerWith(Future<Object?> Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

GoogleApiCredentialsLoader _loader(TargetPlatform platform, {String envKey = 'env-key'}) {
  return GoogleApiCredentialsLoader(
    envKey: envKey,
    channel: _channel,
    platform: platform,
    bundleId: () async => 'com.ma.smarttaxi.ios',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('Android: the .env key, with the build\'s package and signing SHA-1', () async {
    _answerWith((call) async {
      expect(call.method, 'identity');
      return {
        'apiKey': 'manifest-key',
        'packageName': 'com.ma.smarttaxi',
        'certSha1': '4108A6765831A2FC66A66D3CAD92A444F3219CC1',
      };
    });

    final credentials = await _loader(TargetPlatform.android).load();

    // The manifest key is only the map's own; web APIs use the .env key.
    expect(credentials.apiKey, 'env-key');
    expect(credentials.appHeaders, {
      'X-Android-Package': 'com.ma.smarttaxi',
      'X-Android-Cert': '4108A6765831A2FC66A66D3CAD92A444F3219CC1',
    });
  });

  test('Android: asked natively once, then remembered', () async {
    var asked = 0;
    _answerWith((call) async {
      asked++;
      return {'packageName': 'p', 'certSha1': 'AB'};
    });
    final loader = _loader(TargetPlatform.android);

    await loader.load();
    await loader.load();

    expect(asked, 1);
  });

  test('Android: an empty .env key means no credentials, without asking natively', () async {
    var asked = 0;
    _answerWith((call) async {
      asked++;
      return {'apiKey': 'manifest-key', 'packageName': 'p', 'certSha1': 'AB'};
    });

    expect(await _loader(TargetPlatform.android, envKey: '').load(), GoogleApiCredentials.none);
    expect(asked, 0);
  });

  test('Android: a native failure or a missing channel means no credentials', () async {
    _answerWith((call) async => throw PlatformException(code: 'boom'));
    expect(await _loader(TargetPlatform.android).load(), GoogleApiCredentials.none);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    expect(await _loader(TargetPlatform.android).load(), GoogleApiCredentials.none);
  });

  test('iOS: the .env key with the bundle identifier', () async {
    final credentials = await _loader(TargetPlatform.iOS).load();

    expect(credentials.apiKey, 'env-key');
    expect(credentials.appHeaders, {'X-Ios-Bundle-Identifier': 'com.ma.smarttaxi.ios'});
  });

  test('other platforms: the .env key alone; without it, nothing', () async {
    final credentials = await _loader(TargetPlatform.macOS).load();
    expect(credentials, const GoogleApiCredentials(apiKey: 'env-key'));

    expect(await _loader(TargetPlatform.macOS, envKey: '').load(), GoogleApiCredentials.none);
    expect(await _loader(TargetPlatform.iOS, envKey: '').load(), GoogleApiCredentials.none);
  });
}
