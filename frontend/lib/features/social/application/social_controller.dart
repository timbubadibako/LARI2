import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/api_config.dart';
import '../domain/models/social_models.dart';

final socialControllerProvider = Provider<SocialController>((ref) {
  return SocialController();
});

class SocialController {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<List<LeaderboardEntry>> fetchLeaderboard(String district) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/leaderboard/$district'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => LeaderboardEntry.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Uplink failed: Check central intel server connection.');
    }
  }

  Future<List<DominionEntry>> fetchFactionDominion() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/guilds/dominion'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => DominionEntry.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load dominion: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Faction sync failed: Central intelligence unreachable.');
    }
  }

  Future<List<GlobalActivity>> fetchGlobalActivity() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/runs/global'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => GlobalActivity.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load activity: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mission feed offline: Satellite link disrupted.');
    }
  }
}

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, String>((ref, district) async {
  return ref.read(socialControllerProvider).fetchLeaderboard(district);
});

final factionDominionProvider = FutureProvider<List<DominionEntry>>((ref) async {
  return ref.read(socialControllerProvider).fetchFactionDominion();
});

final globalActivityProvider = FutureProvider<List<GlobalActivity>>((ref) async {
  return ref.read(socialControllerProvider).fetchGlobalActivity();
});
