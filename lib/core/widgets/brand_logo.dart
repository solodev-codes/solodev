import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The Solodev mark, shown everywhere the product identity appears.
///
/// The artwork is a transparent-background PNG (see `tool/build_logo_assets.dart`)
/// that already fills its own canvas edge-to-edge, so this widget adds nothing
/// around it: no padding, no plate, no border. Only the corners are rounded, and
/// with [ClipRRect] — a `Container` with a `borderRadius` does **not** clip its
/// child, which is exactly what left visible gaps and hard square corners
/// behind the artwork in an earlier version.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 36, this.glow = false});

  /// Location of the bundled artwork.
  static const String assetPath = 'assets/images/solodev_mark.png';

  final double size;

  /// Adds a soft halo, used where the mark is the focal point.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        // A missing or corrupt asset must never break the navigation bar.
        errorBuilder: (_, __, ___) => Icon(
          Icons.code_rounded,
          color: AppColors.accentCyan,
          size: size * 0.5,
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

/// The large hero mark: the same artwork with a halo, so the homepage leads with
/// the brand.
class BrandHeroMark extends StatelessWidget {
  const BrandHeroMark({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: BrandLogo(size: size, glow: true),
    );
  }
}
