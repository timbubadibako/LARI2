import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/app_strings.dart';
import '../../application/workout_controller.dart';
import '../../../map/presentation/widgets/stride_map_view.dart';
import '../../../map/application/current_address_provider.dart';
import 'post_run_summary_screen.dart';
import '../../../../core/domain/models/workout_session.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> with TickerProviderStateMixin {
  bool _isPocketMode = false;
  double _finishProgress = 0.0;
  Timer? _finishTimer;
  bool _showConquestOverlay = false;

  // Slider state
  double _dragValue = 0.0;

  @override
  void dispose() {
    _finishTimer?.cancel();
    super.dispose();
  }

  void _triggerConquestOverlay() {
    if (_showConquestOverlay) return;
    
    HapticFeedback.heavyImpact();
    setState(() => _showConquestOverlay = true);
    
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showConquestOverlay = false);
      }
    });
  }

  void _startFinishHold() {
    /* 
    // 🔥 PRODUCTION VALIDASI DISTANCE: Jangan izinkan hold jika 0.00 KM
    final workout = ref.read(workoutControllerProvider);
    if (workout.distanceMeters < 1.0) {
      _showMissionAbortedDialog();
      return;
    }
    */

    _finishProgress = 0.0;
    _finishTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _finishProgress >= 1.0) {
        timer.cancel();
        _finishTimer = null;
        if (_finishProgress >= 1.0) _handleFinish();
        return;
      }
      setState(() => _finishProgress += 1.0 / 30.0); // 3 seconds
    });
  }

  void _cancelFinishHold() {
    _finishTimer?.cancel();
    _finishTimer = null;
    setState(() => _finishProgress = 0.0);
  }

  void _showMissionAbortedDialog() {
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: StrideColors.background,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: StrideColors.error, width: 2),
            borderRadius: BorderRadius.zero,
          ),
          title: Text('SESSION_ENDED', style: StrideTypography.headlineMD.copyWith(color: StrideColors.error)),
          content: Text(
            'INSUFFICIENT DISTANCE DETECTED (0.00 KM). DATA WILL NOT BE SAVED.',
            style: StrideTypography.bodyMD,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text(AppStrings.resume, style: StrideTypography.labelBold.copyWith(color: StrideColors.neonGreen)),
            ),
            TextButton(
              onPressed: () {
                ref.read(workoutControllerProvider.notifier).end();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: TextButton.styleFrom(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text(AppStrings.discard, style: StrideTypography.labelBold.copyWith(color: StrideColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFinish() async {
    try {
      debugPrint('ACTIVE_RUN: Hold completed. Initializing finish protocol...');
      HapticFeedback.heavyImpact();
      
      final controller = ref.read(workoutControllerProvider.notifier);
      final workout = ref.read(workoutControllerProvider);
      
      debugPrint('ACTIVE_RUN: Captured workout stats - ID: ${workout.id}, Points: ${workout.points.length}');

      // Hand off to sync service and reset state
      // We wrap this in a timeout just in case Hive or something hangs
      await controller.end().timeout(
        const Duration(seconds: 5),
        onTimeout: () => debugPrint('ACTIVE_RUN_WARNING: Controller end timed out, proceeding to summary.'),
      );

      debugPrint('ACTIVE_RUN: Finish protocol complete. Navigating to summary.');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PostRunSummaryScreen(workout: workout),
        ),
      );
    } catch (e, stack) {
      debugPrint('ACTIVE_RUN_ERROR: Critical failure during finish: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('TERMINAL_FAILURE: $e'), backgroundColor: StrideColors.error),
        );
        // Even on error, try to at least go back to dashboard so user isn't stuck
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(workoutControllerProvider);
    final workoutController = ref.read(workoutControllerProvider.notifier);

    // Listen for loop closure to show overlay
    ref.listen(workoutControllerProvider.select((s) => s.isLoopClosed), (previous, next) {
      if (next == true && (previous == false || previous == null)) {
        _triggerConquestOverlay();
      }
    });

    final minutes = (workout.durationSeconds / 60).floor();
    final seconds = workout.durationSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final paceSec = workout.distanceMeters > 0 ? (workout.durationSeconds / (workout.distanceMeters / 1000.0)) : 0.0;
    final paceStr = paceSec > 0 
        ? '${(paceSec / 60).floor().toString().padLeft(2, '0')}:${(paceSec % 60).floor().toString().padLeft(2, '0')}' 
        : '--:--';

    final distKmParts = (workout.distanceMeters / 1000).toStringAsFixed(2).split('.');
    final distKmMain = distKmParts[0].padLeft(2, '0');
    final distKmDecimal = distKmParts[1];

    return PopScope(
      canPop: !_isPocketMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isPocketMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('UNAUTHORIZED: SLIDE TO UNLOCK DEPLOYED'),
              duration: Duration(seconds: 1),
              backgroundColor: StrideColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: StrideColors.background,
        body: Stack(
          children: [
            const Positioned.fill(child: StrideMapView()),

            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        Colors.transparent,
                        StrideColors.background.withOpacity(0.9),
                      ],
                      stops: const [0.1, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            if (!_isPocketMode)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: StrideColors.neonGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              'CAPTURE_IN_PROGRESS',
                              style: StrideTypography.labelBold.copyWith(fontSize: 10, color: StrideColors.background),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.lock_open, color: StrideColors.white, size: 20),
                            onPressed: () => setState(() => _isPocketMode = true),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      V3SlantBox(
                        slantWidth: 20,
                        isRightSlant: true,
                        color: Colors.black.withOpacity(0.7),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 24, 48, 24),
                          decoration: const BoxDecoration(
                            border: Border(left: BorderSide(color: StrideColors.neonGreen, width: 4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('KILOMETERS', style: StrideTypography.labelTactical.copyWith(fontSize: 9, color: StrideColors.textSecondary)),
                              const SizedBox(height: 16),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(text: distKmMain, style: StrideTypography.displayXL.copyWith(fontSize: 74)),
                                    TextSpan(text: '.', style: StrideTypography.displayXL.copyWith(fontSize: 74, color: StrideColors.neonGreen)),
                                    TextSpan(text: distKmDecimal, style: StrideTypography.displayXL.copyWith(fontSize: 48, color: StrideColors.neonGreen)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _buildSmallTelemetry(AppStrings.pace, paceStr),
                          const SizedBox(width: 12),
                          _buildSmallTelemetry(AppStrings.duration, timeStr, isNeon: true),
                        ],
                      ),

                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: StrideColors.surface.withOpacity(0.9),
                          border: Border.all(color: StrideColors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 3, height: 32, color: StrideColors.neonGreen),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CURRENT_LOCATION', style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textSecondary.withOpacity(0.5))),
                                ref.watch(currentAddressProvider).when(
                                  data: (address) => Text(address, style: StrideTypography.labelBold.copyWith(fontSize: 11)),
                                  loading: () => Text('SYNCING_GRID...', style: StrideTypography.labelBold.copyWith(fontSize: 11, color: StrideColors.textSecondary.withOpacity(0.5))),
                                  error: (e, s) => Text('OFFLINE_GRID', style: StrideTypography.labelBold.copyWith(fontSize: 11, color: StrideColors.error.withOpacity(0.5))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onDoubleTap: () {
                                HapticFeedback.mediumImpact();
                                if (workout.state == WorkoutState.paused) {
                                  workoutController.resume();
                                } else {
                                  workoutController.pause();
                                }
                              },
                              child: V3SkewBox(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: StrideColors.surface,
                                    border: Border.all(color: StrideColors.white, width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      workout.state == WorkoutState.paused ? '${AppStrings.resume} (TAP 2X)' : '${AppStrings.pause} (TAP 2X)',
                                      style: StrideTypography.labelBold.copyWith(color: StrideColors.white, fontSize: 10, letterSpacing: 1.2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onLongPressStart: (_) => _startFinishHold(),
                              onLongPressEnd: (_) => _cancelFinishHold(),
                              child: V3SkewBox(
                                child: Container(
                                  height: 50,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: const BoxDecoration(
                                    color: StrideColors.neonGreen,
                                  ),
                                  child: Stack(
                                    children: [
                                      LinearProgressIndicator(
                                        value: _finishProgress,
                                        backgroundColor: Colors.transparent,
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                      Center(
                                        child: Text(
                                          _finishProgress > 0 ? 'FINISHING...' : 'HOLD 3S FINISH',
                                          style: StrideTypography.labelBold.copyWith(color: StrideColors.background, fontSize: 10, letterSpacing: 1.2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            if (_isPocketMode)
              _buildPocketModeOverlay(distKmMain, distKmDecimal, paceStr, timeStr),

            if (_showConquestOverlay)
              _buildConquestOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildConquestOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: StrideColors.neonGreen.withOpacity(0.1),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: StrideColors.neonGreen, size: 80),
                const SizedBox(height: 16),
                Text(
                  AppStrings.territorySecured,
                  style: StrideTypography.displayXL.copyWith(
                    color: StrideColors.neonGreen,
                    fontSize: 32,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.areaIntegrated,
                  style: StrideTypography.labelTactical.copyWith(color: StrideColors.white),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: StrideColors.neonGreen, width: 2),
                  ),
                  child: const Text(
                    AppStrings.syncInProgress,
                    style: TextStyle(color: StrideColors.neonGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallTelemetry(String label, String value, {bool isNeon = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: const Border(left: BorderSide(color: StrideColors.white, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textSecondary)),
          Text(value, style: StrideTypography.headlineMD.copyWith(fontSize: 28, color: isNeon ? StrideColors.neonGreen : StrideColors.white)),
        ],
      ),
    );
  }

  Widget _buildPocketModeOverlay(String mainDist, String decimalDist, String pace, String time) {
    return Positioned.fill(
      child: Container(
        color: StrideColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
        child: Column(
          children: [
            Text('STATUS: LOCKED', style: StrideTypography.labelTactical.copyWith(color: StrideColors.neonGreen.withOpacity(0.3))),
            const Spacer(),
            Text('KILOMETERS', style: StrideTypography.labelTactical.copyWith(fontSize: 12, color: StrideColors.white.withOpacity(0.4))),
            const SizedBox(height: 24),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: mainDist, style: StrideTypography.displayXL.copyWith(fontSize: 120, color: StrideColors.neonGreen)),
                  TextSpan(text: '.$decimalDist', style: StrideTypography.displayXL.copyWith(fontSize: 60, color: StrideColors.neonGreen.withOpacity(0.5))),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(AppStrings.pace, style: StrideTypography.labelTactical.copyWith(color: StrideColors.white.withOpacity(0.3))),
                    Text(pace, style: StrideTypography.headlineMD.copyWith(fontSize: 40)),
                  ],
                ),
                const SizedBox(width: 40, child: Center(child: Text('|', style: TextStyle(color: Colors.white10)))),
                Column(
                  children: [
                    Text(AppStrings.duration, style: StrideTypography.labelTactical.copyWith(color: StrideColors.white.withOpacity(0.3))),
                    Text(time, style: StrideTypography.headlineMD.copyWith(fontSize: 40)),
                  ],
                ),
              ],
            ),
            const Spacer(),
            
            // Industrial Skewed Slider with Hazard Pattern
            Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    const trackHeight = 70.0;
                    const handleWidth = 80.0;
                    final maxDrag = maxWidth - handleWidth;

                    return V3SkewBox(
                      skewAmount: -0.1,
                      child: Container(
                        width: maxWidth,
                        height: trackHeight,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: StrideColors.white.withOpacity(0.05),
                          border: Border.all(color: StrideColors.white.withOpacity(0.5), width: 1.5),
                        ),
                        child: Stack(
                          children: [
                            if (_dragValue > 0)
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: _dragValue * maxDrag,
                                child: CustomPaint(
                                  painter: HazardStripePainter(
                                    color: StrideColors.neonGreen.withOpacity(0.5), 
                                    stripeWidth: 8.0,
                                  ),
                                ),
                              ),
                            Center(
                              child: Text(
                                'SLIDE_TO_UNLOCK', 
                                style: StrideTypography.labelTactical.copyWith(
                                  color: StrideColors.white.withOpacity(0.2),
                                  letterSpacing: 4,
                                  fontSize: 10,
                                )
                              ),
                            ),
                            Positioned(
                              left: _dragValue * maxDrag,
                              top: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onHorizontalDragUpdate: (details) {
                                  setState(() {
                                    _dragValue += details.delta.dx / maxDrag;
                                    _dragValue = _dragValue.clamp(0.0, 1.0);
                                  });
                                },
                                onHorizontalDragEnd: (details) {
                                  if (_dragValue > 0.85) {
                                    setState(() {
                                      _isPocketMode = false;
                                      _dragValue = 0.0;
                                    });
                                    HapticFeedback.heavyImpact();
                                  } else {
                                    setState(() {
                                      _dragValue = 0.0;
                                    });
                                  }
                                },
                                child: Container(
                                  width: handleWidth,
                                  decoration: const BoxDecoration(
                                    color: StrideColors.white,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.chevron_right, color: Colors.black, size: 28),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
                const SizedBox(height: 16),
                Text(
                  '[ ACTION_REQUIRED: GESTURE_SYNC_DEACTIVATION ]',
                  style: StrideTypography.labelTactical.copyWith(
                    fontSize: 7,
                    color: StrideColors.neonGreen.withOpacity(0.4),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
