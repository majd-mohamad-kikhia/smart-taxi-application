import 'package:equatable/equatable.dart';
import '../../data/models/app_version_model.dart';

sealed class AppVersionState extends Equatable {
  const AppVersionState();

  @override
  List<Object?> get props => const [];
}

class AppVersionChecking extends AppVersionState {
  const AppVersionChecking();
}

/// Continue into the app. [optional] is non-null while an optional update
/// dialog should be shown.
class AppVersionAllowed extends AppVersionState {
  final AppVersionModel? optional;

  const AppVersionAllowed({this.optional});

  @override
  List<Object?> get props => [optional];
}

/// This version is too old: only an "Update" button, no way into the app.
class AppVersionForceUpdate extends AppVersionState {
  final AppVersionModel info;

  const AppVersionForceUpdate(this.info);

  @override
  List<Object?> get props => [info];
}

/// The app is under maintenance: only a "Try again" button.
class AppVersionMaintenance extends AppVersionState {
  final AppVersionModel info;

  const AppVersionMaintenance(this.info);

  @override
  List<Object?> get props => [info];
}
