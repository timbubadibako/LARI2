class UserProfile {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final String? factionId;
  final String? territoryColor;
  final int level;
  final int xp;
  final String? bio;
  final bool publicProfile;
  final bool ghostMode;
  final bool isFallback;
  final double totalDistanceKm;
  final int totalSectorsHeld;
  final int globalRank;

  UserProfile({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.factionId,
    this.territoryColor,
    this.level = 1,
    this.xp = 0,
    this.bio,
    this.publicProfile = false,
    this.ghostMode = false,
    this.isFallback = false,
    this.totalDistanceKm = 0.0,
    this.totalSectorsHeld = 0,
    this.globalRank = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      factionId: json['guild_id']?.toString() ?? json['faction_id']?.toString(),
      territoryColor: json['territory_color']?.toString(),
      level: _asInt(json['level'], 1),
      xp: _asInt(json['xp'], 0),
      bio: json['bio']?.toString(),
      publicProfile: json['public_profile'] as bool? ?? false,
      ghostMode: json['ghost_mode'] as bool? ?? false,
      isFallback: false,
      totalDistanceKm: _asDouble(json['total_distance_km'], 0.0),
      totalSectorsHeld: _asInt(json['total_sectors_held'], 0),
      globalRank: _asInt(json['global_rank'], 0),
    );
  }

  static int _asInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    String? factionId,
    String? territoryColor,
    int? level,
    int? xp,
    String? bio,
    bool? publicProfile,
    bool? ghostMode,
    bool? isFallback,
    double? totalDistanceKm,
    int? totalSectorsHeld,
    int? globalRank,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      factionId: factionId ?? this.factionId,
      territoryColor: territoryColor ?? this.territoryColor,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      bio: bio ?? this.bio,
      publicProfile: publicProfile ?? this.publicProfile,
      ghostMode: ghostMode ?? this.ghostMode,
      isFallback: isFallback ?? this.isFallback,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      totalSectorsHeld: totalSectorsHeld ?? this.totalSectorsHeld,
      globalRank: globalRank ?? this.globalRank,
    );
  }

  String get displayNameOrFallback {
    final value = displayName?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return 'Agent';
  }

  String get bioOrPlaceholder {
    final value = bio?.trim();
    return (value != null && value.isNotEmpty) ? value : 'Bio belum diisi';
  }

  bool get hasAvatar => avatarUrl != null && avatarUrl!.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'faction_id': factionId,
      'territory_color': territoryColor,
      'level': level,
      'xp': xp,
      'bio': bio,
      'public_profile': publicProfile,
      'ghost_mode': ghostMode,
      'total_distance_km': totalDistanceKm,
      'total_sectors_held': totalSectorsHeld,
      'global_rank': globalRank,
    };
  }
}
