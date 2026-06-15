import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/tactical_header.dart';
import '../../../../ui/components/app_strings.dart';
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

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TacticalHeader(
            title: AppStrings.runHistory,
            subTitle: AppStrings.runHistorySubtitle,
            status: hasPending ? 'QUEUED_TRANSMISSIONS' : 'DATA_SYNCED',
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
                      final isCaptured = mission.status == 'captured';
                      final isPendingSync = mission.syncStatus == 'pending';
                      final statusColor = isPendingSync 
                          ? StrideColors.warning 
                          : (isCaptured ? StrideColors.neonGreen : Colors.white.withValues(alpha: 0.4));
                      
                      return MissionDossierCard(
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
                      );
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
}
