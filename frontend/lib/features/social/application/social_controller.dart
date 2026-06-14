import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/http_client_provider.dart';
import '../../../core/config/api_config.dart';
import '../domain/models/social_models.dart';

final socialControllerProvider = Provider<SocialController>((ref) {
  return SocialController(ref);
});

class SocialController {
  final Ref _ref;

  SocialController(this._ref);

  /// Note: WebSocket would be better for real-time, 
  /// for now we stub or use polling if needed.
  Stream<List<Map<String, dynamic>>> watchGlobalActivityStream() {
    return const Stream.empty(); 
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard(String district) async {
    try {
      final client = _ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(_ref);

      final response = await client.get(
        Uri.parse('$baseUrl/leaderboard/$district'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LeaderboardEntry.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<DominionEntry>> fetchGuildDominion() async {
    try {
      final client = _ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(_ref);
      
      final response = await client.get(
        Uri.parse('$baseUrl/guilds/dominion'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => DominionEntry.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<GlobalActivity>> fetchGlobalActivity() async {
    try {
      final client = _ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(_ref);
      
      final response = await client.get(
        Uri.parse('$baseUrl/runs/global'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => GlobalActivity.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Graffiti>> fetchRecentGraffiti() async {
    try {
      final client = _ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(_ref);
      
      final response = await client.get(
        Uri.parse('$baseUrl/graffiti'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Graffiti.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> postGraffiti(String userId, List<List<Map<String, double>>> data) async {
    try {
      final client = _ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(_ref);
      
      final response = await client.post(
        Uri.parse('$baseUrl/graffiti'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'data': data,
        }),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}


final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, String>((ref, district) async {
  return ref.read(socialControllerProvider).fetchLeaderboard(district);
});

final guildDominionProvider = FutureProvider<List<DominionEntry>>((ref) async {
  return ref.read(socialControllerProvider).fetchGuildDominion();
});

final globalActivityProvider = FutureProvider<List<GlobalActivity>>((ref) async {
  return ref.read(socialControllerProvider).fetchGlobalActivity();
});

final recentGraffitiProvider = FutureProvider<List<Graffiti>>((ref) async {
  return ref.read(socialControllerProvider).fetchRecentGraffiti();
});

final globalActivityStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(socialControllerProvider).watchGlobalActivityStream();
});
