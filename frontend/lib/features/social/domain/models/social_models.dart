import 'package:flutter/material.dart';

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String territoryColor;
  final double totalAreaSqm;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.territoryColor,
    required this.totalAreaSqm,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      territoryColor: json['territory_color'] ?? '#0ea5e9',
      totalAreaSqm: (json['total_area_sqm'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Color get color {
    try {
      final hex = territoryColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }
}

class DominionEntry {
  final String guildId;
  final String name;
  final String emblemColor;
  final double totalArea;
  final double percentage;

  DominionEntry({
    required this.guildId,
    required this.name,
    required this.emblemColor,
    required this.totalArea,
    required this.percentage,
  });

  factory DominionEntry.fromJson(Map<String, dynamic> json) {
    return DominionEntry(
      guildId: json['guild_id'] ?? '',
      name: json['name'] ?? '',
      emblemColor: json['emblem_color'] ?? '#38bdf8',
      totalArea: (json['total_area'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Color get color {
    try {
      final hex = emblemColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }
}

class GlobalActivity {
  final String id;
  final String userId;
  final String displayName;
  final String territoryColor;
  final double distanceKm;
  final int durationSec;
  final String status;
  final String? pathWkt;
  final DateTime createdAt;

  GlobalActivity({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.territoryColor,
    required this.distanceKm,
    required this.durationSec,
    required this.status,
    required this.pathWkt,
    required this.createdAt,
  });

  factory GlobalActivity.fromJson(Map<String, dynamic> json) {
    return GlobalActivity(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      displayName: json['display_name'] ?? 'Agent',
      territoryColor: json['territory_color'] ?? '#ffffff',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      durationSec: json['duration_sec'] ?? 0,
      status: json['status'] ?? 'pending',
      pathWkt: json['path_geometry'] as String?,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  Color get color {
    try {
      final hex = territoryColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }
}

class Graffiti {
  final String id;
  final String userId;
  final String displayName;
  final String territoryColor;
  final List<List<Offset>> strokes;
  final DateTime createdAt;

  Graffiti({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.territoryColor,
    required this.strokes,
    required this.createdAt,
  });

  factory Graffiti.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawStrokes = json['data'] ?? [];
    final List<List<Offset>> strokes = rawStrokes.map((s) {
      final List<dynamic> points = s as List<dynamic>;
      return points
          .map(
            (p) =>
                Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()),
          )
          .toList();
    }).toList();

    return Graffiti(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      displayName: json['display_name'] ?? 'Agent',
      territoryColor: json['color'] ?? json['territory_color'] ?? '#ffffff',
      strokes: strokes,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  Color get color {
    try {
      final hex = territoryColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }
}

DateTime _parseDateTime(dynamic raw) {
  if (raw is DateTime) return raw;
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw) ?? DateTime.now();
  }
  return DateTime.now();
}
