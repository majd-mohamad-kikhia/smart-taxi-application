import 'dart:async';
import 'package:app_links/app_links.dart';

/// Reads the links that open the app — today only office orders shared in
/// the drivers' WhatsApp group:
/// - `https://smart-taxi.co/o/{token}` (Android App Links / iOS Universal
///   Links)
/// - `smarttaxidriver://order/{token}` (the web page's "open in the app"
///   fallback)
///
/// One instance per app session. Listen to [sharedOrderTokens] before
/// calling [init], or the link that cold-started the app is missed.
class DeepLinkService {
  /// The same link reported twice this close together is one tap (the
  /// link that starts the app can arrive both ways); tapped again later,
  /// it opens again.
  static const _duplicateWindow = Duration(seconds: 3);

  final AppLinks _appLinks;
  final StreamController<String> _tokens = StreamController<String>.broadcast();
  StreamSubscription<Uri>? _subscription;
  String? _lastToken;
  DateTime? _lastAt;

  /// A link opened while nobody was signed in, waiting for a driver login.
  String? _pendingToken;

  DeepLinkService(this._appLinks);

  Stream<String> get sharedOrderTokens => _tokens.stream;

  Future<void> init() async {
    if (_subscription != null) return;
    _subscription = _appLinks.uriLinkStream.listen(_handle);
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handle(initial);
  }

  void keepPending(String token) => _pendingToken = token;

  /// The waiting token, if any — cleared once taken.
  String? takePendingToken() {
    final token = _pendingToken;
    _pendingToken = null;
    return token;
  }

  void _handle(Uri uri) {
    final token = tokenFrom(uri);
    if (token == null) return;
    final now = DateTime.now();
    final last = _lastAt;
    if (token == _lastToken && last != null && now.difference(last) < _duplicateWindow) {
      return;
    }
    _lastToken = token;
    _lastAt = now;
    _tokens.add(token);
  }

  /// The order token in [uri], or null when it isn't an order link.
  static String? tokenFrom(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (uri.scheme == 'https' &&
        uri.host == 'smart-taxi.co' &&
        segments.length == 2 &&
        segments.first == 'o') {
      return _valid(segments[1]);
    }
    if (uri.scheme == 'smarttaxidriver' &&
        uri.host == 'order' &&
        segments.length == 1) {
      return _valid(segments.first);
    }
    return null;
  }

  static final RegExp _tokenPattern = RegExp(r'^[A-Za-z0-9_-]{22}$');

  static String? _valid(String token) =>
      _tokenPattern.hasMatch(token) ? token : null;

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _tokens.close();
  }
}
