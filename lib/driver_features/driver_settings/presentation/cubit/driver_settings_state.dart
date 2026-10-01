import 'package:equatable/equatable.dart';

enum SearchRadiusSaveStatus { idle, saving, success, failure }

class DriverSettingsState extends Equatable {
  final int searchRadiusKm;
  final SearchRadiusSaveStatus saveStatus;
  final String? errorMessage;

  const DriverSettingsState({
    required this.searchRadiusKm,
    this.saveStatus = SearchRadiusSaveStatus.idle,
    this.errorMessage,
  });

  DriverSettingsState copyWith({
    int? searchRadiusKm,
    SearchRadiusSaveStatus? saveStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DriverSettingsState(
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      saveStatus: saveStatus ?? this.saveStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [searchRadiusKm, saveStatus, errorMessage];
}
