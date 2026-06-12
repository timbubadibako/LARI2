import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Custom location marker with cyan core, pulse ring, heading cone, and accuracy circle
class CustomLocationMarker extends StatefulWidget {
  final double size;
  final bool showHeadingCone;
  final double? headingDegrees;
  final double? accuracyRadiusScreenPx;
  final bool isAnimating;

  const CustomLocationMarker({
    super.key,
    this.size = 40,
    this.showHeadingCone = true,
    this.headingDegrees,
    this.accuracyRadiusScreenPx,
    this.isAnimating = true,
  });

  @override
  State<CustomLocationMarker> createState() => _CustomLocationMarkerState();
}

class RunningCharacterMarker extends StatelessWidget {
  final double size;
  final bool isAnimating;

  const RunningCharacterMarker({
    super.key,
    this.size = 40,
    this.isAnimating = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomLocationMarker(
      size: size,
      showHeadingCone: false,
      isAnimating: isAnimating,
    );
  }
}

class _CustomLocationMarkerState extends State<CustomLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.isAnimating) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(CustomLocationMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!widget.isAnimating && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return SizedBox(
          width: widget.size + (widget.size * 0.5),
          height: widget.size + (widget.size * 0.5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Optional accuracy circle (very subtle dashed ring)
              if (widget.accuracyRadiusScreenPx != null)
                Transform.scale(
                  scale: widget.accuracyRadiusScreenPx! / widget.size,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.sapphire.withOpacity(0.12),
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                  ),
                ),

              // Pulse ring (expands and fades)
              Container(
                width:
                    widget.size + (widget.size * _pulseController.value * 0.5),
                height:
                    widget.size + (widget.size * _pulseController.value * 0.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.sapphire.withOpacity(
                      0.6 * (1.0 - _pulseController.value),
                    ),
                    width: 1.5,
                  ),
                ),
              ),

              // Heading cone (triangle pointing direction)
              if (widget.showHeadingCone && widget.headingDegrees != null)
                Transform.rotate(
                  angle: (widget.headingDegrees! * math.pi / 180),
                  child: Container(
                    width: 0,
                    height: 0,
                    decoration: const BoxDecoration(),
                    child: CustomPaint(
                      painter: _HeadingConePainter(
                        color: AppTheme.sapphire.withOpacity(0.4),
                        size: widget.size * 0.35,
                      ),
                      size: Size(widget.size * 0.7, widget.size * 0.7),
                    ),
                  ),
                ),

              // Core circle
              Container(
                width: widget.size * 0.4,
                height: widget.size * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.sapphire,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.sapphire.withOpacity(0.8),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: AppTheme.sapphire.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Paints a small heading cone (triangle) pointing in direction
class _HeadingConePainter extends CustomPainter {
  final Color color;
  final double size;

  _HeadingConePainter({required this.color, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final offsetX = canvasSize.width / 2;
    final offsetY = canvasSize.height / 2;

    // Triangle pointing up
    path.moveTo(offsetX, offsetY - size);
    path.lineTo(offsetX - size * 0.5, offsetY + size * 0.5);
    path.lineTo(offsetX + size * 0.5, offsetY + size * 0.5);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HeadingConePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.size != size;
  }
}
