import 'package:flutter/material.dart';

/// Centralized brand colors for Solodev
/// Primary brand: #1565C0 (Vibrant futuristic blue)
class AppColors {
  AppColors._();

  // Primary Futuristic Blue
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF0D47A1);

  // Accent Cyan for high-tech micro-highlights
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentNeon = Color(0xFF00B0FF);

  // Dark Theme Palette (Deep Navy / Dark Charcoal)
  static const Color darkBackground = Color(0xFF0A0E17);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF161F30);
  static const Color darkCardBorder = Color(0x3338BDF8);
  static const Color darkGlass = Color(0x221E293B);

  // Light Theme Palette (Clean, Professional, Soft Gray)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightGlass = Color(0xCCFFFFFF);

  // Neutral Accents
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0x331565C0), Color(0x1100E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    colors: [Color(0xFF0A0E17), Color(0xFF111827), Color(0xFF0A0E17)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Centralized layout constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Solodev';
  static const String appTagline = 'Flutter Developer & AI Designer';
  static const String appSubheading =
      'Building modern mobile, web and AI-powered digital experiences with cross-platform excellence.';

  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;

  /// Below this width the public navigation collapses into an overflow menu.
  static const double wideNavBreakpoint = 1200.0;

  // Max content width
  static const double maxContentWidth = 1200.0;
  static const double maxFormWidth = 600.0;

  // Spacings
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusFull = 999.0;
}
