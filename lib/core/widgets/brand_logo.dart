import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The Solodev mark, shown everywhere the product identity appears.
///
/// The bundled logo already carries its own artwork, so the widget frames it in
/// a rounded brand tile with a soft cyan glow — that keeps it legible on every
/// dark surface without recolouring or clipping the artwork itself.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 36, this.glow = true});

  /// Location of the bundled artwork.
  static const String assetPath = 'assets/images/Solodev_logo.png';

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: AppColors.accentCyan.withValues(alpha: 0.18),
          width: size * 0.02,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.accentCyan.withValues(alpha: 0.22),
                  blurRadius: size * 0.45,
                  spreadRadius: size * 0.04,
                ),
              ]
            : null,
      ),
      child: Padding(
        // A hair of breathing room so artwork that touches the canvas edge is
        // not pressed against the tile border.
        padding: EdgeInsets.all(size * 0.06),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          // A missing or corrupt asset must never break the navigation bar.
          errorBuilder: (_, __, ___) => Icon(
            Icons.code_rounded,
            color: AppColors.accentCyan,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// The large hero mark: the same artwork, with a stronger halo and a gentle
/// entrance so the homepage leads with the brand.
class BrandHeroMark extends StatelessWidget {
  const BrandHeroMark({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 1.18,
      height: size * 1.18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.accentCyan.withValues(alpha: 0.22),
            AppColors.accentCyan.withValues(alpha: 0.0),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: BrandLogo(size: size),
    );
  }
}
