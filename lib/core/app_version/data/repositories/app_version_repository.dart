import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../localization/app_strings.dart';
import '../../../network/api_exception.dart';
import '../datasources/app_version_local_datasource.dart';
import '../datasources/app_version_remote_datasource.dart';
import '../models/app_version_model.dart';

class AppVersionRepository {
  final AppVersionRemoteDataSource _remote;
  final AppVersionLocalDataSource _local;

  const AppVersionRepository(this._remote, this._local);

  /// Throws [ApiException] when the server can't be reached or rejects the
  /// request — the caller decides what that means (the cubit fails open).
  Future<AppVersionModel> check({
    required AppVersionApp app,
    required String lang,
  }) async {
    final info = await PackageInfo.fromPlatform();
    final version = info.buildNumber.isEmpty
        ? info.version
        : '${info.version}+${info.buildNumber}';
    try {
      return await _remote.check(
        app: app,
        platform: Platform.isIOS ? 'ios' : 'android',
        version: version,
        lang: lang,
      );
    } on DioException catch (e) {
      final error = e.error;
      throw error is ApiException
          ? error
          : ApiException(AppStrings.current.errServerUnreachable);
    }
  }

  Future<bool> isSkipped(AppVersionApp app, String latestVersion) async =>
      await _local.loadSkippedVersion(app) == latestVersion;

  Future<void> skip(AppVersionApp app, String latestVersion) =>
      _local.saveSkippedVersion(app, latestVersion);
}
