import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/api_config.dart';
import '../../../core/domain/models/run_history.dart';
import '../../../core/services/sync_queue_service.dart';
import '../../auth/application/auth_controller.dart';

final historyControllerProvider = Provider<HistoryController>((ref) {
  return HistoryController(ref);
});

class HistoryController {
  final Ref _ref;
  final String _baseUrl = ApiConfig.baseUrl;

  HistoryController(this._ref);

  Future<List<RunHistory>> fetchUserHistory() async {
    final userId = _ref.read(currentUserSessionProvider);
    if (userId == null) return [];

    final syncService = _ref.read(syncQueueServiceProvider);

    try {
      // 1. Reconcile with Go Backend
      await syncService.reconcileWithServer(userId);
      
      // 2. Process pending
      await syncService.processQueue();

      // 3. Convert all local missions to RunHistory models
      final missions = syncService.getAllMissions();
      return missions.map((m) => RunHistory.fromMap(m)).toList();
    } catch (e) {
      final missions = syncService.getAllMissions();
      return missions.map((m) => RunHistory.fromMap(m)).toList();
    }
  }

  Future<bool> clearHistory() async {
    final userId = _ref.read(currentUserSessionProvider);
    if (userId == null) return false;

    try {
      final response = await http.delete(Uri.parse('$_baseUrl/runs?user_id=$userId'));
      if (response.statusCode == 200) {
        _ref.invalidate(userHistoryProvider);
        return true;
      }
    } catch (e) {
      // log
    }
    return false;
  }
}

final userHistoryProvider = FutureProvider<List<RunHistory>>((ref) async {
  return ref.read(historyControllerProvider).fetchUserHistory();
});
