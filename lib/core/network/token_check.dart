import 'dart:async';
import 'package:dio/dio.dart';
import 'status_code.dart';

/// Runs an authenticated [probe] request and reports whether the server
/// *rejected the token* (401) — an expired session, or a revoked one such as
/// a deleted account.
///
/// Only an explicit 401 counts. Being offline, a timeout, or any other server
/// error says nothing about the token, so those return `false` and the user
/// stays signed in; the check simply runs again on the next app start.
/// [timeout] keeps a poor connection from holding back the first frame.
Future<bool> isTokenRejected(
  Future<void> Function() probe, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    await probe().timeout(timeout);
    return false;
  } on DioException catch (e) {
    return e.response?.statusCode == StatusCode.unauthorized;
  } on TimeoutException {
    return false;
  }
}
