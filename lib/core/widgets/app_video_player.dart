import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../constants/app_colors.dart';

/// Modern custom video player used for project demos (spec section 13).
///
/// Plays direct video URLs (`https://…/demo.mp4`) with an overlay play/pause
/// control, a scrubable progress bar and a mute toggle. Works on Android, iOS
/// and web via the `video_player` plugin; embed URLs (YouTube/Vimeo) are not
/// supported by the plugin, so a failed load offers an "open in browser"
/// fallback instead of failing silently.
class AppVideoPlayer extends StatefulWidget {
  const AppVideoPlayer({
    super.key,
    required this.url,
    this.aspectRatio = 16 / 9,
    this.autoPlay = false,
  });

  final String url;

  /// Fallback aspect ratio used before the video metadata loads.
  final double aspectRatio;

  /// Starts playback as soon as the video is ready. Off by default so an
  /// embedded player never starts making noise on its own; the fullscreen
  /// viewer turns it on.
  final bool autoPlay;

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initializing = true;
  bool _failed = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uri = Uri.tryParse(widget.url.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      setState(() {
        _initializing = false;
        _failed = true;
      });
      return;
    }
    VideoPlayerController? controller;
    try {
      // Created inside the guard: if the platform channel is unavailable the
      // constructor itself throws, and that must degrade to the fallback rather
      // than take down the page.
      controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onFrame);
      if (widget.autoPlay) {
        // Autoplay may be refused until the first user interaction on some
        // mobile browsers; the play button remains available either way.
        await controller.play();
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (_) {
      await controller?.dispose();
      if (mounted) {
        setState(() {
          _initializing = false;
          _failed = true;
        });
      }
    }
  }

  /// Rebuilds the overlay so the progress bar tracks playback.
  void _onFrame() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onFrame);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.url.trim());
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Best-effort: never crash the detail page.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: const ColoredBox(
          color: AppColors.darkSurface,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_failed || _controller == null) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: ColoredBox(
          color: AppColors.darkSurface,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_outlined,
                    color: AppColors.textSecondaryDark, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Preview unavailable in the player.',
                  style: TextStyle(color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _openExternally,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Open video in browser'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = _controller!;
    final value = controller.value;

    return AspectRatio(
      aspectRatio:
          value.aspectRatio == 0 ? widget.aspectRatio : value.aspectRatio,
      child: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            if (_showControls) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  iconSize: 48,
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                    setState(() {});
                  },
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Row(
                    children: [
                      Text(
                        '${_format(value.position)} / ${_format(value.duration)}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: AppColors.accentCyan,
                            bufferedColor: Colors.white30,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: value.volume > 0 ? 'Mute' : 'Unmute',
                        icon: Icon(
                          value.volume > 0
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          controller.setVolume(value.volume > 0 ? 0 : 1);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}