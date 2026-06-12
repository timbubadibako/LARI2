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

  // Slider state
  double _dragValue = 0.0;

  @override
  void dispose() {
    _finishTimer?.cancel();
    super.dispose();
  }

  void _startFinishHold() {
    // 🔥 VALIDASI DISTANCE: Jangan izinkan hold jika 0.00 KM
    final workout = ref.read(workoutControllerProvider);
    if (workout.distanceMeters < 1.0) {
      _showMissionAbortedDialog();
      return;
    }

    _finishProgress = 0.0;
    _finishTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _finishProgress >= 1.0) {
        timer.cancel();
        _finishTimer = null;
        if (_finishProgress >= 1.0) _handleFinish();
        return;
      }
      setState(() => _finishProgress += 1.0 / 60.0); // 6 seconds
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
            borderRadius: BorderRadius.zero, // 🔥 Sharp Edges
          ),
          title: Text('MISSION_ABORTED', style: StrideTypography.headlineMD.copyWith(color: StrideColors.error)),
          content: Text(
            'INSUFFICIENT DATA GATHERED (0.00 KM). THIS SESSION CANNOT BE SAVED.',
            style: StrideTypography.bodyMD,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text('RESUME MISSION', style: StrideTypography.labelBold.copyWith(color: StrideColors.neonGreen)),
            ),
            TextButton(
              onPressed: () {
                ref.read(workoutControllerProvider.notifier).end();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: TextButton.styleFrom(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text('DISCARD MISSION', style: StrideTypography.labelBold.copyWith(color: StrideColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFinish() async {
    HapticFeedback.heavyImpact();
    // Don't save to DB yet, wait for Nexus return in Summary screen
    ref.read(workoutControllerProvider.notifier).pause(); // 🔥 Removed invalid await
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PostRunSummaryScreen()),
    );
  }


  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(workoutControllerProvider);
    final workoutController = ref.read(workoutControllerProvider.notifier);

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
                          _buildSmallTelemetry('AVG_PACE', paceStr),
                          const SizedBox(width: 12),
                          _buildSmallTelemetry('DURATION', timeStr, isNeon: true),
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
                                Text('SECTOR_INTELLIGENCE', style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textSecondary.withOpacity(0.5))),
                                ref.watch(currentAddressProvider).when(
                                  data: (address) => Text(address, style: StrideTypography.labelBold.copyWith(fontSize: 11)),
                                  loading: () => Text('SYNCING...', style: StrideTypography.labelBold.copyWith(fontSize: 11, color: StrideColors.textSecondary)),
                                  error: (e, s) => Text('OFFLINE', style: StrideTypography.labelBold.copyWith(fontSize: 11, color: StrideColors.error)),
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
                                      workout.state == WorkoutState.paused ? 'RESUME (TAP 2X)' : 'PAUSE (TAP 2X)',
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
                                          _finishProgress > 0 ? 'FINISHING...' : 'HOLD 6S FINISH',
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
          ],
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
                    Text('PACE', style: StrideTypography.labelTactical.copyWith(color: StrideColors.white.withOpacity(0.3))),
                    Text(pace, style: StrideTypography.headlineMD.copyWith(fontSize: 40)),
                  ],
                ),
                const SizedBox(width: 40, child: Center(child: Text('|', style: TextStyle(color: Colors.white10)))),
                Column(
                  children: [
                    Text('TIME', style: StrideTypography.labelTactical.copyWith(color: StrideColors.white.withOpacity(0.3))),
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
