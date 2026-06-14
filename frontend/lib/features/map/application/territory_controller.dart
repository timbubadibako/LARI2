import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/lari_logger.dart';
import '../../../dev/dev_providers.dart';

final territoryControllerProvider = Provider<TerritoryController>((ref) {
  return TerritoryController(ref);
});

class UserTerritory {
  final String userId;
  final String sectorId;
  final Map<String, dynamic> geoJson;
  final double totalAreaSqm;
  final String color;

  UserTerritory({
    required this.userId,
    required this.sectorId,
    required this.geoJson,
    required this.totalAreaSqm,
    required this.color,
  });

  factory UserTerritory.fromJson(Map<String, dynamic> json) {
    return UserTerritory(
      userId: json['user_id'] as String,
      sectorId: json['sector_id'] as String,
      geoJson: jsonDecode(json['boundary_geojson'] as String) as Map<String, dynamic>,
      totalAreaSqm: (json['total_area_sqm'] as num).toDouble(),
      color: json['color'] as String? ?? '#0ea5e9',
    );
  }
}

class TerritoryController {
  final Ref _ref;

  TerritoryController(this._ref);

  bool get _logEnabled => _ref.read(lariDevLogEnabledProvider);

  Future<List<UserTerritory>> fetchAllTerritories() async {
    final baseUrl = _ref.read(baseUrlProvider);
    try {
      final response = await http.get(Uri.parse('$baseUrl/territories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserTerritory.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      LariLogger.log(_logEnabled, 'API Fetch Territories Error', success: false, error: e.toString());
      return [];
    }
  }
}

final allTerritoriesProvider = FutureProvider<List<UserTerritory>>((ref) async {
  return ref.read(territoryControllerProvider).fetchAllTerritories();
});
