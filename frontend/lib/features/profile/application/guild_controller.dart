import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
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

class GuildController {
  final Ref _ref;
  final String _baseUrl = ApiConfig.baseUrl;

  GuildController(this._ref);

  bool get _logEnabled => _ref.read(supabaseDevLogEnabledProvider);

  Future<List<Guild>> fetchGuilds() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/guilds'));
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

  Future<bool> joinGuild(String guildId) async {
    final userId = _ref.read(currentUserSessionProvider);
    if (userId == null) return false;

    try {
      final response = await http.post(
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
        return true;
      }
      
      SupabaseLogger.log(_logEnabled, 'API Join Guild Failed', success: false, error: response.body);
      return false;
    } catch (e) {
      SupabaseLogger.log(_logEnabled, 'API Join Guild Error', success: false, error: e.toString());
      return false;
    }
  }
}

final guildsProvider = FutureProvider<List<Guild>>((ref) async {
  return ref.read(guildControllerProvider).fetchGuilds();
});
