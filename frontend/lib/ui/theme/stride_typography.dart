import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'stride_colors.dart';

class StrideTypography {
  // Primary Headlines & Metrics: Bebas Neue
  static TextStyle displayXL = GoogleFonts.bebasNeue(
    fontSize: 84,
    height: 0.9,
    letterSpacing: -1,
    color: StrideColors.textPrimary,
  );

  static TextStyle headlineLG = GoogleFonts.bebasNeue(
    fontSize: 48,
    height: 1.0,
    letterSpacing: 1.5,
    color: StrideColors.textPrimary,
  );

  static TextStyle headlineMD = GoogleFonts.bebasNeue(
    fontSize: 32,
    letterSpacing: 2.0,
    color: StrideColors.textPrimary,
  );

  // Technical Labels: JetBrains Mono
  static TextStyle labelTactical = GoogleFonts.jetBrainsMono(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 3.0,
    color: StrideColors.neonGreen,
  );

  static TextStyle labelBold = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: StrideColors.textPrimary,
  );

  // Body Content: Space Grotesk
  static TextStyle bodyLG = GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: StrideColors.textPrimary,
  );

  static TextStyle bodyMD = GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: StrideColors.textSecondary,
  );

  // Buttons: Bebas Neue
  static TextStyle buttonText = GoogleFonts.bebasNeue(
    fontSize: 20,
    letterSpacing: 2.5,
    color: StrideColors.background,
  );

  // Graffiti Elements: Permanent Marker
  static TextStyle graffitiStyle = GoogleFonts.permanentMarker(
    fontSize: 48,
    color: StrideColors.neonGreen,
  );

  static TextStyle metricSmall = GoogleFonts.bebasNeue(
    fontSize: 28,
    letterSpacing: 1.0,
    color: StrideColors.textPrimary,
  );
}
