import 'dart:math' as math;
import 'package:flutter/material.dart';

class StaticCartoMap extends StatelessWidget {
  final double centerLat;
  final double centerLng;
  final int zoom;
  final bool isLightMode;

  const StaticCartoMap({
    super.key,
    required this.centerLat,
    required this.centerLng,
    this.zoom = 15,
    this.isLightMode = false,
  });

  int _lng2tile(double lon, int z) {
    return ((lon + 180.0) / 360.0 * math.pow(2, z)).floor();
  }

  int _lat2tile(double lat, int z) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * math.pow(2, z)).floor();
  }

  @override
  Widget build(BuildContext context) {
    final centerX = _lng2tile(centerLng, zoom);
    final centerY = _lat2tile(centerLat, zoom);
    
    final baseUrl = isLightMode 
        ? 'https://basemaps.cartocdn.com/light_all'
        : 'https://basemaps.cartocdn.com/dark_all';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tile size is 256
        const double tileSize = 256.0;
        
        // Calculate exact pixel offset of centerLat/centerLng within the center tile
        final num n = math.pow(2, zoom);
        final x = ((centerLng + 180.0) / 360.0) * n;
        final latRad = centerLat * math.pi / 180.0;
        final y = (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n;
        
        final offsetX = (x - centerX) * tileSize;
        final offsetY = (y - centerY) * tileSize;
        
        final viewWidth = constraints.maxWidth;
        final viewHeight = constraints.maxHeight;
        
        // Offset to center the centerLat/centerLng in the view
        final shiftX = (viewWidth / 2.0) - offsetX;
        final shiftY = (viewHeight / 2.0) - offsetY;

        return ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: shiftX - tileSize,
                top: shiftY - tileSize,
                width: tileSize * 3,
                height: tileSize * 3,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    final dx = (index % 3) - 1;
                    final dy = (index ~/ 3) - 1;
                    final url = '$baseUrl/$zoom/${centerX + dx}/${centerY + dy}.png';
                    return Image.network(
                      url, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isLightMode ? const Color(0xFFF0F0F5) : const Color(0xFF0A0A0B),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
