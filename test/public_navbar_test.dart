// Guards the public header: the brand title must build cleanly inside an AppBar.
//
// `AppBar` lays its title out in a box-based slot, so wrapping it in `Flexible`
// throws "Incorrect use of ParentDataWidget"; release builds then paint a grey
// box where the logo and wordmark should be. This test failed for that reason.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_portfolio/core/widgets/brand_logo.dart';
import 'package:my_portfolio/core/widgets/navigation_bars.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            appBar: PublicNavbar(),
            drawer: PublicDrawer(),
            body: SizedBox.shrink(),
          ),
        ),
      ],
    );

void main() {
  testWidgets('navbar renders the brand without a layout exception', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pumpAndSettle();

    // This is the assertion that caught the grey-box regression: a
    // ParentDataWidget misuse surfaces as an exception here, and as an unpainted
    // grey box in a release build.
    expect(tester.takeException(), isNull);
    expect(find.byType(BrandLogo), findsWidgets);
    // "SOLO" and "DEV" are two spans of one rich text, so match on the words.
    expect(find.textContaining('SOLO', findRichText: true), findsWidgets);
  });
}

