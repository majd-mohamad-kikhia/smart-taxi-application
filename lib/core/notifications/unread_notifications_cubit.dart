import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// How many notifications the customer has not read yet, for the bell's
/// badge. One count for the whole app: the notifications screen sets it as
/// it loads and as notifications are read, and anything else can ask for a
/// [refresh]. The count itself comes from [_fetchCount], supplied where the
/// app is wired together, so this stays free of any feature.
class UnreadNotificationsCubit extends Cubit<int> {
  final Future<int> Function() _fetchCount;

  UnreadNotificationsCubit(this._fetchCount) : super(0);

  /// Asks the server for the current count. A failure keeps the count shown
  /// (a badge is a hint, not worth an error message).
  Future<void> refresh() async {
    try {
      final count = await _fetchCount();
      if (!isClosed) emit(count < 0 ? 0 : count);
    } catch (error) {
      debugPrint('UnreadNotificationsCubit: refresh failed: $error');
    }
  }

  void set(int count) {
    if (!isClosed) emit(count < 0 ? 0 : count);
  }
}
