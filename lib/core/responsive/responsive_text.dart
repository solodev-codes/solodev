import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The device tiers every responsive decision in the app is based on.
///
/// Widths come from [AppConstants] so there is exactly one place that defines
/// where a phone stops being a phone.
enum AppSizeClass {
  /// Narrow phones (< 360 logical px).
  compact,

  /// Phones.
  phone,

  /// Tablets and small laptops.
  tablet,

  /// Laptops and desktops.
  laptop,

  /// Wide desktops.
  desktop,
}

/// Single source of truth for responsive type.
///
/// Screens declare a size in a neutral, laptop-shaped value and let this class
/// map it onto the current device. Applying [scaleSubtree] once at the app root
/// is what makes the declared `fontSize` values across the app adapt, admin
/// screens included, without touching each call site.
///
/// Rule for accessibility: the app only ever *reduces* text below the platform
/// setting. If someone has already enlarged their system font, that choice wins
/// and the device tier is not applied on top of it.
abstract final class ResponsiveText {
  /// The device tier for a viewport width.
  static AppSizeClass sizeClassOf(double width) {
    if (width < AppConstants.compactBreakpoint) return AppSizeClass.compact;
    if (width < AppConstants.mobileBreakpoint) return AppSizeClass.phone;
    if (width < AppConstants.tabletBreakpoint) return AppSizeClass.tablet;
    if (width < AppConstants.desktopBreakpoint) return AppSizeClass.laptop;
    return AppSizeClass.desktop;
  }

  /// Text multiplier for a device tier.
  ///
  /// Phones get smaller type so cards, rows and buttons fit; wide desktops get a
  /// touch more so a 1440 px screen does not look sparse.
  static double scaleFor(AppSizeClass sizeClass) {
    return switch (sizeClass) {
      AppSizeClass.compact => 0.88,
      AppSizeClass.phone => 0.94,
      AppSizeClass.tablet => 1.0,
      AppSizeClass.laptop => 1.0,
      AppSizeClass.desktop => 1.05,
    };
  }

  /// Text multiplier for the current viewport.
  static double scaleOf(BuildContext context) =>
      scaleFor(sizeClassOf(MediaQuery.sizeOf(context).width));

  /// Scales one explicit size, for the rare place that needs its own value
  /// instead of relying on the global scale.
  static double sizeOf(BuildContext context, double base) =>
      base * scaleOf(context);

  /// Columns for a responsive card grid.
  ///
  /// [max] is honoured from the laptop tier upwards, where there is room.
  static int gridColumns(BuildContext context, {int max = 3, int min = 1}) =>
      gridColumnsFor(MediaQuery.sizeOf(context).width, max: max, min: min);

  /// The same decision for a layout that already has a width, such as inside a
  /// [LayoutBuilder], where the widget tree width is not the viewport width.
  static int gridColumnsFor(double width, {int max = 3, int min = 1}) {
    return switch (sizeClassOf(width)) {
      AppSizeClass.compact => min,
      AppSizeClass.phone => math.max(min, math.min(max, 2)),
      AppSizeClass.tablet => math.max(min, math.min(max, 2)),
      AppSizeClass.laptop => max,
      AppSizeClass.desktop => max + 1,
    };
  }

  /// Wraps a subtree so all of its text scales with the device.
  ///
  /// Applied once in the app root rather than per screen, so a new screen is
  /// responsive by default instead of by remembering to opt in.
  static Widget scaleSubtree(BuildContext context, Widget child) {
    final media = MediaQuery.of(context);
    // 1.0 unless the platform reports a custom text size.
    final platformScale = media.textScaler.scale(1);
    final deviceScale = scaleOf(context);
    // Strictly greater than 1: a platform scale of exactly 1.0 means "no
    // preference", not "the user chose not to scale", so the device tier still
    // applies. Anything above 1.0 is a deliberate accessibility choice.
    final effective =
        platformScale > 1.0 ? platformScale : platformScale * deviceScale;

    if ((effective - platformScale).abs() < 0.001) return child;
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(effective)),
      child: child,
    );
  }
}
