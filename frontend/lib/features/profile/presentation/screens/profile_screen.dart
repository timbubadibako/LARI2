import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/tactical_header.dart';
import '../../../../dev/debug_screen.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../application/profile_controller.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CONSISTENT TACTICAL HEADER
          TacticalHeader(
            title: 'AGENT_DOSSIER',
            subTitle: 'IDENTITY_VERIFICATION',
            status: 'RANK: VANGUARD_04',
            actions: [
              TacticalIconButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DebugScreen()));
                },
                icon: Icons.bug_report_outlined,
              ),
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
                  // IDENTITY CUSTOM
                  _sectionHeader('IDENTITY_CUSTOM'),
                  const SizedBox(height: 16),
                  
                  Text('ACTIVE_RADIATION_SIGNAL', style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textPrimary.withOpacity(0.4))),
                  const SizedBox(height: 12),
                  _buildColorPicker(),
                  
                  const SizedBox(height: 24),
                  Text('SIGNATURE_TAG', style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textPrimary.withOpacity(0.4))),
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: StrideColors.surface,
                      border: Border.all(color: StrideColors.white.withOpacity(0.05)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background watermark
                        Text('VERIFIED', style: StrideTypography.displayXL.copyWith(fontSize: 60, color: StrideColors.white.withOpacity(0.02))),
                        
                        Transform.rotate(
                          angle: -0.05,
                          child: Text('JRILLYM_01', style: StrideTypography.graffitiStyle.copyWith(fontSize: 32, color: StrideColors.neonGreen)),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: V3SkewBox(
                            skewAmount: -0.15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              color: StrideColors.white.withOpacity(0.1),
                              child: Text('EDIT_TAG', style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // CAREER DOSSIER
                  _sectionHeader('CAREER_STATS'),
                  const SizedBox(height: 16),
                  profileAsync.when(
                    data: (profile) {
                      final dist = profile?.totalDistanceKm ?? 0;
                      final sectors = profile?.totalSectorsHeld ?? 0;
                      final rank = profile?.globalRank ?? 0;
                      
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildStatsCard('TOTAL_CAPTURE', dist.toStringAsFixed(1), 'KM', StrideColors.neonGreen)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatsCard('SECTORS_HELD', sectors.toString(), 'GRIDS', StrideColors.white)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStatsCard('GLOBAL_RANK', rank > 0 ? '#$rank' : 'UNRANKED', 'KUNINGAN_SECTOR', StrideColors.white.withOpacity(0.2)),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: StrideColors.neonGreen)),
                    error: (e, s) => Text('DATA_CORRUPTED', style: StrideTypography.labelBold.copyWith(color: StrideColors.error)),
                  ),

                  const SizedBox(height: 48),

                  // MEDALS RECON
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionHeader('MEDALS_RECON'),
                      Text('4_UNLOCKED', style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textPrimary.withOpacity(0.3))),
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

                  // DANGER ZONE
                  Center(
                    child: Column(
                      children: [
                        const V3HazardBar(height: 4, color: StrideColors.error),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () async {
                            await ref.read(authControllerProvider).signOut();
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                          },
                          child: Text('TERMINATE_SESSION', style: StrideTypography.labelBold.copyWith(color: StrideColors.error, fontSize: 10, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ),
                  
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
        border: Border(bottom: BorderSide(color: StrideColors.white.withOpacity(0.05))),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: StrideTypography.headlineMD.copyWith(fontSize: 18, fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      const Color(0xFFCCFF00), const Color(0xFFFF007A), const Color(0xFF00F0FF),
      const Color(0xFFFF5F00), const Color(0xFFBC00FF), const Color(0xFFFFF000),
      const Color(0xFFFF0000),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: colors.map((c) => Container(
        width: 38,
        height: 30,
        color: c,
      )).toList(),
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
          Text(label, style: StrideTypography.labelTactical.copyWith(fontSize: 7, color: StrideColors.textPrimary.withOpacity(0.4))),
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

  Widget _buildMiniMedal(String label, {bool isUnlocked = false}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isUnlocked ? StrideColors.neonGreen.withOpacity(0.05) : StrideColors.surface,
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
