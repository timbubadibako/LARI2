import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/tactical_header.dart';
import '../../../../ui/components/signature_painter.dart';
import '../../application/social_controller.dart';
import '../../domain/models/social_models.dart';
import '../../../auth/application/auth_controller.dart';
import 'guild_screen.dart';

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
    try {
      await Future.wait([
        ref.refresh(guildDominionProvider.future),
        ref.refresh(leaderboardProvider('KEC-GLOBAL').future),
        ref.refresh(globalActivityProvider.future),
        ref.refresh(recentGraffitiProvider.future),
      ]);
    } catch (e) {
      debugPrint('REFRESH_ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      globalActivityStreamProvider,
      (_, next) {
        if (next.hasValue) {
          ref.invalidate(globalActivityProvider);
          HapticFeedback.lightImpact();
        }
      },
    );

    final activityAsync = ref.watch(globalActivityProvider);
    final dominionAsync = ref.watch(guildDominionProvider);
    final graffitiAsync = ref.watch(recentGraffitiProvider);
    final currentUserId = ref.watch(currentUserSessionProvider);
    final activeNowSummary = ref.watch(socialActiveNowSummaryProvider);
    final hotZones = ref.watch(hotZonePreviewProvider);
    final topLeaders = ref.watch(topWeeklyLeadersProvider);

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TacticalHeader(
            title: 'Social',
            subTitle: 'SEE WHO IS MOVING NEAR YOU',
            status: 'LIVE FEED',
            statusColor: StrideColors.neonGreen,
            actions: [
              TacticalIconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuildScreen()));
                },
                icon: Icons.shield_outlined,
              ),
              TacticalIconButton(
                onPressed: _onRefresh,
                icon: Icons.refresh,
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: StrideColors.neonGreen,
              backgroundColor: StrideColors.background,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    activityAsync.when(
                      data: (activities) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('ACTIVE NOW'),
                          const SizedBox(height: 16),
                          _buildActiveNowStrip(activeNowSummary),
                          const SizedBox(height: 36),
                          _sectionHeader('HOT ZONES'),
                          const SizedBox(height: 16),
                          _buildHotZonesPanel(hotZones),
                          const SizedBox(height: 36),
                        ],
                      ),
                      loading: () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader('ACTIVE NOW'),
                          const SizedBox(height: 16),
                          _buildLoadingSection(110),
                          const SizedBox(height: 36),
                          _sectionHeader('HOT ZONES'),
                          const SizedBox(height: 16),
                          _buildLoadingSection(180),
                          const SizedBox(height: 36),
                        ],
                      ),
                      error: (e, s) => Column(
                        children: [
                          _buildErrorSection('SOCIAL FEED OFFLINE: ${e.toString()}'),
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                    if (topLeaders.isNotEmpty) ...[
                      _sectionHeader('WEEKLY LEADERS', trailing: 'TOP 5'),
                      const SizedBox(height: 16),
                      ...topLeaders.map(
                        (e) => _buildRunnerCard(
                          e.rank.toString().padLeft(2, '0'),
                          e.displayName,
                          '${(e.totalAreaSqm / 1000).toStringAsFixed(1)}K sqm held',
                          '${(e.totalAreaSqm / 10000).toStringAsFixed(1)}%',
                          factionColor: e.color,
                          isYou: e.userId == currentUserId,
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                    _buildRunTogetherSection(),
                    dominionAsync.when(
                      data: (entries) => entries.isEmpty
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionHeader('TEAM DOMINION'),
                                const SizedBox(height: 16),
                                _buildDominionSection(entries),
                                const SizedBox(height: 36),
                              ],
                            ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                    graffitiAsync.when(
                      data: (tags) => tags.isEmpty
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionHeader('GRAFFITI WALL'),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: tags.length,
                                    itemBuilder: (context, index) => _buildGraffitiTag(tags[index]),
                                  ),
                                ),
                              ],
                            ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, s) => const SizedBox.shrink(),
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

  Widget _sectionHeader(String title, {String? trailing}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: StrideColors.white.withOpacity(0.05))),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: StrideTypography.headlineMD.copyWith(fontSize: 18, fontStyle: FontStyle.italic, letterSpacing: 1),
          ),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              color: StrideColors.surface,
              child: Text(
                trailing,
                style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveNowStrip(SocialActiveNowSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: StrideColors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildKpiBlock('RUNNERS', '${summary.activeRunners}', StrideColors.neonGreen)),
          Expanded(child: _buildKpiBlock('HOT ZONES', '${summary.hotZones}', StrideColors.warning)),
          Expanded(child: _buildKpiBlock('CAPTURES', '${summary.capturedRuns}', Colors.white)),
        ],
      ),
    );
  }

  Widget _buildKpiBlock(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: accent.withOpacity(0.25), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: StrideTypography.headlineLG.copyWith(fontSize: 28, color: accent),
          ),
        ],
      ),
    );
  }

  Widget _buildHotZonesPanel(List<HotZonePreview> zones) {
    if (zones.isEmpty) {
      return _buildEmptyState('No hot zones yet', 'Finish a run to light up this area');
    }

    return Column(
      children: List.generate(zones.length, (index) {
        final zone = zones[index];
        return Container(
          margin: EdgeInsets.only(bottom: index == zones.length - 1 ? 0 : 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: StrideColors.surface,
            border: Border(left: BorderSide(color: zone.intensity, width: 3)),
          ),
          child: Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: const Color(0xFF090909),
                  border: Border.all(color: zone.intensity.withOpacity(0.35)),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _HotZonePreviewPainter(
                          accent: zone.intensity,
                          seed: zone.seed,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: FadeTransition(
                        opacity: _pulseController.drive(Tween(begin: 0.35, end: 0.9)),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: zone.intensity,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: zone.intensity.withOpacity(0.35),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.zoneName, style: StrideTypography.labelBold.copyWith(fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '${zone.displayName} finished a ${zone.distanceKm.toStringAsFixed(1)} km run nearby',
                      style: StrideTypography.bodyMD.copyWith(fontSize: 12, color: StrideColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              V3SkewBox(
                skewAmount: -0.12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  color: zone.intensity,
                  child: Text(
                    zone.statusLabel,
                    style: StrideTypography.labelBold.copyWith(fontSize: 7, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDominionSection(List<DominionEntry> entries) {
    final activeEntries = entries.where((e) => e.percentage > 0).toList();

    return Column(
      children: [
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white12,
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: activeEntries
                .map((e) => Expanded(
                      flex: (e.percentage * 10).round().clamp(1, 1000),
                      child: _powerSegment(e.color),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: entries
              .take(3)
              .map((e) => _powerLabel(
                    e.name.toUpperCase(),
                    e.color,
                    '${e.percentage.toStringAsFixed(0)}%',
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _powerSegment(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildRunTogetherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('RUN TOGETHER'),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: StrideColors.surface,
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.white12)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.login, color: StrideColors.neonGreen, size: 24),
                      const SizedBox(height: 8),
                      Text('JOIN', style: StrideTypography.labelBold.copyWith(fontSize: 10)),
                      Text('Enter PIN', style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.share, color: StrideColors.neonGreen, size: 24),
                      const SizedBox(height: 8),
                      Text('HOST', style: StrideTypography.labelBold.copyWith(fontSize: 10)),
                      Text('Share PIN', style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
      ],
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

  Widget _buildRunnerCard(String rank, String name, String subtitle, String dominion, {Color factionColor = StrideColors.neonGreen, bool isYou = false}) {
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

  Widget _buildGraffitiTag(Graffiti tag) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: StrideColors.surface,
        border: Border.all(color: StrideColors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: CustomPaint(
                painter: SignaturePainter(
                  strokes: tag.strokes,
                  color: tag.color,
                  strokeWidth: 2.0,
                  scale: 0.4,
                  showGlow: true,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tag.displayName.toUpperCase(),
                    style: StrideTypography.labelBold.copyWith(fontSize: 7, color: tag.color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '#${tag.id.substring(0, 4)}',
                  style: StrideTypography.labelTactical.copyWith(fontSize: 6, color: StrideColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
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
          const Icon(Icons.error_outline, color: StrideColors.error, size: 16),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: StrideTypography.labelTactical.copyWith(color: StrideColors.error, fontSize: 8))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: StrideColors.surface,
        border: Border.all(color: StrideColors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.radar_outlined, color: StrideColors.textMuted, size: 32),
          const SizedBox(height: 12),
          Text(title, style: StrideTypography.labelBold.copyWith(fontSize: 10, color: StrideColors.textMuted)),
          const SizedBox(height: 4),
          Text(subtitle, style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textMuted.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _HotZonePreviewPainter extends CustomPainter {
  final Color accent;
  final int seed;

  _HotZonePreviewPainter({
    required this.accent,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    const step = 18.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final routePaint = Paint()
      ..color = accent.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final glowPaint = Paint()
      ..color = accent.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    if (seed % 3 == 1) {
      path.moveTo(14, 56);
      path.lineTo(28, 42);
      path.lineTo(24, 26);
      path.lineTo(46, 16);
      path.lineTo(60, 28);
    } else if (seed % 3 == 2) {
      path.moveTo(12, 48);
      path.lineTo(26, 34);
      path.lineTo(38, 40);
      path.lineTo(50, 22);
      path.lineTo(66, 28);
    } else {
      path.moveTo(10, 52);
      path.lineTo(22, 38);
      path.lineTo(42, 34);
      path.lineTo(52, 20);
      path.lineTo(64, 24);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, routePaint);

    final zonePaint = Paint()
      ..color = accent.withOpacity(0.16)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(size.width - 24, size.height - 24, 16, 16),
      zonePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HotZonePreviewPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.seed != seed;
  }
}
