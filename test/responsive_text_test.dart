// Guards the shared breakpoint table and the device type scale.
//
// This is the mechanism that makes every screen's declared font sizes adapt, so
// its rules are worth pinning: phones shrink, wide desktops grow, and an
// enlarged platform font setting is never overridden.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_portfolio/core/responsive/responsive_text.dart';

void main() {
  group('size classes', () {
    test('map widths to the documented tiers', () {
      expect(ResponsiveText.sizeClassOf(320), AppSizeClass.compact);
      expect(ResponsiveText.sizeClassOf(390), AppSizeClass.phone);
      expect(ResponsiveText.sizeClassOf(599), AppSizeClass.phone);
      expect(ResponsiveText.sizeClassOf(600), AppSizeClass.tablet);
      expect(ResponsiveText.sizeClassOf(834), AppSizeClass.tablet);
      expect(ResponsiveText.sizeClassOf(1024), AppSizeClass.laptop);
      expect(ResponsiveText.sizeClassOf(1440), AppSizeClass.desktop);
      expect(ResponsiveText.sizeClassOf(2560), AppSizeClass.desktop);
    });

    test('type grows monotonically with the device', () {
      double scaleAt(double width) =>
          ResponsiveText.scaleFor(ResponsiveText.sizeClassOf(width));
      expect(scaleAt(320), lessThan(scaleAt(390)));
      expect(scaleAt(390), lessThan(scaleAt(834)));
      expect(scaleAt(834), lessThanOrEqualTo(scaleAt(1440)));
      expect(scaleAt(1440), greaterThan(scaleAt(834)));
    });
  });

  group('grid columns', () {
    test('never exceed max and always keep min', () {
      for (final width in [320.0, 390.0, 768.0, 1280.0, 1920.0]) {
        final columns = ResponsiveText.gridColumnsFor(width, max: 4);
        expect(columns, greaterThanOrEqualTo(1));
        expect(columns, lessThanOrEqualTo(5));
      }
    });

    test('a phone shows fewer columns than a desktop', () {
      expect(
        ResponsiveText.gridColumnsFor(390, max: 4),
        lessThan(ResponsiveText.gridColumnsFor(1920, max: 4)),
      );
    });
  });

  group('scaleSubtree', () {
    Future<TextScaler> scalerInside(
      WidgetTester tester, {
      required Size size,
      TextScaler platform = TextScaler.noScaling,
    }) async {
      final completer = Completer<TextScaler>();
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size, textScaler: platform),
          child: Builder(
            builder: (context) => ResponsiveText.scaleSubtree(
              context,
              Builder(
                builder: (inner) {
                  if (!completer.isCompleted) {
                    completer.complete(MediaQuery.of(inner).textScaler);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      return completer.future;
    }

    testWidgets('shrinks text below the platform setting on a phone', (
      tester,
    ) async {
      final scaler = await scalerInside(tester, size: const Size(390, 800));
      // A phone shrinks type by 0.94 so rows and cards fit.
      expect(scaler.scale(10), closeTo(9.4, 0.001));
    });

    testWidgets('leaves text alone on a tablet', (tester) async {
      final scaler = await scalerInside(tester, size: const Size(834, 1000));
      expect(scaler.scale(10), closeTo(10, 0.001));
    });

    testWidgets('never overrides an enlarged platform setting', (
      tester,
    ) async {
      final scaler = await scalerInside(
        tester,
        size: const Size(390, 800),
        platform: const TextScaler.linear(1.5),
      );
      // Accessibility wins: 1.5 stays 1.5 and is not multiplied down to 1.41.
      expect(scaler.scale(10), closeTo(15, 0.001));
    });
  });
}
