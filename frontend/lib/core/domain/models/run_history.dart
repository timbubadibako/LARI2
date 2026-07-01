class RunHistory {
  final String id;
  final String userId;
  final double distanceKm;
  final int durationSec;
  final String status; // 'captured', 'pending', etc.
  final String? pathWkt;
  final DateTime createdAt;
  final String syncStatus; // 'pending' or 'synced'
  final int retryCount;
  final String? syncError;
  final String? quarantineReason;

  RunHistory({
    required this.id,
    required this.userId,
    required this.distanceKm,
    required this.durationSec,
    required this.status,
    this.pathWkt,
    required this.createdAt,
    this.syncStatus = 'synced',
    this.retryCount = 0,
    this.syncError,
    this.quarantineReason,
  });

  // Factory for API response (Go Backend)
  factory RunHistory.fromJson(Map<String, dynamic> json) {
    return RunHistory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
      durationSec: (json['duration_sec'] as num).toInt(),
      status: json['status'] as String,
      pathWkt: json['path_geometry'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      syncStatus: 'synced',
      retryCount: 0,
    );
  }

  // Factory for Unified Local/Remote structure (The "Sync Queue" format)
  factory RunHistory.fromMap(Map<String, dynamic> map) {
    final payload = Map<String, dynamic>.from(
      (map['payload'] as Map<dynamic, dynamic>).map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
    final createdAtRaw =
        map['created_at'] ?? map['createdAt'] ?? payload['created_at'];
    return RunHistory(
      id: map['id'] as String,
      userId: payload['user_id'] as String,
      distanceKm: (payload['distance_km'] as num).toDouble(),
      durationSec: (payload['duration_sec'] as num).toInt(),
      status: payload['status'] as String,
      pathWkt: payload['path_wkt'] as String?,
      createdAt: DateTime.parse(createdAtRaw as String),
      syncStatus: (map['status'] as String?) ?? 'pending',
      retryCount: (map['retry_count'] as int?) ?? 0,
      syncError: map['last_error'] as String?,
      quarantineReason: map['quarantine_reason'] as String?,
    );
  }

  // Factory for Direct Supabase Row
  factory RunHistory.fromSupabase(Map<String, dynamic> map) {
    return RunHistory(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      distanceKm: (map['distance_km'] as num).toDouble(),
      durationSec: (map['duration_sec'] as num).toInt(),
      status: map['status'] as String,
      pathWkt: map['path_geometry'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      syncStatus: 'synced',
      retryCount: 0,
    );
  }
}
