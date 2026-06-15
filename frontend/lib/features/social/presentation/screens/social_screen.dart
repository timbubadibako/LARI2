import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/tactical_header.dart';
import '../../../../ui/components/signature_painter.dart';
import '../../../../ui/components/app_strings.dart';
import '../../../../ui/components/route_preview_painter.dart';
import '../../application/social_controller.dart';
import '../../domain/models/social_models.dart';
import '../../../auth/application/auth_controller.dart';
import 'guild_screen.dart';
import '../../../../ui/components/mission_dossier_card.dart';

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

    final dominionAsync = ref.watch(guildDominionProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider('KEC-GLOBAL'));
    final activityAsync = ref.watch(globalActivityProvider);
    final graffitiAsync = ref.watch(recentGraffitiProvider);
    final currentUserId = ref.watch(currentUserSessionProvider);

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TacticalHeader(
            title: AppStrings.socialRoom,
            subTitle: AppStrings.communityFeed,
            status: AppStrings.networkOnline,
            statusColor: StrideColors.secondary,
            actions: [
              TacticalIconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuildScreen()));
                },
                icon: Icons.shield_outlined,
              ),
              TacticalIconButton(
                onPressed: () => _onRefresh(),
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      loading: () => const SizedBox.shrink(), // Don't show loading if empty
                      error: (e, s) => _buildErrorSection('FEED_OFFLINE: ${e.toString()}'),
                    ),

                    leaderboardAsync.when(
                      data: (entries) => entries.isEmpty 
                        ? const SizedBox.shrink() 
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeader(AppStrings.leaderboard, trailing: 'AREA: GLOBAL'),
                              const SizedBox(height: 16),
                              ...entries.take(5).map((e) => _buildRunnerCard(
                                e.rank.toString().padLeft(2, '0'),
                                e.displayName,
                                '${(e.totalAreaSqm / 1000).toStringAsFixed(1)}K SQM SECURED',
                                '${(e.totalAreaSqm / 10000).toStringAsFixed(1)}%', 
                                factionColor: e.color,
                                isYou: e.userId == currentUserId,
                              )),
                              const SizedBox(height: 48),
                            ],
                          ),
                      loading: () => _buildLoadingSection(120),
                      error: (e, s) => _buildErrorSection('${AppStrings.leaderboard} OFFLINE: ${e.toString()}'),
                    ),

                    graffitiAsync.when(
                      data: (tags) => tags.isEmpty 
                        ? const SizedBox.shrink() 
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeader(AppStrings.globalGraffitiWall),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: tags.length,
                                  itemBuilder: (context, index) {
                                    final tag = tags[index];
                                    return _buildGraffitiTag(tag);
                                  },
                                ),
                              ),
                              const SizedBox(height: 48),
                            ],
                          ),
                      loading: () => _buildLoadingSection(100),
                      error: (e, s) => _buildErrorSection('GRAFFITI_OFFLINE: ${e.toString()}'),
                    ),

                    _buildRunTogetherSection(),

                    activityAsync.when(
                      data: (activities) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(AppStrings.recentActivity),
                          const SizedBox(height: 16),
                          if (activities.isEmpty)
                            _buildEmptyState(AppStrings.noActivity, AppStrings.awaitingUplink)
                          else
                            ...activities.map((a) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildGlobalActivityCard(a),
                              ),
                            ),
                          const SizedBox(height: 48),
                        ],
                      ),
                      loading: () => _buildLoadingSection(200),
                      error: (e, s) => _buildErrorSection('FEED_OFFLINE: ${e.toString()}'),
                    ),
                    
                    const SizedBox(height: 150),
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
    final activeEntries = entries.where((e) => e.percentage > 0).toList();
    
    return Column(
      children: [
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white12, // Visible background
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: activeEntries.map((e) => Expanded(
              flex: (e.percentage * 10).round().clamp(1, 1000),
              child: _powerSegment(e.color),
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
        _sectionHeader('RUN_TOGETHER'),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: StrideColors.surface,
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              // LEFT: Join Session
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
                      Text('INPUT_PIN', style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted)),
                    ],
                  ),
                ),
              ),
              // RIGHT: Generate Pin
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.share, color: StrideColors.neonGreen, size: 24),
                      const SizedBox(height: 8),
                      Text('HOST', style: StrideTypography.labelBold.copyWith(fontSize: 10)),
                      Text('SHARE_PIN', style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
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
                  'TAG_${tag.id.substring(0, 4)}',
                  style: StrideTypography.labelTactical.copyWith(fontSize: 6, color: StrideColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalActivityCard(GlobalActivity activity) {
    final isCaptured = activity.status == 'captured';
    final statusColor = isCaptured ? activity.color : Colors.white.withValues(alpha: 0.4);

    return MissionDossierCard(
      id: activity.id,
      title: isCaptured ? 'AREA ACQUISITION' : 'STANDARD ACTIVITY',
      status: activity.status,
      distanceKm: activity.distanceKm,
      durationSec: activity.durationSec,
      createdAt: activity.createdAt,
      pathWkt: activity.pathWkt,
      statusColor: statusColor,
      isPendingSync: false,
      onTap: () {
        HapticFeedback.lightImpact();
      },
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
          Icon(Icons.radar_outlined, color: StrideColors.textMuted, size: 32),
          const SizedBox(height: 12),
          Text(title, style: StrideTypography.labelBold.copyWith(fontSize: 10, color: StrideColors.textMuted)),
          const SizedBox(height: 4),
          Text(subtitle, style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textMuted.withOpacity(0.5))),
        ],
      ),
    );
  }

