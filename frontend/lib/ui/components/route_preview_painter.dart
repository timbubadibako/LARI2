import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong;

class RoutePreviewPainter extends CustomPainter {
  final List<latlong.LatLng> points;
  final Color color;

  RoutePreviewPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    final scale = min(
      size.width / (lngRange == 0 ? 1 : lngRange),
      size.height / (latRange == 0 ? 1 : latRange),
    );

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (points[i].longitude - minLng) * scale + (size.width - lngRange * scale) / 2;
      final y = size.height - ((points[i].latitude - minLat) * scale + (size.height - latRange * scale) / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RoutePreviewPainter oldDelegate) => true;
}
