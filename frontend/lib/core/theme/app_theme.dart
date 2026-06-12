import 'package:flutter/material.dart';
import '../../ui/theme/stride_colors.dart';
import '../../ui/theme/stride_typography.dart';

class AppTheme {
  // Static color constants for backward compatibility
  static const Color sapphire = Color.fromRGBO(204, 255, 0, 1);
  static const Color background = StrideColors.background;
  static const Color obsidian = StrideColors.obsidian;
  static const Color glassBase = StrideColors.glassBase;
  static const Color secondary = StrideColors.secondary;
  static const Color error = StrideColors.error;
  static const Color surface = StrideColors.surface;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFCCFF00),
      scaffoldBackgroundColor: StrideColors.background,
      colorScheme: const ColorScheme.dark(
        primary: StrideColors.neonGreen,
        secondary: StrideColors.secondary,
        surface: StrideColors.surface,
        error: StrideColors.error,
        onSurface: StrideColors.textPrimary,
      ),
      fontFamily: 'Space Grotesk',
      textTheme: TextTheme(
        displayLarge: StrideTypography.displayXL,
        displayMedium: StrideTypography.headlineLG,
        titleLarge: StrideTypography.headlineMD,
        bodyLarge: StrideTypography.bodyLG,
        bodyMedium: StrideTypography.bodyMD,
        labelLarge: StrideTypography.labelTactical,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: StrideColors.white),
        titleTextStyle: StrideTypography.headlineMD.copyWith(fontSize: 24),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: StrideColors.neonGreen,
          foregroundColor: StrideColors.background,
          elevation: 0,
          textStyle: StrideTypography.buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Sharp edges in V3
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: StrideColors.outline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
