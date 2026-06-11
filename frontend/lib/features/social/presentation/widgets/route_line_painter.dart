import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/domain/models/position_sample.dart';

class RouteLinePainter extends CustomPainter {
  final List<PositionSample> points;
  final bool drawGrid;
  final bool isLightMode;
  final int zoom;
  final Color? accentColor;

  RouteLinePainter({
    required this.points,
    this.drawGrid = true,
    this.isLightMode = false,
    this.zoom = 15,
    this.accentColor,
  });

  double _lng2pixel(double lon, int z) {
    return ((lon + 180.0) / 360.0 * math.pow(2, z) * 256.0);
  }

  double _lat2pixel(double lat, int z) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 -
            math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
        2.0 *
        math.pow(2, z) *
        256.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final primaryColor =
        accentColor ?? (isLightMode ? AppTheme.obsidian : AppTheme.sapphire);

    // Draw Cyber-Grid background
    if (drawGrid) {
      final gridPaint = Paint()
        ..color = primaryColor.withOpacity(isLightMode ? 0.05 : 0.1)
        ..strokeWidth = 1.0;

      for (double i = 0; i < size.width; i += 20) {
        canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
      }
      for (double i = 0; i < size.height; i += 20) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
      }
    }

    // Determine bounds to find center
    double minLat = points.first.lat;
    double maxLat = points.first.lat;
    double minLng = points.first.lng;
    double maxLng = points.first.lng;

    for (var p in points) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    double centerX = _lng2pixel(centerLng, zoom);
    double centerY = _lat2pixel(centerLat, zoom);

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final px = _lng2pixel(p.lng, zoom);
      final py = _lat2pixel(p.lat, zoom);

      final x = size.width / 2.0 + (px - centerX);
      final y = size.height / 2.0 + (py - centerY);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Polygon Cover / Fill
    final fillPath = Path.from(path);
    // Directly close the path back to the start point
    fillPath.close();

    final fillPaint = Paint()
      ..color = primaryColor.withOpacity(isLightMode ? 0.1 : 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = isLightMode ? 3.0 : 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Add glow
    if (!isLightMode) {
      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(0.4)
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, glowPaint);
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
