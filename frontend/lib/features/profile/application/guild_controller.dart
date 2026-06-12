import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/http_client_provider.dart';
import '../../../core/services/supabase_logger.dart';
import '../../../dev/dev_providers.dart';
import '../../auth/application/auth_controller.dart';
import 'profile_controller.dart';

final guildControllerProvider = Provider<GuildController>((ref) {
  return GuildController(ref);
});

class Guild {
  final String id;
  final String name;
  final String emblemColor;

  Guild({required this.id, required this.name, required this.emblemColor});

  factory Guild.fromJson(Map<String, dynamic> json) {
    return Guild(
      id: json['id'] as String,
      name: json['name'] as String,
      emblemColor: json['emblem_color'] as String,
    );
  }
}

class FactionDominion {
  final String guildId;
  final String name;
  final String emblemColor;
  final double totalArea;
  final double percentage;

  FactionDominion({
    required this.guildId,
    required this.name,
    required this.emblemColor,
    required this.totalArea,
    required this.percentage,
  });

  factory FactionDominion.fromJson(Map<String, dynamic> json) {
    return FactionDominion(
      guildId: json['guild_id'] as String,
      name: json['name'] as String,
      emblemColor: json['emblem_color'] as String,
      totalArea: (json['total_area'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class GuildController {
  final Ref _ref;
  final String _baseUrl = ApiConfig.baseUrl;

  GuildController(this._ref);

  http.Client get _client => _ref.read(httpClientProvider);
  bool get _logEnabled => _ref.read(supabaseDevLogEnabledProvider);

  Future<List<Guild>> fetchGuilds() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/guilds'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Guild.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      SupabaseLogger.log(_logEnabled, 'API Fetch Guilds Error', success: false, error: e.toString());
      return [];
    }
  }

  Future<List<FactionDominion>> fetchDominion() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/guilds/dominion'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => FactionDominion.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      SupabaseLogger.log(_logEnabled, 'API Fetch Dominion Error', success: false, error: e.toString());
      return [];
    }
  }

  Future<bool> joinGuild(String guildId) async {
    final userId = _ref.read(currentUserSessionProvider);
    if (userId == null) return false;

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/guilds/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'guild_id': guildId,
        }),
      );

      if (response.statusCode == 200) {
        SupabaseLogger.log(_logEnabled, 'API Join Guild Success');
        _ref.invalidate(profileControllerProvider);
        _ref.invalidate(dominionProvider); // Invalidate dominion when joining
        return true;
      }

      SupabaseLogger.log(_logEnabled, 'API Join Guild Failed', success: false, error: response.body);
      return false;
    } catch (e) {
      SupabaseLogger.log(_logEnabled, 'API Join Guild Error', success: false, error: e.toString());
      return false;
    }
  }

  Future<bool> leaveGuild() async {
    final userId = _ref.read(currentUserSessionProvider);
    if (userId == null) return false;

    try {
      // We'll use a specific endpoint or just update profile with null guild_id
      // For now, let's assume there's a leave endpoint or use the profile update
      final response = await _client.post(
        Uri.parse('$_baseUrl/guilds/leave'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        SupabaseLogger.log(_logEnabled, 'API Leave Guild Success');
        _ref.invalidate(profileControllerProvider);
        _ref.invalidate(dominionProvider);
        return true;
      }
      return false;
    } catch (e) {
      SupabaseLogger.log(_logEnabled, 'API Leave Guild Error', success: false, error: e.toString());
      return false;
    }
  }
}

final guildsProvider = FutureProvider<List<Guild>>((ref) async {
  return ref.read(guildControllerProvider).fetchGuilds();
});

final dominionProvider = FutureProvider<List<FactionDominion>>((ref) async {
  return ref.read(guildControllerProvider).fetchDominion();
});

