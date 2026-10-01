import 'package:equatable/equatable.dart';

enum SearchRadiusSaveStatus { idle, saving, success, failure }

class DriverSettingsState extends Equatable {
  /// What the slider shows now.
  final int searchRadiusKm;

  /// What is saved on the account; the slider differs from it while there is
  /// something unsaved.
  final int savedSearchRadiusKm;
  final SearchRadiusSaveStatus saveStatus;
  final String? errorMessage;

  const DriverSettingsState({
    required this.searchRadiusKm,
    required this.savedSearchRadiusKm,
    this.saveStatus = SearchRadiusSaveStatus.idle,
    this.errorMessage,
  });

  bool get hasUnsavedRadius => searchRadiusKm != savedSearchRadiusKm;

  DriverSettingsState copyWith({
    int? searchRadiusKm,
    int? savedSearchRadiusKm,
    SearchRadiusSaveStatus? saveStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DriverSettingsState(
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      savedSearchRadiusKm: savedSearchRadiusKm ?? this.savedSearchRadiusKm,
      saveStatus: saveStatus ?? this.saveStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    searchRadiusKm,
    savedSearchRadiusKm,
    saveStatus,
    errorMessage,
  ];
}
