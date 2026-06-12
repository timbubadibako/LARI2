import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/app_strings.dart';
import '../widgets/stride_map_view.dart';
import '../../application/map_actions_provider.dart';
import '../../application/current_address_provider.dart';
import '../../../workout/presentation/screens/active_workout_screen.dart';
import '../../../workout/application/workout_controller.dart';
import '../../../profile/application/profile_controller.dart';
import '../../../../core/domain/models/workout_session.dart';

class MapDashboardScreen extends ConsumerStatefulWidget {
  const MapDashboardScreen({super.key});

  @override
  ConsumerState<MapDashboardScreen> createState() => _MapDashboardScreenState();
}

class _MapDashboardScreenState extends ConsumerState<MapDashboardScreen> {
  Future<void> _startWorkout() async {
    final workoutState = ref.read(workoutControllerProvider).state;
    
    if (workoutState == WorkoutState.running || workoutState == WorkoutState.paused) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ActiveWorkoutScreen()),
      );
      return;
    }

    ref.read(workoutControllerProvider.notifier).start();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActiveWorkoutScreen()),
    );
  }

  void _recenterMap() {
    ref.read(mapRecenterTriggerProvider.notifier).trigger();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);
    final addressAsync = ref.watch(currentAddressProvider);
    final workout = ref.watch(workoutControllerProvider);

    final minutes = (workout.durationSeconds / 60).floor();
    final seconds = workout.durationSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isWorkoutActive = workout.state == WorkoutState.running || workout.state == WorkoutState.paused;

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Stack(
        children: [
          // LAYER 0: Map
          const Positioned.fill(child: StrideMapView()),

          // LAYER 1: Heavy Vignette
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      Colors.black,
                    ],
                    stops: [0.3, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // LAYER 2: HUD Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MINIMIZED HEADER (REAL DATA)
                  profileAsync.when(
                    data: (profile) {
                      if (profile == null) return const SizedBox.shrink();
                      return Row(
                        children: [
                          V3SlantBox(
                            slantWidth: 15,
                            isRightSlant: true,
                            color: StrideColors.neonGreen,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('LVL', style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.background)),
                                  Text('${profile.level}', style: StrideTypography.headlineMD.copyWith(fontSize: 24, color: StrideColors.background)),
                                ],
                              ),
                            ),
                          ),
                          V3SlantBox(
                            slantWidth: 15,
                            isLeftSlant: true,
                            color: StrideColors.surface.withOpacity(0.8),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: StrideColors.outline.withOpacity(0.5),
                                  width: 1.0,
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(profile.displayNameOrFallback.toUpperCase(), style: StrideTypography.labelBold.copyWith(fontSize: 10)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 80,
                                    height: 2,
                                    color: StrideColors.background,
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: (profile.xp % 1000) / 1000,
                                      child: Container(color: StrideColors.neonGreen),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: StrideColors.neonGreen))),
                    error: (e, s) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  // LOCATION BOX
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      border: Border(left: BorderSide(color: StrideColors.white, width: 2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CURRENT LOCATION', style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textSecondary)),
                        const SizedBox(height: 2),
                        addressAsync.when(
                          data: (address) => Text(address, style: StrideTypography.headlineMD.copyWith(fontSize: 18)),
                          loading: () => Text('SYNCING_GRID...', style: StrideTypography.headlineMD.copyWith(fontSize: 18, color: StrideColors.textSecondary)),
                          error: (e, s) => Text('OFFLINE_GRID', style: StrideTypography.headlineMD.copyWith(fontSize: 18, color: StrideColors.error)),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // DUAL SIDE BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // RECENTER BUTTON (LEFT)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _recenterMap,
                            child: V3SkewBox(
                              skewAmount: -0.1,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: StrideColors.background.withOpacity(0.8),
                                  border: Border.all(color: StrideColors.white.withOpacity(0.2), width: 1.5),
                                ),
                                child: const Center(
                                  child: Icon(Icons.my_location, color: StrideColors.white, size: 18),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SYNC_GRID',
                            style: StrideTypography.labelTactical.copyWith(fontSize: 6, color: StrideColors.textSecondary),
                          ),
                        ],
                      ),

                      // ACTIVE RUN WIDGET (MIDDLE)
                      if (isWorkoutActive)
                        GestureDetector(
                          onTap: _startWorkout, // Jump back to ActiveWorkoutScreen
                          child: V3SkewBox(
                            skewAmount: -0.1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(color: StrideColors.outline.withOpacity(0.5), width: 1.5),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    workout.state == WorkoutState.paused ? 'PAUSED_SESSION' : 'MISSION_CLOCK',
                                    style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.neonGreen, letterSpacing: 1),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: StrideTypography.headlineMD.copyWith(fontSize: 22, color: StrideColors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // START BUTTON (RIGHT)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            color: StrideColors.white,
                            child: Text(
                              isWorkoutActive ? 'CONTINUE' : AppStrings.ready,
                              style: StrideTypography.labelBold.copyWith(fontSize: 8, color: StrideColors.background),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _startWorkout,
                            child: V3SkewBox(
                              skewAmount: -0.1,
                              child: Container(
                                width: 58,
                                height: 58,
                                clipBehavior: Clip.antiAlias,
                                decoration: const BoxDecoration(
                                  color: Colors.transparent,
                                ),
                                child: Image.asset(
                                  'assets/images/LARI-NeonBlack.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // FOOTER
                  const SizedBox(height: 104), 
                  Center(
                    child: Text(
                      'LARI_GRID_LINK_V3.3',
                      style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textSecondary.withOpacity(0.2)),
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
}
