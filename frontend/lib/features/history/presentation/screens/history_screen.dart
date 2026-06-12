import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/app_strings.dart';
import '../../../../ui/components/tactical_header.dart';
import '../../../../core/services/sync_queue_service.dart';
import '../../application/history_controller.dart';
import '../../../../core/domain/models/run_history.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: StrideColors.background,
            shape: const RoundedRectangleBorder(
              side: BorderSide(color: StrideColors.white),
              borderRadius: BorderRadius.zero,
            ),
            title: Text('ERASE MISSION LOGS?', style: StrideTypography.headlineMD.copyWith(color: StrideColors.error)),
            content: Text(
              'THIS ACTION WILL PERMANENTLY WIPE ALL ARCHIVES FROM THE CENTRAL INTEL SERVER.',
              style: StrideTypography.bodyMD,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: TextButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                child: Text('CANCEL', style: StrideTypography.labelTactical.copyWith(color: StrideColors.textMuted)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                child: Text('CONFIRM_ERASE', style: StrideTypography.labelTactical.copyWith(color: StrideColors.error)),
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      final success = await ref.read(historyControllerProvider).clearHistory();
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ARCHIVES PURGED.'), backgroundColor: StrideColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(userHistoryProvider);

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // THE NEW TRIPLE-STACK TACTICAL HEADER WITH ACTIONS
          TacticalHeader(
            title: 'MISSION_LOGS',
            subTitle: 'OPERATIONAL_ARCHIVES',
            status: 'ARCHIVE_MODE_ACTIVE',
            actions: [
              TacticalIconButton(
                onPressed: () => ref.invalidate(userHistoryProvider),
                icon: Icons.refresh,
              ),
              TacticalIconButton(
                onPressed: _clearHistory,
                icon: Icons.delete_sweep_outlined,
              ),
            ],
          ),

          // SCROLLABLE LIST
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(userHistoryProvider),
              color: StrideColors.neonGreen,
              backgroundColor: StrideColors.background,
              child: historyAsync.when(
                data: (missions) {
                  if (missions.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Text(
                              'NO MISSION DATA FOUND.',
                              style: StrideTypography.labelTactical.copyWith(color: StrideColors.textMuted),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: missions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final mission = missions[index];
                      return _buildMissionDossierCard(mission);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: StrideColors.neonGreen)),
                error: (e, s) => ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Text('SYNC_FAIL: ARCHIVE UNREACHABLE',
                          style: StrideTypography.labelTactical.copyWith(color: StrideColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionDossierCard(RunHistory mission) {
    final isCaptured = mission.status == 'captured';
    final statusColor = isCaptured ? StrideColors.neonGreen : StrideColors.white.withOpacity(0.4);
    final dateStr = '${mission.createdAt.day}_${_monthName(mission.createdAt.month)}_${mission.createdAt.year}'.toUpperCase();

    // Pace calculation
    final paceSec = mission.distanceKm > 0 ? (mission.durationSec / mission.distanceKm) : 0.0;
    final pace = paceSec > 0 
        ? '${(paceSec / 60).floor().toString().padLeft(2, '0')}:${(paceSec % 60).floor().toString().padLeft(2, '0')}' 
        : '--:--';

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Stack(
        children: [
          // Subtle Diagonal Gloss Effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
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
                // 1. MISSION SHAPE PREVIEW (LEFT)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(60, 60),
                      painter: MissionShapePainter(
                        color: statusColor,
                        isCaptured: isCaptured,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),

                // 2. MISSION INFO (RIGHT)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateStr, style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: Colors.white24)),
                          V3SkewBox(
                            skewAmount: -0.1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              color: isCaptured ? StrideColors.neonGreen : Colors.white12,
                              child: Text(
                                isCaptured ? 'CAPTURED' : 'FAILED',
                                style: StrideTypography.labelBold.copyWith(fontSize: 7, color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isCaptured ? 'GRID_SECURED_OP_${mission.id.substring(0, 3).toUpperCase()}' : 'RECON_MISSION_ABORTED',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StrideTypography.headlineMD.copyWith(fontSize: 18, letterSpacing: 0),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _miniStat('DIST', '${mission.distanceKm.toStringAsFixed(1)}KM'),
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
    );
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

class MissionShapePainter extends CustomPainter {
  final Color color;
  final bool isCaptured;

  MissionShapePainter({required this.color, required this.isCaptured});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isCaptured) {
      // Draw a glowing "loop" representation
      final path = Path();
      path.moveTo(size.width * 0.2, size.height * 0.3);
      path.quadraticBezierTo(size.width * 0.8, size.height * 0.1, size.width * 0.9, size.height * 0.6);
      path.quadraticBezierTo(size.width * 0.7, size.height * 0.9, size.width * 0.2, size.height * 0.8);
      path.close();

      // Outer glow
      canvas.drawPath(path, paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      // Inner core
      canvas.drawPath(path, paint..maskFilter = null..strokeWidth = 1.5);
    } else {
      // Draw a "broken" or open path representation
      final path = Path();
      path.moveTo(size.width * 0.1, size.height * 0.8);
      path.lineTo(size.width * 0.4, size.height * 0.2);
      path.lineTo(size.width * 0.9, size.height * 0.5);
      canvas.drawPath(path, paint..color = Colors.white24);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
