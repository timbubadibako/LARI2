import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/app_strings.dart';
import '../../../map/presentation/widgets/stride_map_view.dart';
import '../../../map/application/current_address_provider.dart';
import '../../application/workout_controller.dart';

class PostRunSummaryScreen extends ConsumerStatefulWidget {
  const PostRunSummaryScreen({super.key});

  @override
  ConsumerState<PostRunSummaryScreen> createState() => _PostRunSummaryScreenState();
}

class _PostRunSummaryScreenState extends ConsumerState<PostRunSummaryScreen> {
  bool _isSyncing = false;

  Future<void> _handleNexusReturn() async {
    setState(() => _isSyncing = true);
    
    // Save to Hive and Enqueue to Go Backend
    await ref.read(workoutControllerProvider.notifier).saveAndEnqueueSync();
    
    if (!mounted) return;
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _shareMission() {
    final workout = ref.read(workoutControllerProvider);
    final dist = (workout.distanceMeters / 1000).toStringAsFixed(2);
    final time = '${(workout.durationSeconds / 60).floor()}m ${workout.durationSeconds % 60}s';
    
    Share.share(
      'MISSION_ACCOMPLISHED: Captured $dist KM in $time. \nJoin the LARI movement and reclaim your city! 🚀🏙️',
      subject: 'LARI Mission Intel',
    );
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(workoutControllerProvider);
    final addressAsync = ref.watch(currentAddressProvider);

    final distKm = (workout.distanceMeters / 1000).toStringAsFixed(2);
    final paceSec = workout.distanceMeters > 0 ? (workout.durationSeconds / (workout.distanceMeters / 1000.0)) : 0.0;
    final paceStr = paceSec > 0 
        ? '${(paceSec / 60).floor().toString().padLeft(2, '0')}:${(paceSec % 60).floor().toString().padLeft(2, '0')}' 
        : '--:--';

    // XP Logic: 100 XP per KM + 500 Bonus for Capture
    final int xpGained = (double.parse(distKm) * 100).toInt() + (workout.isLoopClosed ? 500 : 0);

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        children: [
          // TOP: MAP HERO (55%)
          Expanded(
            flex: 55,
            child: Stack(
              children: [
                Positioned.fill(child: const StrideMapView()),
                
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

                // Secured Stamp
                Positioned(
                  top: 60,
                  right: -10,
                  child: Transform.rotate(
                    angle: 0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                      color: workout.isLoopClosed ? StrideColors.neonGreen : StrideColors.white,
                      child: Text(
                        workout.isLoopClosed ? 'SECTOR_CAPTURED' : 'RECON_COMPLETE',
                        style: StrideTypography.headlineMD.copyWith(color: StrideColors.background, fontSize: 24),
                      ),
                    ),
                  ),
                ),

                // Floating XP Badge
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: V3SkewBox(
                    skewAmount: -0.1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: StrideColors.neonGreen,
                      child: Text(
                        '+${xpGained}_XP_GAINED',
                        style: StrideTypography.labelBold.copyWith(color: StrideColors.background, fontSize: 14),
                      ),
                    ),
                  ),
                ),

                // Location Info
                Positioned(
                  bottom: 24,
                  left: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MISSION_REPORT_LOC', style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.white.withOpacity(0.5))),
                      addressAsync.when(
                        data: (address) => Text(address, style: StrideTypography.headlineLG.copyWith(fontSize: 28)),
                        loading: () => Text('LOCATING...', style: StrideTypography.headlineLG.copyWith(fontSize: 28)),
                        error: (e, s) => Text('UNKNOWN_SECTOR', style: StrideTypography.headlineLG.copyWith(fontSize: 28)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM: MISSION REPORT (45%)
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
                          Text('MISSION_REPORT', style: StrideTypography.headlineMD.copyWith(fontSize: 24, fontStyle: FontStyle.italic)),
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
                      Expanded(child: _buildV3Stat('DIST', distKm, 'KM')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildV3Stat('PACE', paceStr, '/KM')),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniInfo('CALORIES', '${workout.caloriesEstimate.toInt()} KCAL'),
                      _buildMiniInfo('TIME', '${(workout.durationSeconds / 60).floor()}:${(workout.durationSeconds % 60).toString().padLeft(2, '0')}'),
                    ],
                  ),

                  const Spacer(),

                  // FINAL ACTION
                  V3SkewBox(
                    child: ElevatedButton(
                      onPressed: _isSyncing ? null : _handleNexusReturn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StrideColors.neonGreen,
                        minimumSize: const Size(double.infinity, 64),
                      ),
                      child: _isSyncing 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: StrideColors.background, strokeWidth: 2))
                        : Text('BACK TO NEXUS', style: StrideTypography.buttonText.copyWith(fontSize: 24)),
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
}
