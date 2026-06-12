import 'package:flutter/material.dart';

class StrideColors {
  // Base Colors - The "Street Rebel" depth
  static const Color background = Color(0xFF000000); // Pure Black
  static const Color surface = Color(0xFF080808); // Deep Zinc
  static const Color obsidian = Color(0xFF000000);
  
  // Neon Palette - Primary branding V3
  static const Color neonGreen = Color(0xFFCCFF00);
  static const Color sapphire = Color(0xFFCCFF00); // Redirecting legacy sapphire to Neon Green
  static const Color sky = Color(0xFF00F0FF); // Electric Blue for accents
  
  // High Contrast Structural
  static const Color white = Color(0xFFFFFFFF);
  static const Color glassBase = Color(0xCC000000); // Heavy black glass
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white for sharp borders
  
  // Semantic / Functional
  static const Color success = Color(0xFFCCFF00); // Aligned with neon green
  static const Color warning = Color(0xFFFF5F00); // Inferno Orange
  static const Color error = Color(0xFFFF0000); // Infra Red
  
  // Accents
  static const Color secondary = Color(0xFFFF007A); // Ultra Pink
  static const Color gold = Color(0xFFFFF000); // High Volt Yellow
  
  // Neutral / Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color textMuted = Color(0xFF52525B); // Zinc 600
  static const Color outline = Color(0xFF27272A); // Zinc 800
}
