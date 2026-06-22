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
    final rawBoundary = json['boundary_geojson'];
    // boundary_geojson can be a pre-decoded Map or a JSON string
    final Map<String, dynamic> geoJson = rawBoundary is String
        ? jsonDecode(rawBoundary) as Map<String, dynamic>
        : rawBoundary as Map<String, dynamic>;
    return UserTerritory(
      userId: json['user_id'] as String,
      sectorId: json['sector_id'] as String,
      geoJson: geoJson,
      totalAreaSqm: (json['total_area_sqm'] as num).toDouble(),
      color: json['color'] as String? ?? '#0ea5e9',
    );
  }
}

/// Bounding box for viewport-based territory fetching.
class TerritoryViewportBounds {
  final double lonMin, latMin, lonMax, latMax;
  const TerritoryViewportBounds({
    required this.lonMin,
    required this.latMin,
    required this.lonMax,
    required this.latMax,
  });
}

class TerritoryController {
  final Ref _ref;

  TerritoryController(this._ref);

  bool get _logEnabled => _ref.read(lariDevLogEnabledProvider);
  String get _baseUrl => _ref.read(baseUrlProvider);

  /// Fetch all territories without viewport filter.
  /// Use fetchWithBounds() when the map viewport is known for better performance.
  Future<List<UserTerritory>> fetchAllTerritories() async {
    return _fetchTerritories(null);
  }

  /// Fetch territories within a specific map viewport bounding box.
  /// This is the preferred method when the map is visible — reduces data transfer significantly.
  Future<List<UserTerritory>> fetchWithBounds(TerritoryViewportBounds bounds) async {
    return _fetchTerritories(bounds);
  }

  Future<List<UserTerritory>> _fetchTerritories(TerritoryViewportBounds? bounds) async {
    try {
      final uri = Uri.parse('$_baseUrl/territories').replace(
        queryParameters: bounds != null
            ? {
                'lon_min': bounds.lonMin.toString(),
                'lat_min': bounds.latMin.toString(),
                'lon_max': bounds.lonMax.toString(),
                'lat_max': bounds.latMax.toString(),
              }
            : null,
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => UserTerritory.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      LariLogger.log(_logEnabled, 'Territories fetch: HTTP ${response.statusCode}', success: false);
      return [];
    } catch (e) {
      LariLogger.log(_logEnabled, 'API Fetch Territories Error', success: false, error: e.toString());
      return [];
    }
  }
}

class TerritoryViewportBoundsNotifier extends Notifier<TerritoryViewportBounds?> {
  @override
  TerritoryViewportBounds? build() => null;

  void updateBounds(TerritoryViewportBounds? newBounds) {
    state = newBounds;
  }
}

final territoryViewportBoundsProvider =
    NotifierProvider<TerritoryViewportBoundsNotifier, TerritoryViewportBounds?>(
      TerritoryViewportBoundsNotifier.new,
    );

// Use ref.watch() so the provider rebuilds when baseUrlProvider, devLog or viewport bounds changes.
final allTerritoriesProvider = FutureProvider<List<UserTerritory>>((ref) async {
  final bounds = ref.watch(territoryViewportBoundsProvider);
  final controller = ref.watch(territoryControllerProvider);
  if (bounds == null) {
    return controller.fetchAllTerritories();
  }
  return controller.fetchWithBounds(bounds);
});
