class RunHistory {
  final String id;
  final String userId;
  final double distanceKm;
  final int durationSec;
  final String status; // 'captured', 'pending', etc.
  final String? pathWkt;
  final DateTime createdAt;
  final String syncStatus; // 'pending' or 'synced'

  RunHistory({
    required this.id,
    required this.userId,
    required this.distanceKm,
    required this.durationSec,
    required this.status,
    this.pathWkt,
    required this.createdAt,
    this.syncStatus = 'synced',
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
    );
  }

  // Factory for Unified Local/Remote structure (The "Sync Queue" format)
  factory RunHistory.fromMap(Map<String, dynamic> map) {
    final payload = map['payload'] as Map<dynamic, dynamic>;
    return RunHistory(
      id: map['id'] as String,
      userId: payload['user_id'] as String,
      distanceKm: (payload['distance_km'] as num).toDouble(),
      durationSec: (payload['duration_sec'] as num).toInt(),
      status: payload['status'] as String,
      pathWkt: payload['path_wkt'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      syncStatus: map['status'] as String,
    );
  }
}
