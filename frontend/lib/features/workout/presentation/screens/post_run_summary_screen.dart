import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/app_strings.dart';
import '../../../map/presentation/widgets/stride_map_view.dart';
import '../../../map/application/current_address_provider.dart';
import '../../../../core/domain/models/workout_session.dart';
import '../../../../core/domain/models/run_history.dart';

class PostRunSummaryScreen extends ConsumerStatefulWidget {
  final WorkoutSession? workout;
  final RunHistory? missionOverride;
  const PostRunSummaryScreen({super.key, this.workout, this.missionOverride});

  @override
  ConsumerState<PostRunSummaryScreen> createState() => _PostRunSummaryScreenState();
}

class _PostRunSummaryScreenState extends ConsumerState<PostRunSummaryScreen> {
  void _handleNexusReturn() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _shareMission() {
    final workout = widget.workout;
    final mission = widget.missionOverride;

    final dist = workout != null
        ? (workout.distanceMeters / 1000).toStringAsFixed(2)
        : mission?.distanceKm.toStringAsFixed(2) ?? '0.00';

    final duration = workout?.durationSeconds ?? mission?.durationSec ?? 0;
    final time = '${(duration / 60).floor()}m ${duration % 60}s';

    Share.share(
      'RUN SUMMARY: Captured $dist KM in $time. \nJoin the LARI movement and reclaim your city! 🚀🏙️',
      subject: 'LARI Run Summary',
    );
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;
    final mission = widget.missionOverride;
    final isReplay = mission != null;

    List<latlong.LatLng> replayPath = [];
    if (isReplay && mission.pathWkt != null && mission.pathWkt!.startsWith('LINESTRING')) {
      replayPath = _parseWKT(mission.pathWkt!);
    }

    final previewPath = replayPath.isNotEmpty
        ? replayPath
        : (workout?.points
                .map((point) => latlong.LatLng(point.lat, point.lng))
                .toList() ??
            const <latlong.LatLng>[]);
    final previewCamera = _buildPreviewCamera(previewPath);

    final distKm = workout != null
        ? (workout.distanceMeters / 1000).toStringAsFixed(2)
        : mission?.distanceKm.toStringAsFixed(2) ?? '0.00';

    final duration = workout?.durationSeconds ?? mission?.durationSec ?? 0;
    final isLoopClosed = workout?.isLoopClosed ?? (mission?.status == 'captured');
    final calories = workout?.caloriesEstimate ?? (mission != null ? (70.0 * mission.distanceKm) : 0.0);

    final paceSec = double.tryParse(distKm) != null && double.parse(distKm) > 0
        ? (duration / double.parse(distKm))
        : 0.0;
    final paceStr = paceSec > 0
        ? '${(paceSec / 60).floor().toString().padLeft(2, '0')}:${(paceSec % 60).floor().toString().padLeft(2, '0')}'
        : '--:--';

    final addressAsync = ref.watch(currentAddressProvider);
    final int xpGained = ((double.tryParse(distKm) ?? 0.0) * 100).toInt() + (isLoopClosed ? 500 : 0);

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        children: [
          Expanded(
            flex: 38,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: StrideMapView(
                        initialCameraPositionOverride: previewCamera,
                        staticPath: replayPath.isNotEmpty ? replayPath : null,
                        isCaptured: isLoopClosed,
                        isPreviewMode: true,
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.18),
                                Colors.black.withValues(alpha: 0.24),
                                Colors.black.withValues(alpha: 0.72),
                              ],
                              stops: const [0.0, 0.38, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                    ),
                    if (isReplay)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Text(
                            'HISTORY',
                            style: StrideTypography.labelBold.copyWith(
                              color: StrideColors.warning,
                              fontSize: 9,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: StrideColors.neonGreen.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isLoopClosed ? 'NEW TERRITORY SECURED' : 'RUN COMPLETE',
                              style: StrideTypography.labelBold.copyWith(
                                color: StrideColors.neonGreen,
                                fontSize: 8,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _buildHeroTitle(isLoopClosed),
                            style: StrideTypography.headlineLG.copyWith(
                              fontSize: 22,
                              fontStyle: FontStyle.italic,
                              height: 0.95,
                              color: StrideColors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          addressAsync.when(
                            data: (address) => Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: StrideTypography.bodyMD.copyWith(
                                color: StrideColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            loading: () => Text(
                              'Locating...',
                              style: StrideTypography.bodyMD.copyWith(
                                color: StrideColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            error: (e, s) => Text(
                              'Unknown location',
                              style: StrideTypography.bodyMD.copyWith(
                                color: StrideColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 62,
            child: Container(
              color: StrideColors.background,
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoopClosed ? 'Territory secured' : 'Run complete',
                              style: StrideTypography.labelTactical.copyWith(
                                fontSize: 8,
                                color: isLoopClosed ? StrideColors.neonGreen : StrideColors.textSecondary,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'SUMMARY',
                              style: StrideTypography.headlineLG.copyWith(fontSize: 28, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      V3SkewBox(
                        skewAmount: -0.12,
                        child: InkWell(
                          onTap: _shareMission,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: StrideColors.surface,
                              border: Border.all(color: StrideColors.white.withValues(alpha: 0.08)),
                            ),
                            child: const Icon(Icons.share_outlined, color: StrideColors.neonGreen, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPrimarySummaryCard(distKm),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('PACE', paceStr, '/KM', StrideColors.neonGreen)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          'TIME',
                          '${(duration / 60).floor()}:${(duration % 60).toString().padLeft(2, '0')}',
                          'MIN',
                          Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('CALORIES', '${calories.toInt()}', 'KCAL', StrideColors.warning)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMetricCard('XP EARNED', '+$xpGained', 'XP', StrideColors.neonGreen.withValues(alpha: 0.7))),
                    ],
                  ),
                  const Spacer(),
                  V3SkewBox(
                    child: ElevatedButton(
                      onPressed: _handleNexusReturn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isReplay ? StrideColors.white : StrideColors.neonGreen,
                        minimumSize: const Size(double.infinity, 64),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text(
                        isReplay ? 'BACK TO HISTORY' : 'RETURN TO DASHBOARD',
                        style: StrideTypography.buttonText.copyWith(fontSize: 24, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimarySummaryCard(String distKm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: StrideColors.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StrideColors.neonGreen.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
        border: Border(
          left: BorderSide(color: StrideColors.neonGreen.withValues(alpha: 0.85), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.distance,
            style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                distKm,
                style: StrideTypography.displayXL.copyWith(fontSize: 40),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'KM',
                  style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.neonGreen.withValues(alpha: 0.8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String unit, Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: StrideColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: StrideTypography.labelTactical.copyWith(
                    fontSize: 7,
                    color: StrideColors.textPrimary.withValues(alpha: 0.4),
                  ),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(value, style: StrideTypography.headlineMD.copyWith(fontSize: 24)),
              ),
              const SizedBox(width: 4),
              Text(unit, style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  String _buildHeroTitle(bool isLoopClosed) {
    return isLoopClosed ? 'AFTERNOON POWER\nRUN' : 'EVENING TRAINING\nRUN';
  }

  CameraPosition? _buildPreviewCamera(List<latlong.LatLng> route) {
    if (route.isEmpty) return null;

    if (route.length == 1) {
      final point = route.first;
      return CameraPosition(
        target: LatLng(point.latitude, point.longitude),
        zoom: 16.6,
        bearing: -12,
        tilt: 48,
      );
    }

    double minLat = route.first.latitude;
    double maxLat = route.first.latitude;
    double minLng = route.first.longitude;
    double maxLng = route.first.longitude;

    for (final point in route.skip(1)) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    const minSpan = 0.0015;
    final latSpan = (maxLat - minLat).abs().clamp(minSpan, 999.0);
    final lngSpan = (maxLng - minLng).abs().clamp(minSpan, 999.0);
    final dominantSpan = latSpan > lngSpan ? latSpan : lngSpan;
    final zoom = (16.9 - (math.log(dominantSpan / minSpan) / math.ln2)).clamp(14.3, 17.2);

    return CameraPosition(
      target: LatLng(((minLat + maxLat) / 2) - latSpan * 0.08, (minLng + maxLng) / 2),
      zoom: zoom,
      bearing: -12,
      tilt: 48,
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
}
