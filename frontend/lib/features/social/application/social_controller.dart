import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/http_client_provider.dart';
import '../domain/models/social_models.dart';

final socialControllerProvider = Provider<SocialController>((ref) {
  return SocialController(ref);
});

class SocialController {
  final Ref _ref;
  final String _baseUrl = ApiConfig.baseUrl;

  SocialController(this._ref);

  http.Client get _client => _ref.read(httpClientProvider);

  // Derive WS URL from base URL (assuming ws:// if http://)
  String get _wsUrl {
    if (_baseUrl.startsWith('https')) {
      return _baseUrl.replaceFirst('https', 'wss');
    }
    return _baseUrl.replaceFirst('http', 'ws');
  }

  Stream<void> watchGlobalActivityStream() {
    final controller = StreamController<void>();
    try {
      final channel = WebSocketChannel.connect(Uri.parse('$_wsUrl/ws'));
      channel.stream.listen(
        (message) {
          // A message means a new run was broadcast
          controller.add(null);
        },
        onError: (e) {
          controller.addError(e);
        },
        onDone: () {
          controller.close();
        },
      );
      
      controller.onCancel = () {
        channel.sink.close();
      };
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard(String district) async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/leaderboard/$district')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => LeaderboardEntry.fromJson(e)).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Leaderboard uplink failed: $e');
    }
  }

  Future<List<DominionEntry>> fetchFactionDominion() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/guilds/dominion')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => DominionEntry.fromJson(e)).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Dominion sync failed: $e');
    }
  }

  Future<List<GlobalActivity>> fetchGlobalActivity() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/runs/global')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => GlobalActivity.fromJson(e)).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mission feed offline: $e');
    }
  }

  Future<List<Graffiti>> fetchRecentGraffiti() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/graffiti')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Graffiti.fromJson(e)).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Graffiti link disrupted: $e');
    }
  }

  Future<bool> postGraffiti(String userId, List<List<Map<String, double>>> data) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/graffiti'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'data': data,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
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

final recentGraffitiProvider = FutureProvider<List<Graffiti>>((ref) async {
  return ref.read(socialControllerProvider).fetchRecentGraffiti();
});

final globalActivityStreamProvider = StreamProvider<void>((ref) {
  return ref.read(socialControllerProvider).watchGlobalActivityStream();
});
