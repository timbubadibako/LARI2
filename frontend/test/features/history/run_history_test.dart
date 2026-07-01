import 'package:flutter_test/flutter_test.dart';
import 'package:lari_lari/core/domain/models/run_history.dart';

void main() {
  group('RunHistory.fromMap', () {
    test('parses local queue records using created_at fallback', () {
      final history = RunHistory.fromMap({
        'id': 'run-1',
        'status': 'pending',
        'retry_count': 2,
        'last_error': 'HTTP 401',
        'payload': {
          'user_id': 'user-1',
          'distance_km': 3.2,
          'duration_sec': 1200,
          'status': 'finished',
          'created_at': '2026-07-01T00:00:00Z',
          'path_wkt': 'LINESTRING(106.8 -6.2, 106.81 -6.21)',
        },
      });

      expect(history.id, 'run-1');
      expect(history.syncStatus, 'pending');
      expect(history.retryCount, 2);
      expect(history.syncError, 'HTTP 401');
      expect(history.pathWkt, isNotNull);
      expect(history.createdAt.toUtc().toIso8601String(), '2026-07-01T00:00:00.000Z');
    });
  });
}
