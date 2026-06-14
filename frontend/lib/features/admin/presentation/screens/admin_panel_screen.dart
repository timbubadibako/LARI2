import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../ui/components/tactical_header.dart';
import '../../../../ui/components/app_strings.dart';
import '../../../map/application/territory_controller.dart';
import '../../../profile/application/profile_controller.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final territoriesAsync = ref.watch(allTerritoriesProvider);

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: SafeArea(
        child: Column(
          children: [
            TacticalHeader(title: AppStrings.adminPanel),
            Expanded(
              child: territoriesAsync.when(
                data: (territories) {
                  final totalArea = territories.fold(0.0, (sum, t) => sum + t.totalAreaSqm);
                  final userCount = territories.map((t) => t.userId).toSet().length;

                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildStatCard('TOTAL_RUNNERS_ACTIVE', userCount.toString()),
                      const SizedBox(height: 16),
                      _buildStatCard('GLOBAL_CONQUERED_AREA', '${(totalArea / 1000).toStringAsFixed(2)} KM²'),
                      const SizedBox(height: 32),
                      Text('RECENT_SECTOR_ACQUISITIONS', style: StrideTypography.labelTactical),
                      const SizedBox(height: 16),
                      ...territories.take(10).map((t) => _buildRecentActivityItem(t)),
                      const SizedBox(height: 40),
                      _buildDangerZone(context),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: StrideColors.neonGreen)),
                error: (e, s) => Center(child: Text('${AppStrings.accessDenied}: $e', style: const TextStyle(color: StrideColors.error))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return V3SlantBox(
      color: StrideColors.surface,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: StrideColors.neonGreen, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: StrideTypography.labelTactical.copyWith(fontSize: 10, color: StrideColors.textSecondary)),
            const SizedBox(height: 8),
            Text(value, style: StrideTypography.displayXL.copyWith(fontSize: 32, color: StrideColors.neonGreen)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityItem(UserTerritory territory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: StrideColors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, color: Color(int.parse(territory.color.replaceFirst('#', '0xFF')))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RUNNER_${territory.userId.substring(0, 8)}', style: StrideTypography.labelBold.copyWith(fontSize: 10)),
                Text('SECTOR: ${territory.sectorId}', style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: StrideColors.textSecondary)),
              ],
            ),
          ),
          Text('+${territory.totalAreaSqm.toInt()} m²', style: StrideTypography.labelBold.copyWith(color: StrideColors.neonGreen, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: StrideColors.error),
        const SizedBox(height: 8),
        Text('DANGER_ZONE', style: StrideTypography.labelTactical.copyWith(color: StrideColors.error)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Implementation for Nuke/Reset
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: StrideColors.error.withOpacity(0.1),
              side: const BorderSide(color: StrideColors.error),
              foregroundColor: StrideColors.error,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('INITIATE_GLOBAL_GRID_RESET (NUKE)'),
          ),
        ),
      ],
    );
  }
}
