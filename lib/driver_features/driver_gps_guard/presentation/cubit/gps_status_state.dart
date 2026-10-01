import 'package:equatable/equatable.dart';

/// Whether the phone's GPS is on. [isEnabled] is null until the first
/// check answers — the driver isn't blocked before then, so the dialog
/// never flashes on start-up.
class GpsStatusState extends Equatable {
  final bool? isEnabled;

  const GpsStatusState({this.isEnabled});

  /// Known to be off: the driver must be blocked.
  bool get isDisabled => isEnabled == false;

  @override
  List<Object?> get props => [isEnabled];
}
