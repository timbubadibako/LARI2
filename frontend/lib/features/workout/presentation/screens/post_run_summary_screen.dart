import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/app_strings.dart';
import '../../../map/presentation/widgets/stride_map_view.dart';
import '../../../map/application/current_address_provider.dart';
import '../../application/workout_controller.dart';
import '../../../../core/domain/models/workout_session.dart';
import '../../../history/application/history_controller.dart';
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
    
    // Parse pathWkt for replay
    List<latlong.LatLng> replayPath = [];
    if (isReplay && mission?.pathWkt != null && mission!.pathWkt!.startsWith('LINESTRING')) {
      replayPath = _parseWKT(mission.pathWkt!);
    }
    
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
    final int xpGained = (double.tryParse(distKm) ?? 0.0 * 100).toInt() + (isLoopClosed ? 500 : 0);

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        children: [
          Expanded(
            flex: 55,
            child: Stack(
              children: [
                Positioned.fill(child: StrideMapView(
                  staticPath: replayPath.isNotEmpty ? replayPath : null,
                  isCaptured: isLoopClosed,
                )),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.transparent,
                          Colors.black,
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  right: -10,
                  child: Transform.rotate(
                    angle: 0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                      color: isLoopClosed ? StrideColors.neonGreen : StrideColors.white,
                      child: Text(
                        isLoopClosed ? 'TERRITORY SECURED' : 'RUN COMPLETE',
                        style: StrideTypography.headlineMD.copyWith(color: StrideColors.background, fontSize: 24),
                      ),
                    ),
                  ),
                ),
                if (isReplay)
                  Positioned(
                    top: 60,
                    left: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      color: StrideColors.warning,
                      child: Text(
                        'HISTORY',
                        style: StrideTypography.labelBold.copyWith(color: Colors.black, fontSize: 10),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: V3SkewBox(
                    skewAmount: -0.1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: StrideColors.neonGreen,
                      child: Text(
                        '+${xpGained} XP EARNED',
                        style: StrideTypography.labelBold.copyWith(color: StrideColors.background, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LOCATION', style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.white.withOpacity(0.5))),
                      addressAsync.when(
                        data: (address) => Text(address, style: StrideTypography.headlineLG.copyWith(fontSize: 28)),
                        loading: () => Text('Locating...', style: StrideTypography.headlineLG.copyWith(fontSize: 28)),
                        error: (e, s) => Text('UNKNOWN LOCATION', style: StrideTypography.headlineLG.copyWith(fontSize: 28)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 45,
            child: Container(
              color: StrideColors.background,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 2, height: 24, color: StrideColors.white.withOpacity(0.2)),
                          const SizedBox(width: 12),
                          Text('RUN SUMMARY', style: StrideTypography.headlineMD.copyWith(fontSize: 24, fontStyle: FontStyle.italic)),
                        ],
                      ),
                      IconButton(
                        onPressed: _shareMission,
                        icon: const Icon(Icons.share_outlined, color: StrideColors.neonGreen, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: _buildV3Stat(AppStrings.distance, distKm, 'KM')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildV3Stat(AppStrings.pace, paceStr, '/KM')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniInfo(AppStrings.calories, '${calories.toInt()} KCAL'),
                      _buildMiniInfo('TIME', '${(duration / 60).floor()}:${(duration % 60).toString().padLeft(2, '0')}'),
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
                        style: StrideTypography.buttonText.copyWith(fontSize: 24, color: Colors.black)
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

  Widget _buildV3Stat(String label, String value, String unit) {
    return Row(
      children: [
        V3SlantBox(
          slantWidth: 10,
          isRightSlant: true,
          color: StrideColors.neonGreen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(label, style: StrideTypography.labelBold.copyWith(fontSize: 9, color: StrideColors.background)),
          ),
        ),
        Expanded(
          child: V3SlantBox(
            slantWidth: 10,
            isLeftSlant: true,
            color: StrideColors.surface,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: StrideColors.glassBorder)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: StrideTypography.headlineMD.copyWith(fontSize: 24)),
                  const SizedBox(width: 4),
                  Text(unit, style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textPrimary.withOpacity(0.4))),
        Text(value, style: StrideTypography.headlineMD.copyWith(fontSize: 18)),
      ],
    );
  }

  // Local helper for WKT parsing
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
