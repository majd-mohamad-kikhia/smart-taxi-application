import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/onboarding_local_data_source.dart';
import '../../data/models/onboarding_step.dart';

/// The onboarding's current page (0-based). Finishing or skipping it is
/// remembered on the device so the onboarding is only shown on the first
/// launch.
class OnboardingCubit extends Cubit<int> {
  final OnboardingLocalDataSource _local;

  OnboardingCubit(this._local) : super(0);

  bool get isLastPage => state == OnboardingStep.count - 1;

  void pageChanged(int page) => emit(page);

  /// Records that the onboarding was seen — call before leaving it, whether
  /// it was finished or skipped.
  Future<void> complete() => _local.markSeen();
}
