import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/tactical_header.dart';
import '../../application/social_controller.dart';
import '../../domain/models/social_models.dart';
import '../../../auth/application/auth_controller.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    ref.invalidate(factionDominionProvider);
    ref.invalidate(leaderboardProvider('KEC-GLOBAL'));
    ref.invalidate(globalActivityProvider);
  }

  @override
  Widget build(BuildContext context) {
    final dominionAsync = ref.watch(factionDominionProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider('KEC-GLOBAL'));
    final activityAsync = ref.watch(globalActivityProvider);
    final currentUserId = ref.watch(currentUserSessionProvider);

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: StrideColors.neonGreen,
        backgroundColor: StrideColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TacticalHeader(
              title: 'WAR_ROOM',
              subTitle: 'STRATEGIC_INTEL',
              status: 'INTEL_FEED_ACTIVE',
              statusColor: StrideColors.secondary,
              actions: [
                IconButton(
                  onPressed: _onRefresh,
                  icon: const Icon(Icons.refresh, color: StrideColors.white, size: 28),
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FACTION DOMINION
                    dominionAsync.when(
                      data: (entries) => entries.isEmpty 
                        ? const SizedBox.shrink() 
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeader('FACTION_DOMINION'),
                              const SizedBox(height: 16),
                              _buildDominionSection(entries),
                              const SizedBox(height: 48),
                            ],
                          ),
                      loading: () => _buildLoadingSection(80),
                      error: (e, s) => _buildErrorSection('DOMINION_OFFLINE: ${e.toString().split(':').last.trim()}'),
                    ),

                    // TOP OPERATIVES
                    leaderboardAsync.when(
                      data: (entries) => entries.isEmpty 
                        ? const SizedBox.shrink() 
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeader('TOP_OPERATIVES', trailing: 'AREA: GLOBAL'),
                              const SizedBox(height: 16),
                              ...entries.take(5).map((e) => _buildAgentCard(
                                e.rank.toString().padLeft(2, '0'),
                                e.displayName,
                                '${(e.totalAreaSqm / 1000).toStringAsFixed(1)}K SQM SECURED',
                                '${(e.totalAreaSqm / 10000).toStringAsFixed(1)}%', // Dummy percentage for now
                                factionColor: e.color,
                                isYou: e.userId == currentUserId,
                              )),
                              const SizedBox(height: 48),
                            ],
                          ),
                      loading: () => _buildLoadingSection(120),
                      error: (e, s) => _buildErrorSection('LEADERBOARD_DISRUPTED'),
                    ),

                    // RECENT GLOBAL ACTIVITY
                    activityAsync.when(
                      data: (activities) => activities.isEmpty 
                        ? const SizedBox.shrink() 
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeader('RECENT_GLOBAL_ACTIVITY'),
                              const SizedBox(height: 16),
                              ...activities.map((a) {
                                final paceSec = a.distanceKm > 0 ? (a.durationSec / a.distanceKm) : 0.0;
                                final paceStr = paceSec > 0 
                                    ? '${(paceSec / 60).floor().toString().padLeft(2, '0')}:${(paceSec % 60).floor().toString().padLeft(2, '0')}' 
                                    : '--:--';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildGlobalMissionDossier(
                                    a.displayName,
                                    a.status == 'captured' ? 'GRID_SECURED_OP_${a.id.substring(0, 3).toUpperCase()}' : 'RECON_MISSION_ABORTED',
                                    a.status.toUpperCase(),
                                    a.color,
                                    '${a.distanceKm.toStringAsFixed(1)}KM',
                                    paceStr,
                                  ),
                                );
                              }),
                              const SizedBox(height: 48),
                            ],
                          ),
                      loading: () => _buildLoadingSection(200),
                      error: (e, s) => _buildErrorSection('FEED_DATA_LOST'),
                    ),

                    // NO DATA STATE (If all are empty)
                    if (dominionAsync.hasValue && dominionAsync.value!.isEmpty &&
                        leaderboardAsync.hasValue && leaderboardAsync.value!.isEmpty &&
                        activityAsync.hasValue && activityAsync.value!.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Column(
                            children: [
                              Icon(Icons.radar, color: StrideColors.textMuted, size: 48),
                              const SizedBox(height: 16),
                              Text('NO_FIELD_ACTIVITY_DETECTED', 
                                style: StrideTypography.labelTactical.copyWith(color: StrideColors.textMuted)
                              ),
                              const SizedBox(height: 8),
                              Text('AWAITING_AGENT_UPLINK...', 
                                style: StrideTypography.labelBold.copyWith(fontSize: 8, color: StrideColors.textMuted.withOpacity(0.5))
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 150),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {String? trailing}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: StrideColors.white.withOpacity(0.05))),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: StrideTypography.headlineMD.copyWith(fontSize: 18, fontStyle: FontStyle.italic, letterSpacing: 1)),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              color: StrideColors.surface,
              child: Text(trailing, style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted)),
            ),
        ],
      ),
    );
  }

  Widget _buildDominionSection(List<DominionEntry> entries) {
    return Column(
      children: [
        SizedBox(
          height: 32,
          child: Row(
            children: entries.map((e) => Expanded(
              flex: (e.percentage * 10).round().clamp(1, 1000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: _powerSegment(e.color),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: entries.take(3).map((e) => _powerLabel(
            e.name.toUpperCase(),
            e.color,
            '${e.percentage.toStringAsFixed(0)}%',
          )).toList(),
        ),
      ],
    );
  }

  Widget _powerSegment(Color color) {
    return Container(
      color: color,
      child: CustomPaint(
        painter: SegmentOverlayPainter(),
      ),
    );
  }

  Widget _powerLabel(String label, Color color, String percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(percent, style: StrideTypography.labelBold.copyWith(color: color, fontSize: 14)),
        Text(label, style: StrideTypography.labelTactical.copyWith(fontSize: 6, color: StrideColors.textMuted, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildAgentCard(String rank, String name, String subtitle, String dominion, {Color factionColor = StrideColors.neonGreen, bool isYou = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StrideColors.surface,
        border: Border(bottom: BorderSide(color: StrideColors.white.withOpacity(0.03))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(rank, style: StrideTypography.displayXL.copyWith(fontSize: 32, color: isYou ? StrideColors.neonGreen : Colors.white.withOpacity(0.1))),
          ),
          const SizedBox(width: 12),
          V3SlantBox(
            slantWidth: 8,
            isLeftSlant: true,
            color: StrideColors.background,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: factionColor.withOpacity(isYou ? 1 : 0.4), width: 1.5),
              ),
              child: Icon(Icons.person, color: Colors.white.withOpacity(isYou ? 1 : 0.3), size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: StrideTypography.labelBold.copyWith(fontSize: 12)),
                    if (isYou) ...[
                      const SizedBox(width: 8),
                      V3SkewBox(
                        skewAmount: -0.2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          color: StrideColors.neonGreen,
                          child: Text('YOU', style: StrideTypography.labelBold.copyWith(fontSize: 7, color: Colors.black)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted, letterSpacing: 0.5)),
              ],
            ),
          ),
          Text(dominion, style: StrideTypography.labelBold.copyWith(fontSize: 14, color: isYou ? StrideColors.neonGreen : Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildGlobalMissionDossier(String agent, String title, String status, Color color, String dist, String pace) {
    final isCaptured = status == 'CAPTURED';
    return Container(
      height: 120, 
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(left: BorderSide(color: color, width: 4)),
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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(50, 50),
                      painter: MissionShapePainter(color: color, isCaptured: isCaptured),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(agent, style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: color.withOpacity(0.6))),
                          V3SkewBox(
                            skewAmount: -0.1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              color: isCaptured ? color : Colors.white12,
                              child: Text(
                                status,
                                style: StrideTypography.labelBold.copyWith(fontSize: 7, color: isCaptured ? Colors.black : color),
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _miniStat('DIST', dist),
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

  Widget _buildLoadingSection(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: StrideColors.surface,
      child: const Center(child: CircularProgressIndicator(color: StrideColors.neonGreen, strokeWidth: 2)),
    );
  }

  Widget _buildErrorSection(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: StrideColors.error.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: StrideColors.error, size: 16),
          const SizedBox(width: 12),
          Text(message, style: StrideTypography.labelTactical.copyWith(color: StrideColors.error, fontSize: 8)),
        ],
      ),
    );
  }
}

class SegmentOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 2;

    const step = 6.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MissionShapePainter extends CustomPainter {
  final Color color;
  final bool isCaptured;

  MissionShapePainter({required this.color, required this.isCaptured});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isCaptured) {
      final path = Path();
      path.moveTo(size.width * 0.2, size.height * 0.3);
      path.quadraticBezierTo(size.width * 0.8, size.height * 0.1, size.width * 0.9, size.height * 0.6);
      path.quadraticBezierTo(size.width * 0.7, size.height * 0.9, size.width * 0.2, size.height * 0.8);
      path.close();
      canvas.drawPath(path, paint);
    } else {
      final path = Path();
      path.moveTo(size.width * 0.1, size.height * 0.8);
      path.lineTo(size.width * 0.4, size.height * 0.2);
      path.lineTo(size.width * 0.9, size.height * 0.5);
      canvas.drawPath(path, paint..color = color.withOpacity(0.2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
