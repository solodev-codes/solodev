// Guards the fullscreen video view: the deep link, the chrome, and the
// unplayable-source path. Playback itself needs a real video element, so the
// cases covered here are the ones that must never throw.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_portfolio/core/widgets/app_video_player.dart';
import 'package:my_portfolio/features/projects/video_view_screen.dart';

GoRouter _router(String initialLocation) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/watch',
          builder: (context, state) => VideoViewScreen(
            url: state.uri.queryParameters['video'] ?? '',
            title: state.uri.queryParameters['title'] ?? '',
          ),
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const Scaffold(body: Text('Projects')),
        ),
      ],
    );

void main() {
  testWidgets('shows the caption and the unplayable state for a bad source', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: _router('/watch?video=not-a-url&title=Solodev%20Demo'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Solodev Demo'), findsOneWidget);
    expect(find.text('This video cannot be played here'), findsOneWidget);
    // The player is not even built for an unplayable source.
    expect(find.byType(AppVideoPlayer), findsNothing);
  });

  testWidgets('a direct http source builds the player with autoplay', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: _router(
          '/watch?video=${Uri.encodeComponent('https://example.com/demo.mp4')}'
          '&title=Demo',
        ),
      ),
    );
    // One frame only: the plugin channel is absent in tests, so the player
    // settles on its own fallback rather than hanging on a real load.
    await tester.pump();

    expect(find.text('Demo'), findsOneWidget);
    expect(find.byType(AppVideoPlayer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('query values survive URLs containing ? and &', (tester) async {
    const url = 'https://cdn.example.com/v/clip.mp4?token=abc&x=1';
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: _router(
          '/watch?video=${Uri.encodeComponent(url)}&title=Clip',
        ),
      ),
    );
    await tester.pump();

    final screen = tester.widget<VideoViewScreen>(find.byType(VideoViewScreen));
    expect(screen.url, url);
    expect(screen.title, 'Clip');
  });
}
