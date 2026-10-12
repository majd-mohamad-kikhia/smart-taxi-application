import 'dart:async';

/// Tells the startup code that the splash has been shown: its video ended, was
/// skipped with a tap, or could not play. The first real screen waits for it,
/// so a fast startup never cuts the splash short and a slow one never waits
/// for a splash that is already over.
class SplashSignal {
  final Completer<void> _done = Completer<void>();

  Future<void> get finished => _done.future;

  bool get isFinished => _done.isCompleted;

  /// Safe to call more than once.
  void finish() {
    if (!_done.isCompleted) _done.complete();
  }
}
