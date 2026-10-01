import 'package:equatable/equatable.dart';

/// Which side of the platform the version check is asked for. The wire value
/// is what `GET /api/app/version-check?app=` expects.
enum AppVersionApp {
  customer,
  driver;

  String get wireValue => name;
}

/// The server's verdict on this app version. Unknown values map to [ok] so an
/// older app never locks itself out if the server adds a new status.
enum AppVersionStatus { ok, optionalUpdate, forceUpdate, maintenance }

class AppVersionModel extends Equatable {
  final AppVersionStatus status;
  final bool canContinue;
  final String currentVersion;
  final String latestVersion;
  final String minVersion;
  final String? storeUrl;

  /// Ready-to-show text in the requested language — null when [status] is ok.
  final String? title;
  final String? message;
  final String? releaseNotes;

  /// Expected end of maintenance (server time), display only.
  final String? maintenanceEndsAt;

  const AppVersionModel({
    required this.status,
    required this.canContinue,
    required this.currentVersion,
    required this.latestVersion,
    required this.minVersion,
    this.storeUrl,
    this.title,
    this.message,
    this.releaseNotes,
    this.maintenanceEndsAt,
  });

  static AppVersionStatus _statusFrom(String? raw) => switch (raw) {
    'optional_update' => AppVersionStatus.optionalUpdate,
    'force_update' => AppVersionStatus.forceUpdate,
    'maintenance' => AppVersionStatus.maintenance,
    _ => AppVersionStatus.ok,
  };

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    final maintenance =
        (json['maintenance'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AppVersionModel(
      status: _statusFrom(json['status'] as String?),
      canContinue: json['can_continue'] as bool? ?? true,
      currentVersion: json['current_version'] as String? ?? '',
      latestVersion: json['latest_version'] as String? ?? '',
      minVersion: json['min_version'] as String? ?? '',
      storeUrl: json['store_url'] as String?,
      title: json['title'] as String?,
      message: json['message'] as String?,
      releaseNotes: json['release_notes'] as String?,
      maintenanceEndsAt: maintenance['ends_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    canContinue,
    currentVersion,
    latestVersion,
    minVersion,
    storeUrl,
    title,
    message,
    releaseNotes,
    maintenanceEndsAt,
  ];
}
