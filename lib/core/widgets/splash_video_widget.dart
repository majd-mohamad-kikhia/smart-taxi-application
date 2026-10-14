import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../splash/splash_signal.dart';
import '../theme/app_colors.dart';
import 'app_splash_widget.dart';

/// The app's splash: the intro video, full screen on black, with its sound,
/// played once while the app starts up. The system bars are hidden while it
/// plays, so the picture is centered on the whole screen. [signal] is
/// finished when the video ends,
/// when it is tapped (skip), or when it cannot play — in which case the
/// still logo splash stands in, so the app is never held up by a broken video.
class SplashVideoWidget extends StatefulWidget {
  static const asset = 'assets/videos/smart_taxi_splash_green_5s.mp4';

  /// The car in the video sits a little left of its frame's middle (measured:
  /// the headlights' middle is at 48–49% of the width); this nudges it back,
  /// as a share of the screen's width.
  static const _centerNudge = 0.015;

  final SplashSignal signal;

  const SplashVideoWidget({super.key, required this.signal});

  @override
  State<SplashVideoWidget> createState() => _SplashVideoWidgetState();
}

class _SplashVideoWidgetState extends State<SplashVideoWidget> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _controller = VideoPlayerController.asset(
      SplashVideoWidget.asset,
      // Mixes with whatever is playing: a splash must not stop the user's music.
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller.addListener(_onTick);
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      await _controller.initialize();
      await _controller.setVolume(1);
      await _controller.play();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      debugPrint('SplashVideoWidget: the video could not play: $e');
      _fail();
    }
  }

  void _onTick() {
    final value = _controller.value;
    if (value.hasError) return _fail();
    if (value.isInitialized &&
        value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 80)) {
      widget.signal.finish();
    }
  }

  void _fail() {
    widget.signal.finish();
    if (mounted && !_failed) setState(() => _failed = true);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    // Back to the app's own system bars.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const AppSplashWidget();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // A tap skips the rest of the video (the app still waits for its own
      // startup work).
      onTap: widget.signal.finish,
      child: ColoredBox(
        color: AppColors.black,
        child: SizedBox.expand(
          child: _ready
              // The whole picture, centered; the video's black background
              // makes the bars above and below it invisible.
              ? FractionalTranslation(
                  translation: const Offset(SplashVideoWidget._centerNudge, 0),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
