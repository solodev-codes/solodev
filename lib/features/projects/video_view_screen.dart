import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_video_player.dart';
import '../../core/widgets/app_widgets.dart';

/// Full-bleed video viewer for project demonstrations (spec section 13).
///
/// Reached through the router as `/watch?video=<url>&title=<title>`, so the
/// view is deep-linkable, survives a refresh and the browser back button closes
/// it. Playback itself is delegated to [AppVideoPlayer]; this screen supplies
/// the viewing chrome that only makes sense fullscreen: a black stage, the
/// system UI hidden on mobile, a title, and an escape hatch to the source.
class VideoViewScreen extends StatefulWidget {
  const VideoViewScreen({super.key, required this.url, this.title = ''});

  /// Direct video URL. Only `http(s)` is accepted.
  final String url;

  /// Optional caption, usually the project title.
  final String title;

  @override
  State<VideoViewScreen> createState() => _VideoViewScreenState();
}

class _VideoViewScreenState extends State<VideoViewScreen> {
  @override
  void initState() {
    super.initState();
    // Hides the status and navigation bars on mobile so the video owns the
    // screen. A no-op on web, and restored on the way out.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Only direct `http(s)` sources are played. Embed URLs (YouTube, Vimeo) and
  /// anything unparseable get an explanation instead of a broken stage.
  bool get _isPlayable {
    final uri = Uri.tryParse(widget.url.trim());
    return uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.url.trim());
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Best-effort: a blocked hand-off must not close the viewer.
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/projects');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isPlayable)
            Center(child: AppVideoPlayer(url: widget.url, autoPlay: true))
          else
            const _UnplayableSource(),
          _TopBar(
            title: widget.title,
            canOpenExternally: _isPlayable,
            onClose: _close,
            onOpenExternally: _openExternally,
          ),
        ],
      ),
    );
  }
}

/// Chrome layered over the stage, kept clear of the centre where the player's
/// own play button sits.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.canOpenExternally,
    required this.onClose,
    required this.onOpenExternally,
  });

  final String title;
  final bool canOpenExternally;
  final VoidCallback onClose;
  final VoidCallback onOpenExternally;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.72),
              Colors.black.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Close video',
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (canOpenExternally)
                  IconButton(
                    tooltip: 'Open in browser',
                    onPressed: onOpenExternally,
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      color: AppColors.accentCyan,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when the URL is missing, malformed, or an embed the plugin cannot play.
/// The player keeps its own "open in browser" fallback for a valid URL that
/// fails to load; this covers the remaining cases.
class _UnplayableSource extends StatelessWidget {
  const _UnplayableSource();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              color: AppColors.textSecondaryDark,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'This video cannot be played here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The link is missing or is not a direct video file. Hosted clips '
              '(YouTube, Vimeo) are not supported in the built-in player.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Back to Projects',
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.go('/projects'),
            ),
          ],
        ),
      ),
    );
  }
}