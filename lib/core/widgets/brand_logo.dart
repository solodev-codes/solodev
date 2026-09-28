import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The Solodev mark, shown everywhere the product identity appears.
///
/// The artwork is the untouched master from `assets/branding/`. It is not
/// square-filling: a 1080x1080 canvas in which the artwork occupies 894x894
/// starting at (90, 113), so drawing the whole canvas into a box leaves a
/// transparent margin — the "space" around the logo.
///
/// Two things fix that without touching the file:
///
/// 1. The canvas is magnified by [ContentFit.artworkZoom] and shifted by
///    [ContentFit] so the artwork — not the canvas — covers the box exactly.
/// 2. The result is clipped to the requested shape, so the logo takes on the
///    silhouette of whatever box or widget it is placed in.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 36,
    this.shape = BrandLogoShape.squircle,
    this.glow = false,
  });

  /// Location of the bundled master artwork.
  static const String assetPath = 'assets/branding/Solodev_logo_master.png';

  /// Width and height of the box the logo is drawn into.
  final double size;

  /// Silhouette applied to the artwork.
  final BrandLogoShape shape;

  /// Adds a soft halo, used where the mark is the focal point.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    // Side of the magnified canvas. Its artwork is then exactly `size` wide,
    // which is what removes the margin.
    final canvasSide = size * ContentFit.artworkZoom;

    final logo = ClipPath(
      clipper: _BrandClipper(shape),
      child: SizedBox.square(
        dimension: size,
        child: OverflowBox(
          // Park the magnified canvas at the top-left of the box; the clip
          // above then trims it back down to the box.
          alignment: Alignment.topLeft,
          minWidth: canvasSide,
          maxWidth: canvasSide,
          minHeight: canvasSide,
          maxHeight: canvasSide,
          child: Transform.translate(
            // Pull the artwork's own top-left onto the box's top-left.
            offset: Offset(
              -canvasSide * ContentFit.artworkLeftFraction,
              -canvasSide * ContentFit.artworkTopFraction,
            ),
            child: Image.asset(
              assetPath,
              width: canvasSide,
              height: canvasSide,
              // Square canvas into a square box, so filling cannot distort it.
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              // A missing or corrupt asset must never break the navigation bar.
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    if (!glow) return logo;

    return Container(
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.accentCyan.withValues(alpha: 0.20),
            AppColors.accentCyan.withValues(alpha: 0.0),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: logo,
    );
  }
}

/// Silhouettes the brand mark can take inside its box.
enum BrandLogoShape {
  /// A circle, for avatars and roundels.
  circle,

  /// A superellipse, matching modern launcher-icon geometry.
  squircle,

  /// A plain rectangle with no rounding.
  square,
}

/// Geometry of the master artwork, measured once from the 1080x1080 file.
///
/// The canvas is 1080 px square and the artwork occupies 894x894 starting at
/// (90, 113), so the mark sits slightly off-centre inside a transparent margin.
/// These four numbers are all that is needed to crop it at render time; no
/// derived or re-encoded image file is involved.
abstract final class ContentFit {
  static const double canvasPx = 1080;
  static const double artworkPx = 894;
  static const double artworkLeft = 90;
  static const double artworkTop = 113;

  /// Scale that magnifies the whole canvas until its artwork fills the box.
  static const double artworkZoom = canvasPx / artworkPx;

  /// The artwork's position within the canvas, as a fraction of its side.
  static const double artworkLeftFraction = artworkLeft / canvasPx;
  static const double artworkTopFraction = artworkTop / canvasPx;
}

/// Clips the logo to the requested silhouette.
class _BrandClipper extends CustomClipper<Path> {
  const _BrandClipper(this.shape);

  final BrandLogoShape shape;

  @override
  Path getClip(Size size) {
    switch (shape) {
      case BrandLogoShape.circle:
        return Path()
          ..addOval(Offset.zero & size);
      case BrandLogoShape.squircle:
        return Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Offset.zero & size,
              Radius.circular(size.shortestSide * 0.32),
            ),
          );
      case BrandLogoShape.square:
        return Path()..addRect(Offset.zero & size);
    }
  }

  @override
  bool shouldReclip(_BrandClipper oldClipper) => oldClipper.shape != shape;
}

/// The large hero mark: the same artwork with a halo, so the homepage leads with
/// the brand.
class BrandHeroMark extends StatelessWidget {
  const BrandHeroMark({super.key, this.size = 140, this.shape = BrandLogoShape.squircle});

  final double size;
  final BrandLogoShape shape;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: BrandLogo(size: size, shape: shape, glow: true),
    );
  }
}

