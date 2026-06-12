import 'package:flutter/material.dart';

/// A clipper that creates a parallel slant effect.
/// [slantWidth] is the horizontal offset for the slant in pixels.
/// [isRightSlant] if true, slants the right side (Level Patch style).
/// [isLeftSlant] if true, slants the left side (Name Patch style).
class SlantClipper extends CustomClipper<Path> {
  final double slantWidth;
  final bool isRightSlant;
  final bool isLeftSlant;

  SlantClipper({
    this.slantWidth = 30.0,
    this.isRightSlant = false,
    this.isLeftSlant = false,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    double endX = size.width;

    if (isLeftSlant) {
      path.moveTo(slantWidth, 0);
      path.lineTo(endX, 0);
      path.lineTo(endX, size.height);
      path.lineTo(0, size.height);
    } else if (isRightSlant) {
      path.moveTo(0, 0);
      path.lineTo(endX, 0);
      path.lineTo(endX - slantWidth, size.height);
      path.lineTo(0, size.height);
    } else {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

/// A widget that applies a parallel slant to its child.
class V3SlantBox extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double slantWidth;
  final bool isRightSlant;
  final bool isLeftSlant;
  final BorderSide? border;

  const V3SlantBox({
    super.key,
    required this.child,
    this.color,
    this.slantWidth = 30.0,
    this.isRightSlant = false,
    this.isLeftSlant = false,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: SlantClipper(
        slantWidth: slantWidth,
        isRightSlant: isRightSlant,
        isLeftSlant: isLeftSlant,
      ),
      child: Container(
        color: color,
        child: child,
      ),
    );
  }
}

/// A generic skewed box for buttons and other UI elements.
class V3SkewBox extends StatelessWidget {
  final Widget child;
  final double skewAmount;

  const V3SkewBox({
    super.key,
    required this.child,
    this.skewAmount = -0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.skewX(skewAmount),
      child: child,
    );
  }
}

class HazardStripePainter extends CustomPainter {
  final Color color;
  final double stripeWidth;

  HazardStripePainter({required this.color, this.stripeWidth = 10.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double i = -size.height; i < size.width; i += stripeWidth * 2) {
      final path = Path();
      path.moveTo(i, size.height);
      path.lineTo(i + stripeWidth, size.height);
      path.lineTo(i + stripeWidth + size.height, 0);
      path.lineTo(i + size.height, 0);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class V3HazardBar extends StatelessWidget {
  final double height;
  final Color color;

  const V3HazardBar({
    super.key,
    this.height = 12,
    this.color = const Color(0xFFCCFF00),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: HazardStripePainter(color: color),
      ),
    );
  }
}
