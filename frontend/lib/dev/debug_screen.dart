import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../ui/theme/stride_colors.dart';
import '../ui/theme/stride_typography.dart';
import '../ui/components/tactical_header.dart';
import '../ui/components/v3_shapes.dart';
import '../core/services/sync_queue_service.dart';
import '../core/services/workout_storage_service.dart';
import '../core/services/supabase_logger.dart';
import 'dev_providers.dart';
import 'dev_menu.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncQueue = ref.watch(syncQueueServiceProvider);
    final workoutStorage = ref.watch(workoutStorageServiceProvider);
    final prefs = ref.watch(sharedPreferencesProvider);

    final syncQueueItems = syncQueue.getAllMissions();
    final workoutItems = workoutStorage.getAllWorkouts();
    final logs = SupabaseLogger.logs;
    final prefKeys = prefs.getKeys();

    return Scaffold(
      backgroundColor: StrideColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TacticalHeader(
            title: 'DEBUG_CONSOLE_V2',
            subTitle: 'DEVELOPER_TOOLS',
            status: 'GOD_MODE_ACTIVE',
            statusColor: StrideColors.warning,
            actions: [
              TacticalIconButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DevMenu()));
                },
                icon: Icons.settings_input_component_outlined,
              ),
              TacticalIconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icons.close,
                color: StrideColors.error,
              ),
            ],
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SYSTEM OVERRIDE
                  _sectionHeader('SYSTEM_OVERRIDE'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDebugButton(
                          'WIPE_ALL_DATA',
                          Icons.auto_delete_outlined,
                          StrideColors.error,
                          () async {
                            final confirmed = await _showConfirmDialog(context, 'WIPE EVERYTHING?', 'This will clear SharedPreferences, Hive Boxes, and terminate the session.');
                            if (confirmed) {
                              await Hive.deleteFromDisk();
                              await prefs.clear();
                              SupabaseLogger.clearLogs();
                              HapticFeedback.heavyImpact();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('RESTART REQUIRED FOR FULL RESET')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDebugButton(
                          'FORCE_SYNC',
                          Icons.sync_outlined,
                          StrideColors.neonGreen,
                          () async {
                            HapticFeedback.mediumImpact();
                            await syncQueue.processQueue();
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // SYSTEM LOGS
                  _sectionHeader('SYSTEM_LOGS (${logs.length})'),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: StrideColors.white.withOpacity(0.05)),
                    ),
                    child: ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[logs.length - 1 - index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            log.toString(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              color: log.success ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () => SupabaseLogger.clearLogs(),
                    child: Text('CLEAR_LOGS', style: StrideTypography.labelBold.copyWith(fontSize: 8, color: StrideColors.textMuted)),
                  ),

                  const SizedBox(height: 48),

                  // HIVE INSPECTOR: SYNC_QUEUE
                  _sectionHeader('HIVE_INSPECTOR: SYNC_QUEUE (${syncQueueItems.length})'),
                  const SizedBox(height: 16),
                  ...syncQueueItems.map((item) => _buildInspectorTile(
                    'MISSION_${item['id'].toString().substring(0, 8)}',
                    'STATUS: ${item['status']}',
                    item['status'] == 'synced' ? StrideColors.neonGreen : StrideColors.warning,
                    item,
                  )),

                  const SizedBox(height: 48),

                  // HIVE INSPECTOR: WORKOUTS
                  _sectionHeader('HIVE_INSPECTOR: WORKOUTS (${workoutItems.length})'),
                  const SizedBox(height: 16),
                  ...workoutItems.map((item) => _buildInspectorTile(
                    'SESSION_${item['id'].toString().substring(0, 8)}',
                    'DIST: ${item['distanceMeters'].toStringAsFixed(0)}M',
                    StrideColors.white,
                    item,
                  )),

                  const SizedBox(height: 48),

                  // SHARED PREFERENCES
                  _sectionHeader('SHARED_PREFERENCES (${prefKeys.length})'),
                  const SizedBox(height: 16),
                  ...prefKeys.map((key) => _buildInspectorTile(
                    key,
                    'TYPE: ${prefs.get(key).runtimeType}',
                    StrideColors.warning,
                    {'value': prefs.get(key)},
                  )),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          
          const V3HazardBar(height: 8, color: StrideColors.warning),
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
      child: Text(title, style: StrideTypography.labelTactical.copyWith(fontSize: 10, color: StrideColors.textMuted)),
    );
  }

  Widget _buildDebugButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: StrideColors.surface,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: StrideTypography.labelBold.copyWith(fontSize: 8, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectorTile(String title, String subtitle, Color color, Map<String, dynamic> data) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(title, style: StrideTypography.labelBold.copyWith(fontSize: 12)),
      subtitle: Text(subtitle, style: StrideTypography.labelTactical.copyWith(fontSize: 8, color: color.withOpacity(0.6))),
      collapsedIconColor: StrideColors.textMuted,
      iconColor: StrideColors.neonGreen,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.black,
          child: Text(
            data.toString().replaceAll(', ', ',\n'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.green),
          ),
        ),
      ],
    );
  }

  Future<bool> _showConfirmDialog(BuildContext context, String title, [String? content]) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: StrideColors.surface,
        title: Text(title, style: StrideTypography.labelBold.copyWith(color: StrideColors.error)),
        content: Text(content ?? 'This action cannot be undone and may corrupt your mission history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('PROCEED', style: TextStyle(color: StrideColors.error)),
          ),
        ],
      ),
    ) ?? false;
  }
}
