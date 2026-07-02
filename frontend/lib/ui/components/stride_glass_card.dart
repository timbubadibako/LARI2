import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/stride_colors.dart';

class StrideGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;
  final Color? glowColor;
  final double blur;
  final double opacity;

  const StrideGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.borderRadius = 24.0,
    this.borderColor,
    this.glowColor,
    this.blur = 30.0,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: -5,
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: StrideColors.glassBase.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? StrideColors.glassBorder,
                width: 1.0,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
