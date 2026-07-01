import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/models/run_history.dart';
import '../../../core/services/lari_sync_service.dart';
import '../../../core/services/http_client_provider.dart';
import '../../../core/config/api_config.dart';
import '../../auth/application/auth_controller.dart';

final historyControllerProvider = Provider<HistoryController>((ref) {
  return HistoryController(ref);
});

enum HistoryRange { week, month, year }

typedef HistorySummary = ({double distanceKm, int runCount, int capturedCount});

class HistoryController {
  final Ref _ref;

  HistoryController(this._ref);

  Future<List<RunHistory>> fetchUserHistory() async {
    final userId = _ref.read(currentUserSessionProvider);
    if (userId == null) return [];

    final syncService = _ref.read(lariSyncServiceProvider);
    
    // 1. Get Local Offline Missions that are not fully synced yet.
    final localMissions = syncService.getAllMissions();
    final List<RunHistory> localHistory = localMissions
        .where((m) =>
            m['status'] == 'pending' ||
            m['status'] == 'processing' ||
            m['status'] == 'quarantined')
        .map((m) => RunHistory.fromMap(m))
        .toList();

    try {
      // 2. Fetch from Go Backend
      final client = _ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(_ref);

      debugPrint('HISTORY_FETCH: Requesting runs for $userId from $baseUrl');

      final response = await client.get(
        Uri.parse('$baseUrl/runs?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('HISTORY_FETCH: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> remoteData = jsonDecode(response.body);
        debugPrint('HISTORY_FETCH: Received ${remoteData.length} remote runs.');

        final List<RunHistory> remoteHistory = remoteData.map((m) {
          try {
            return RunHistory.fromJson(m as Map<String, dynamic>);
          } catch (e) {
            debugPrint('HISTORY_PARSE_ERROR: Failed to parse run: $e\nData: $m');
            rethrow;
          }
        }).toList();

        // 3. MERGE BOTH: Local (Pending) + Remote (Synced)
        final merged = [...localHistory, ...remoteHistory];
        merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return merged;
      } else {
        debugPrint('HISTORY_FETCH_ERROR: Server returned ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('HISTORY_EXCEPTION: $e\n$stack');
    }
    return localHistory;
  }

  Future<bool> clearHistory() async {
    final userId = _ref.read(currentUserSessionProvider);
    if (userId == null) return false;

    try {
      final client = _ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(_ref);
      
      final response = await client.delete(
        Uri.parse('$baseUrl/runs?user_id=$userId'),
      );
      
      if (response.statusCode == 200) {
        _ref.invalidate(userHistoryProvider);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final userHistoryProvider = FutureProvider<List<RunHistory>>((ref) async {
  return ref.read(historyControllerProvider).fetchUserHistory();
});

class HistoryRangeNotifier extends Notifier<HistoryRange> {
  @override
  HistoryRange build() => HistoryRange.week;

  void setRange(HistoryRange range) => state = range;
}

final historyRangeProvider = NotifierProvider<HistoryRangeNotifier, HistoryRange>(
  HistoryRangeNotifier.new,
);

final filteredUserHistoryProvider = Provider<List<RunHistory>>((ref) {
  final history = ref.watch(userHistoryProvider).asData?.value ?? const <RunHistory>[];
  final range = ref.watch(historyRangeProvider);
  final now = DateTime.now();
  final start = switch (range) {
    HistoryRange.week => now.subtract(const Duration(days: 7)),
    HistoryRange.month => DateTime(now.year, now.month - 1, now.day),
    HistoryRange.year => DateTime(now.year - 1, now.month, now.day),
  };

  return history.where((mission) => mission.createdAt.isAfter(start)).toList();
});

final historySummaryProvider = Provider<HistorySummary>((ref) {
  final missions = ref.watch(filteredUserHistoryProvider);
  double distanceKm = 0;
  int capturedCount = 0;

  for (final mission in missions) {
    distanceKm += mission.distanceKm;
    if (mission.status == 'captured') {
      capturedCount++;
    }
  }

  return (
    distanceKm: distanceKm,
    runCount: missions.length,
    capturedCount: capturedCount,
  );
});
