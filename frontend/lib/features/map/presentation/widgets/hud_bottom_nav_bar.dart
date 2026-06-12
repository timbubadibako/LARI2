import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';

class HudBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String modeName;

  const HudBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.modeName = 'MODE: ROGUE_MOVEMENT',
  });

  @override
  State<HudBottomNavBar> createState() => _HudBottomNavBarState();
}

class _HudBottomNavBarState extends State<HudBottomNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _wobbleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _wobbleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(HudBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. THE HARD NEON SHADOW (OFFSET)
                Positioned(
                  top: 8,
                  left: 8,
                  right: -8,
                  bottom: -8,
                  child: Transform(
                    transform: Matrix4.skewX(0.05)..rotateZ(-0.02),
                    child: Container(
                      color: StrideColors.neonGreen.withOpacity(0.5),
                    ),
                  ),
                ),

                // 2. THE MAIN BAR
                Transform(
                  transform: Matrix4.skewX(0.05)..rotateZ(-0.02),
                  child: Container(
                    padding: const EdgeInsets.all(2), // White border width
                    color: StrideColors.white,
                    child: Container(
                      color: StrideColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (index) {
                          final isActive = widget.currentIndex == index;
                          return GestureDetector(
                            onTap: () => widget.onTap(index),
                            behavior: HitTestBehavior.opaque,
                            child: _buildRogueIcon(index, isActive),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 3. THE TACTICAL BADGE (BOTTOM RIGHT)
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.4),
          child: Align(
            alignment: Alignment.centerRight,
            child: Transform(
              transform: Matrix4.skewX(-0.2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: StrideColors.neonGreen,
                child: Text(
                  widget.modeName,
                  style: StrideTypography.labelBold.copyWith(
                    fontSize: 8,
                    color: StrideColors.background,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRogueIcon(int index, bool isActive) {
    final color = isActive ? StrideColors.neonGreen : StrideColors.white;
    final opacity = isActive ? 1.0 : 0.4;
    
    Widget iconWidget;
    switch (index) {
      case 0: // Triangle (Segitiga)
        iconWidget = CustomPaint(
          size: const Size(18, 18),
          painter: TrianglePainter(color: color.withOpacity(opacity), isSolid: isActive),
        );
        break;
      case 1: // Square (Kotak)
        iconWidget = Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            border: Border.all(color: color.withOpacity(opacity), width: 2),
          ),
        );
        break;
      case 2: // Cross (X)
        iconWidget = CustomPaint(
          size: const Size(16, 16),
          painter: CrossPainter(color: color.withOpacity(opacity), strokeWidth: 2.5),
        );
        break;
      case 3: // Circle (Bulat)
      default:
        iconWidget = Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(opacity), width: 2),
          ),
        );
    }

    return AnimatedBuilder(
      animation: _wobbleAnimation,
      builder: (context, child) {
        final double steadyRotation = isActive ? (12 * math.pi / 180) : 0;
        final double wobbleRotation = isActive ? _wobbleAnimation.value : 0;

        return Transform.rotate(
          angle: steadyRotation + wobbleRotation,
          child: SizedBox(
            width: 50,
            child: Center(child: iconWidget),
          ),
        );
      },
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  final bool isSolid;

  TrianglePainter({required this.color, this.isSolid = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = isSolid ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CrossPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  CrossPainter({required this.color, this.strokeWidth = 2.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
