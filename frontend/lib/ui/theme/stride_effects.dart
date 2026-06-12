import 'package:flutter/material.dart';
import 'stride_colors.dart';

class StrideEffects {
  static List<BoxShadow> neonGlow(Color color, {double opacity = 0.3}) {
    return [
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ];
  }

  static BoxDecoration glassCardDecoration({
    double blur = 30, 
    double opacity = 0.6,
    double borderRadius = 24,
  }) {
    return BoxDecoration(
      color: StrideColors.glassBase.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: StrideColors.glassBorder,
        width: 1.0,
      ),
    );
  }

  static BoxDecoration sapphireGlowDecoration() {
    return BoxDecoration(
      color: StrideColors.sapphire.withOpacity(0.1),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: StrideColors.sapphire.withOpacity(0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: StrideColors.sapphire.withOpacity(0.15),
          blurRadius: 30,
          spreadRadius: -5,
        )
      ],
    );
  }

  static BoxDecoration tacticalGoldGlow() {
    return BoxDecoration(
      color: StrideColors.gold.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: StrideColors.gold.withOpacity(0.3),
        width: 1.0,
      ),
    );
  }
}
