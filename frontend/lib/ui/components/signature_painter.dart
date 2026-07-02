import 'package:flutter/material.dart';
import '../theme/stride_colors.dart';

class SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;
  final double strokeWidth;
  final bool showGlow;
  final double scale;

  SignaturePainter({
    required this.strokes,
    this.color = StrideColors.neonGreen,
    this.strokeWidth = 4.0,
    this.showGlow = true,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = (strokeWidth + 6.0) * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.save();
    // We don't apply scale here directly to the canvas if we want to scale points manually, 
    // but scaling canvas is easier.
    // However, if we scale canvas, we need to know the original bounds.
    
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path();
      path.moveTo(stroke[0].dx * scale, stroke[0].dy * scale);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx * scale, stroke[i].dy * scale);
      }
      if (showGlow) {
        canvas.drawPath(path, glowPaint);
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) => true;
}
