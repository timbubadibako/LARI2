import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/tactical_header.dart';
import '../../../../ui/components/mission_dossier_card.dart';
import '../../../../core/services/lari_sync_service.dart';
import '../../application/history_controller.dart';
import '../../../workout/presentation/screens/post_run_summary_screen.dart';
import 'dart:ui';

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
    final missions = historyAsync.asData?.value ?? [];
    final hasPending = missions.any((m) => m.syncStatus == 'pending');
    final filteredMissions = ref.watch(filteredUserHistoryProvider);
    final summary = ref.watch(historySummaryProvider);
    final selectedRange = ref.watch(historyRangeProvider);

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TacticalHeader(
            title: 'History',
            subTitle: 'YOUR RUNS AND RECENT RESULTS',
            status: hasPending ? 'SYNC NEEDED' : 'UP TO DATE',
            statusColor: hasPending ? StrideColors.warning : StrideColors.neonGreen,
            actions: [
              if (hasPending)
                TacticalIconButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await ref.read(lariSyncServiceProvider).processQueue();
                    ref.invalidate(userHistoryProvider);
                  },
                  icon: Icons.sync_outlined,
                  color: StrideColors.warning,
                ),
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

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(userHistoryProvider),
              color: StrideColors.neonGreen,
              backgroundColor: StrideColors.background,
              child: historyAsync.when(
                data: (missions) {
                  if (filteredMissions.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      children: [
                        _buildRangePicker(selectedRange),
                        const SizedBox(height: 18),
                        _buildSummaryRow(summary),
                        const SizedBox(height: 48),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.28,
                          child: Center(
                            child: Text(
                              'NO RUNS FOUND FOR THIS PERIOD.',
                              style: StrideTypography.labelTactical.copyWith(color: StrideColors.textMuted),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    children: [
                      _buildRangePicker(selectedRange),
                      const SizedBox(height: 18),
                      _buildSummaryRow(summary),
                      const SizedBox(height: 24),
                      ...List.generate(filteredMissions.length, (index) {
                        final mission = filteredMissions[index];
                        final isCaptured = mission.status == 'captured';
                        final isPendingSync = mission.syncStatus == 'pending';
                        final statusColor = isPendingSync
                            ? StrideColors.warning
                            : (isCaptured ? StrideColors.neonGreen : Colors.white.withValues(alpha: 0.4));

                        return Padding(
                          padding: EdgeInsets.only(bottom: index == filteredMissions.length - 1 ? 0 : 16),
                          child: MissionDossierCard(
                            id: mission.id,
                            title: isCaptured ? 'Area Acquisition' : 'Standard Activity',
                            status: mission.status,
                            distanceKm: mission.distanceKm,
                            durationSec: mission.durationSec,
                            createdAt: mission.createdAt,
                            pathWkt: mission.pathWkt,
                            statusColor: statusColor,
                            isPendingSync: isPendingSync,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostRunSummaryScreen(missionOverride: mission),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ],
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

  Widget _buildRangePicker(HistoryRange selectedRange) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StrideColors.surface,
        border: Border.all(color: StrideColors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: HistoryRange.values.map((range) {
          final isSelected = range == selectedRange;
          final label = switch (range) {
            HistoryRange.week => 'WEEK',
            HistoryRange.month => 'MONTH',
            HistoryRange.year => 'YEAR',
          };

          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(historyRangeProvider.notifier).setRange(range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? StrideColors.neonGreen : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? StrideColors.neonGreen
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: StrideTypography.labelTactical.copyWith(
                      fontSize: 8,
                      color: isSelected ? Colors.black : StrideColors.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryRow(({double distanceKm, int runCount, int capturedCount}) summary) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard('Distance', '${summary.distanceKm.toStringAsFixed(1)} km', StrideColors.neonGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard('Runs', '${summary.runCount}', Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard('Captured', '${summary.capturedCount}', StrideColors.warning),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 3,
            color: accent,
            margin: const EdgeInsets.only(bottom: 12),
          ),
          Text(
            label.toUpperCase(),
            style: StrideTypography.labelTactical.copyWith(
              fontSize: 7,
              color: StrideColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: StrideTypography.headlineMD.copyWith(
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
