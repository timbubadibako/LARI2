import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class MapRouteLineLayerController {
  static const String routeSourceId = 'route-source';
  static const String territorySourceId = 'territory-source';
  static const String masteredTerritorySourceId = 'mastered-territory-source';
  static const String routeGlowLayerId = 'route-glow-layer';
  static const String routeCoreLayerId = 'route-core-layer';
  static const String territoryFillLayerId = 'territory-fill-layer';
  static const String territoryOutlineLayerId = 'territory-outline-layer';
  static const String masteredTerritoryLayerId = 'mastered-territory-layer';
  static const String currentPosSourceId = 'current-pos-source';
  static const String currentPosGlowLayerId = 'current-pos-glow-layer';
  static const String currentPosLayerId = 'current-pos-layer';
  static const String presenceSourceId = 'presence-source';
  static const String presenceLayerId = 'presence-layer';
  static const String historySourceId = 'history-source';
  static const String historyLayerId = 'history-layer';


  final Duration throttleDuration = const Duration(milliseconds: 800);
  DateTime _lastRouteUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastPositionUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  bool _initialized = false;

  MapLibreMapController? _mapController;

  void setMapController(MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> initialize() async {
    if (_initialized || _mapController == null) return;
    _initialized = true;

    await _mapController!.addSource(
      territorySourceId,
      GeojsonSourceProperties(data: _emptyTerritoryGeoJson()),
    );

    await _mapController!.addSource(
      masteredTerritorySourceId,
      GeojsonSourceProperties(data: {
        'type': 'FeatureCollection',
        'features': [],
      }),
    );

    await _mapController!.addFillLayer(
      masteredTerritorySourceId,
      masteredTerritoryLayerId,
      FillLayerProperties(
        fillColor: ['get', 'color'],
        fillOpacity: 0.25,
        fillOutlineColor: ['get', 'color'],
      ),
    );

    await _mapController!.addFillLayer(
      territorySourceId,
      territoryFillLayerId,
      FillLayerProperties(
        fillColor: '#00F5FF',
        fillOpacity: 0.20,
        fillOutlineColor: '#00F5FF',
      ),
    );

    await _mapController!.addLineLayer(
      territorySourceId,
      territoryOutlineLayerId,
      LineLayerProperties(
        lineColor: '#00F5FF',
        lineWidth: 1.0,
        lineOpacity: 0.18,
        lineJoin: 'round',
        lineCap: 'round',
      ),
    );

    await _mapController!.addSource(
      routeSourceId,
      GeojsonSourceProperties(data: _emptyRouteGeoJson()),
    );

    await _mapController!.addLineLayer(
      routeSourceId,
      routeGlowLayerId,
      LineLayerProperties(
        lineColor: '#00F5FF',
        lineWidth: 9.0,
        lineOpacity: 0.25,
        lineJoin: 'round',
        lineCap: 'round',
      ),
    );

    await _mapController!.addLineLayer(
      routeSourceId,
      routeCoreLayerId,
      LineLayerProperties(
        lineColor: '#00F5FF',
        lineWidth: 5.0,
        lineOpacity: 0.95,
        lineJoin: 'round',
        lineCap: 'round',
      ),
    );

    await _mapController!.addSource(
      currentPosSourceId,
      GeojsonSourceProperties(data: _emptyPointGeoJson()),
    );

    await _mapController!.addCircleLayer(
      currentPosSourceId,
      currentPosGlowLayerId,
      CircleLayerProperties(
        circleColor: '#00F5FF',
        circleRadius: 14.0,
        circleOpacity: 0.16,
      ),
    );

    await _mapController!.addCircleLayer(
      currentPosSourceId,
      currentPosLayerId,
      CircleLayerProperties(
        circleColor: '#00F5FF',
        circleRadius: 8.0,
        circleOpacity: 0.95,
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2.0,
      ),
    );

    await _mapController!.addSource(
      presenceSourceId,
      GeojsonSourceProperties(data: _emptyRouteGeoJson()),
    );

    await _mapController!.addLineLayer(
      presenceSourceId,
      presenceLayerId,
      LineLayerProperties(
        lineColor: '#FFA500', 
        lineWidth: 3.0,
        lineOpacity: 0.4,
        lineDasharray: [2.0, 2.0],
        lineJoin: 'round',
        lineCap: 'round',
      ),
    );

    await _mapController!.addSource(
      historySourceId,
      GeojsonSourceProperties(data: _emptyRouteGeoJson()),
    );

    await _mapController!.addLineLayer(
      historySourceId,
      historyLayerId,
      LineLayerProperties(
        lineColor: '#FFFFFF',
        lineWidth: 2.0,
        lineOpacity: 0.12,
        lineJoin: 'round',
        lineCap: 'round',
      ),
    );
  }


  Future<void> updateRoute(List<latlong.LatLng> route) async {
    if (_mapController == null) return;
    final now = DateTime.now();
    if (now.difference(_lastRouteUpdate) < throttleDuration) return;
    _lastRouteUpdate = now;

    final geoJson = _buildRouteGeoJson(route);
    await _mapController!.setGeoJsonSource(routeSourceId, geoJson);
  }

  Future<void> updateTerritoryPolygon(
    List<latlong.LatLng> route, {
    double closeToleranceMeters = 25.0,
  }) async {
    if (_mapController == null) return;

    final geoJson = _isTerritoryClosed(route, closeToleranceMeters)
        ? _buildTerritoryGeoJson(route)
        : _emptyTerritoryGeoJson();
    await _mapController!.setGeoJsonSource(territorySourceId, geoJson);
  }

  Future<void> updateCurrentPosition(latlong.LatLng position) async {
    if (_mapController == null) return;
    final now = DateTime.now();
    if (now.difference(_lastPositionUpdate) < throttleDuration) return;
    _lastPositionUpdate = now;

    final geoJson = _buildPointGeoJson(position);
    await _mapController!.setGeoJsonSource(currentPosSourceId, geoJson);
  }

  Future<void> updateRunnerMarker(
    latlong.LatLng position, {
    double? bearingDeg,
  }) async {
    if (_mapController == null) return;
    final now = DateTime.now();
    if (now.difference(_lastPositionUpdate) < throttleDuration) return;
    _lastPositionUpdate = now;

    final geoJson = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {'bearing': bearingDeg ?? 0.0, 'kind': 'runner'},
          'geometry': {
            'type': 'Point',
            'coordinates': [position.longitude, position.latitude],
          },
        },
      ],
    };

    await _mapController!.setGeoJsonSource(currentPosSourceId, geoJson);
  }

  Future<void> updatePresenceLines(List<List<latlong.LatLng>> lines) async {
    if (_mapController == null) return;
    final geoJson = _buildPresenceGeoJson(lines);
    await _mapController!.setGeoJsonSource(presenceSourceId, geoJson);
  }

  Future<void> updateHistoryLines(List<List<latlong.LatLng>> lines) async {
    if (_mapController == null) return;
    final geoJson = _buildPresenceGeoJson(lines);
    await _mapController!.setGeoJsonSource(historySourceId, geoJson);
  }

  Future<void> updateMasteredTerritories(List<({Map<String, dynamic> geoJson, String color})> territories) async {
    if (_mapController == null) return;

    final geoJson = {
      'type': 'FeatureCollection',
      'features': territories.map((t) {
        return {
          'type': 'Feature',
          'properties': {'color': t.color},
          'geometry': t.geoJson,
        };
      }).toList(),
    };

    await _mapController!.setGeoJsonSource(masteredTerritorySourceId, geoJson);
  }


  Map<String, dynamic> _emptyRouteGeoJson() {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {},
          'geometry': {'type': 'LineString', 'coordinates': <List<double>>[]},
        },
      ],
    };
  }

  Map<String, dynamic> _buildRouteGeoJson(List<latlong.LatLng> route) {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': 'LineString',
            'coordinates': route
                .map((point) => [point.longitude, point.latitude])
                .toList(),
          },
        },
      ],
    };
  }

  bool _isTerritoryClosed(
    List<latlong.LatLng> route,
    double closeToleranceMeters,
  ) {
    if (route.length < 3) return false;

    final first = route.first;
    final last = route.last;
    final gapMeters = Geolocator.distanceBetween(
      first.latitude,
      first.longitude,
      last.latitude,
      last.longitude,
    );

    return gapMeters <= closeToleranceMeters;
  }

  Map<String, dynamic> _buildTerritoryGeoJson(List<latlong.LatLng> route) {
    final ring = route
        .map((point) => [point.longitude, point.latitude])
        .toList();

    if (ring.isNotEmpty) {
      final first = ring.first;
      final last = ring.last;
      if (first[0] != last[0] || first[1] != last[1]) {
        ring.add([first[0], first[1]]);
      }
    }

    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {'kind': 'territory'},
          'geometry': {
            'type': 'Polygon',
            'coordinates': [ring],
          },
        },
      ],
    };
  }

  Map<String, dynamic> _emptyTerritoryGeoJson() {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {},
          'geometry': {'type': 'Polygon', 'coordinates': []},
        },
      ],
    };
  }

  Map<String, dynamic> _emptyPointGeoJson() {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': 'Point',
            'coordinates': <double>[0.0, 0.0],
          },
        },
      ],
    };
  }

  Map<String, dynamic> _buildPointGeoJson(latlong.LatLng point) {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': 'Point',
            'coordinates': [point.longitude, point.latitude],
          },
        },
      ],
    };
  }

  Map<String, dynamic> _buildPresenceGeoJson(List<List<latlong.LatLng>> lines) {
    if (lines.isEmpty) return _emptyRouteGeoJson();

    return {
      'type': 'FeatureCollection',
      'features': lines.map((line) {
        // Very simple downsampling to improve performance if many lines
        final step = line.length > 50 ? 5 : 1;
        final simplified = <latlong.LatLng>[];
        for (int i = 0; i < line.length; i += step) {
          simplified.add(line[i]);
        }
        if (simplified.isNotEmpty && simplified.last != line.last) simplified.add(line.last);

        return {
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': 'LineString',
            'coordinates': simplified
                .map((p) => [p.longitude, p.latitude])
                .toList()
          }
        };
      }).toList(),
    };
  }
}
