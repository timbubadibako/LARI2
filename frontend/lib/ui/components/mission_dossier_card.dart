import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../../ui/theme/stride_colors.dart';
import '../../../ui/theme/stride_typography.dart';
import '../../../ui/components/v3_shapes.dart';
import '../../../ui/components/route_preview_painter.dart';

class MissionDossierCard extends StatelessWidget {
  final String id;
  final String title;
  final String status;
  final double distanceKm;
  final int durationSec;
  final DateTime createdAt;
  final String? pathWkt;
  final Color statusColor;
  final bool isPendingSync;
  final VoidCallback onTap;

  const MissionDossierCard({
    super.key,
    required this.id,
    required this.title,
    required this.status,
    required this.distanceKm,
    required this.durationSec,
    required this.createdAt,
    this.pathWkt,
    required this.statusColor,
    this.isPendingSync = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCaptured = status.toLowerCase() == 'captured';
    final dateStr = '${createdAt.day}_${_monthName(createdAt.month)}_${createdAt.year}'.toUpperCase();

    final paceSec = distanceKm > 0 ? (durationSec / distanceKm) : 0.0;
    final pace = paceSec > 0 
        ? '${(paceSec / 60).floor().toString().padLeft(2, '0')}:${(paceSec % 60).floor().toString().padLeft(2, '0')}' 
        : '--:--';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border(left: BorderSide(color: statusColor, width: 4)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: _buildRoutePreview(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(dateStr, style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: Colors.white24)),
                            const Spacer(),
                            if (isPendingSync) ...[
                              V3SkewBox(
                                skewAmount: -0.1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  color: StrideColors.warning,
                                  child: Text('SYNC PENDING', style: StrideTypography.labelBold.copyWith(fontSize: 7, color: Colors.black)),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            V3SkewBox(
                              skewAmount: -0.1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                color: isCaptured ? StrideColors.neonGreen : Colors.white12,
                                child: Text(
                                  isCaptured ? 'TERRITORY' : 'ROUTE',
                                  style: StrideTypography.labelBold.copyWith(fontSize: 7, color: isCaptured ? Colors.black : Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StrideTypography.headlineMD.copyWith(fontSize: 18, letterSpacing: 0),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _miniStat('DIST', '${distanceKm.toStringAsFixed(1)}KM'),
                            const SizedBox(width: 20),
                            _miniStat('PACE', pace),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutePreview() {
    if (pathWkt == null || !pathWkt!.startsWith('LINESTRING')) {
      return Container(color: Colors.white12, child: const Icon(Icons.route, color: Colors.white24));
    }

    final points = _parseWKT(pathWkt!);
    return Container(
      color: Colors.black,
      child: CustomPaint(
        painter: RoutePreviewPainter(
          points: points,
          color: statusColor, // Dynamically use the passed statusColor
        ),
      ),
    );
  }

  List<latlong.LatLng> _parseWKT(String wkt) {
    try {
      final content = wkt.replaceAll('LINESTRING(', '').replaceAll(')', '');
      final pairs = content.split(',');
      return pairs.map((pair) {
        final parts = pair.trim().split(' ');
        return latlong.LatLng(double.parse(parts[1]), double.parse(parts[0]));
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: Colors.white24)),
        Text(value, style: StrideTypography.displayXL.copyWith(fontSize: 16, color: StrideColors.white)),
      ],
    );
  }

  String _monthName(int month) {
    const names = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];
    return names[month - 1];
  }
}
