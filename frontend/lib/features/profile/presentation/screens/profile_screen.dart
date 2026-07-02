import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/tactical_header.dart';
import '../../application/profile_controller.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final overview = ref.watch(profileOverviewProvider);
    final totals = ref.watch(profileTotalsProvider);

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CONSISTENT TACTICAL HEADER
          TacticalHeader(
            title: 'Profile',
            subTitle: 'YOUR STATS, STYLE, AND SETTINGS',
            status: 'PERSONAL HUB',
            statusColor: StrideColors.neonGreen,
            actions: [
              TacticalIconButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
                icon: Icons.settings,
              ),
            ],
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('ACCOUNT OVERVIEW'),
                  const SizedBox(height: 16),
                  if (overview != null)
                    _buildProfileHero(
                      displayName: overview.displayName,
                      level: overview.level,
                      bio: overview.bio,
                    )
                  else
                    profileAsync.when(
                      data: (_) => _buildProfileHeroLoading(),
                      loading: () => _buildProfileHeroLoading(),
                      error: (e, s) => _buildProfileHeroError(),
                    ),

                  const SizedBox(height: 48),

                  _sectionHeader('TOTALS'),
                  const SizedBox(height: 16),
                  if (totals != null)
                    Column(
                      children: [
                        _buildPrimaryStatsCard('DISTANCE', totals.distanceKm.toStringAsFixed(1), 'KM'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildStatsCard('AREAS HELD', totals.sectors.toString(), 'ZONES', Colors.white)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatsCard('CURRENT LEVEL', '${totals.level}', 'LEVEL', StrideColors.neonGreen.withValues(alpha: 0.7))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildRankStrip(totals.rank),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildPrimaryStatsCard('DISTANCE', '...', 'KM', isLoading: true),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildStatsCard('AREAS HELD', '...', 'ZONES', StrideColors.white.withValues(alpha: 0.2))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatsCard('CURRENT LEVEL', '...', 'LEVEL', StrideColors.neonGreen.withValues(alpha: 0.2))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildRankStrip(0, isLoading: true),
                        const SizedBox(height: 8),
                        Text('Loading stats...', style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted)),
                      ],
                    ),

                  const SizedBox(height: 48),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionHeader('ACHIEVEMENTS'),
                      Text('4 UNLOCKED', style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textPrimary.withValues(alpha: 0.3))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniMedal('FIRST', isUnlocked: true),
                      _buildMiniMedal('10KM', isUnlocked: true),
                      _buildMiniMedal('BOS', isUnlocked: true),
                      _buildMiniMedal('ACE', isUnlocked: true),
                      _buildSeeMoreMedal(),
                    ],
                  ),

                  const SizedBox(height: 60),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: StrideColors.white.withValues(alpha: 0.05))),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: StrideTypography.headlineMD.copyWith(fontSize: 18, fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildProfileHero({
    required String displayName,
    required int level,
    required String? bio,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StrideColors.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StrideColors.neonGreen.withValues(alpha: 0.10),
            StrideColors.neonGreen.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
        border: Border.all(color: StrideColors.neonGreen.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: StrideColors.neonGreen.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: StrideColors.neonGreen.withValues(alpha: 0.12),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    level.toString().padLeft(2, '0'),
                    style: StrideTypography.headlineMD.copyWith(fontSize: 24, color: StrideColors.neonGreen),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RUNNER PROFILE',
                      style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayName.toUpperCase(),
                      style: StrideTypography.headlineLG.copyWith(fontSize: 30),
                    ),
                    if (bio != null && bio.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        bio,
                        style: StrideTypography.bodyMD.copyWith(fontSize: 12, color: StrideColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniInfoCard('MEMBER STATUS', 'ACTIVE', StrideColors.neonGreen, isHighlighted: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniInfoCard('PROFILE', 'READY', Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeroLoading() {
    return Container(
      height: 200,
      width: double.infinity,
      color: StrideColors.surface,
      child: Center(
        child: Text('Loading profile...', style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textMuted)),
      ),
    );
  }

  Widget _buildProfileHeroError() {
    return Container(
      height: 200,
      width: double.infinity,
      color: StrideColors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: StrideColors.error, size: 18),
            const SizedBox(height: 6),
            Text('Profile unavailable', style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.error)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StrideColors.surface,
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textPrimary.withValues(alpha: 0.4))),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: StrideTypography.headlineMD.copyWith(fontSize: 28)),
              const SizedBox(width: 4),
              Text(unit, style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryStatsCard(String label, String value, String unit, {bool isLoading = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: StrideColors.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StrideColors.neonGreen.withValues(alpha: isLoading ? 0.05 : 0.09),
            Colors.transparent,
          ],
        ),
        border: Border(
          left: BorderSide(color: StrideColors.neonGreen.withValues(alpha: isLoading ? 0.25 : 0.7), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: StrideTypography.displayXL.copyWith(
                  fontSize: 44,
                  color: isLoading ? StrideColors.neonGreen.withValues(alpha: 0.35) : StrideColors.white,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  unit,
                  style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.neonGreen.withValues(alpha: 0.8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankStrip(int rank, {bool isLoading = false}) {
    final value = isLoading ? '...' : (rank > 0 ? '#$rank' : 'UNRANKED');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: StrideColors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Text(
            'GLOBAL RANK',
            style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted),
          ),
          const Spacer(),
          Text(
            value,
            style: StrideTypography.labelBold.copyWith(
              fontSize: 12,
              color: isLoading ? StrideColors.textMuted : StrideColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfoCard(String label, String value, Color accent, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: isHighlighted ? 0.78 : 1),
        border: Border.all(color: accent.withValues(alpha: isHighlighted ? 0.28 : 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textMuted)),
          const SizedBox(height: 6),
          Text(value, style: StrideTypography.labelBold.copyWith(fontSize: 12, color: accent)),
        ],
      ),
    );
  }

  Widget _buildMiniMedal(String label, {bool isUnlocked = false}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isUnlocked ? StrideColors.neonGreen.withValues(alpha: 0.05) : StrideColors.surface,
        border: Border.all(color: isUnlocked ? StrideColors.neonGreen : StrideColors.outline),
      ),
      child: Center(
        child: Text(label, style: StrideTypography.labelBold.copyWith(fontSize: 6, color: isUnlocked ? StrideColors.neonGreen : StrideColors.textMuted)),
      ),
    );
  }

  Widget _buildSeeMoreMedal() {
    return Container(
      width: 50,
      height: 50,
      color: StrideColors.white,
      child: Center(
        child: Text('SEE\nMORE', textAlign: TextAlign.center, style: StrideTypography.buttonText.copyWith(fontSize: 8, color: StrideColors.background)),
      ),
    );
  }
}
