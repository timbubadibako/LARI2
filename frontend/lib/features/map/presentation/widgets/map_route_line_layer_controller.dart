import 'dart:math' as math;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../../../core/domain/models/position_sample.dart';

class MapRouteLineLayerController {
  static const double loopCloseToleranceMeters = 5.0;
  static const double minLoopDisplacementMeters = 50.0;
  static const int routeGapSplitSeconds = 12;
  static const double masteredTerritoryFillOpacity = 0.24;
  static const double previewTerritoryFillOpacity = 0.20;
  static const double territoryOutlineOpacity = 0.42;
  static const double territoryHatchOpacity = 0.20;
  static const String routeSourceId = 'route-source';
  static const String territorySourceId = 'territory-source';
  static const String masteredTerritorySourceId = 'mastered-territory-source';
  static const String masteredTerritoryHatchSourceId =
      'mastered-territory-hatch-source';
  static const String routeGlowLayerId = 'route-glow-layer';
  static const String routeCoreLayerId = 'route-core-layer';
  static const String territoryFillLayerId = 'territory-fill-layer';
  static const String territoryOutlineLayerId = 'territory-outline-layer';
  static const String masteredTerritoryLayerId = 'mastered-territory-layer';
  static const String masteredTerritoryHatchLayerId =
      'mastered-territory-hatch-layer';
  static const String currentPosSourceId = 'current-pos-source';
  static const String currentPosGlowLayerId = 'current-pos-glow-layer';
  static const String currentPosLayerId = 'current-pos-layer';
  static const String presenceSourceId = 'presence-source';
  static const String presenceLayerId = 'presence-layer';
  static const String historySourceId = 'history-source';
  static const String historyLayerId = 'history-layer';
  static const String contestedSourceId = 'contested-source';
  static const String contestedFillLayerId = 'contested-fill-layer';
  static const String contestedOutlineLayerId = 'contested-outline-layer';

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
      GeojsonSourceProperties(
        data: {'type': 'FeatureCollection', 'features': []},
      ),
    );

    await _mapController!.addSource(
      masteredTerritoryHatchSourceId,
      GeojsonSourceProperties(
        data: {'type': 'FeatureCollection', 'features': []},
      ),
    );

    await _mapController!.addFillLayer(
      masteredTerritorySourceId,
      masteredTerritoryLayerId,
      FillLayerProperties(
        fillColor: ['get', 'color'],
        fillOpacity: masteredTerritoryFillOpacity,
        fillOutlineColor: ['get', 'color'],
      ),
    );

    await _mapController!.addLineLayer(
      masteredTerritoryHatchSourceId,
      masteredTerritoryHatchLayerId,
      LineLayerProperties(
        lineColor: ['get', 'color'],
        lineWidth: 1.1,
        lineOpacity: territoryHatchOpacity,
        lineJoin: 'round',
        lineCap: 'round',
      ),
    );

    await _mapController!.addFillLayer(
      territorySourceId,
      territoryFillLayerId,
      FillLayerProperties(
        fillColor: '#CCFF00',
        fillOpacity: previewTerritoryFillOpacity,
        fillOutlineColor: '#CCFF00',
      ),
    );

    await _mapController!.addLineLayer(
      territorySourceId,
      territoryOutlineLayerId,
      LineLayerProperties(
        lineColor: '#CCFF00',
        lineWidth: 1.4,
        lineOpacity: territoryOutlineOpacity,
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
        lineColor: '#CCFF00',
        lineWidth: 10.0,
        lineOpacity: 0.3,
        lineJoin: 'round',
        lineCap: 'round',
      ),
    );

    await _mapController!.addLineLayer(
      routeSourceId,
      routeCoreLayerId,
      LineLayerProperties(
        lineColor: '#CCFF00',
        lineWidth: 5.0,
        lineOpacity: 1.0, // Solid
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
        lineColor: [
          'coalesce',
          ['get', 'color'],
          '#FFA500',
        ],
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

    await _mapController!.addSource(
      contestedSourceId,
      GeojsonSourceProperties(data: _emptyTerritoryGeoJson()),
    );

    await _mapController!.addFillLayer(
      contestedSourceId,
      contestedFillLayerId,
      FillLayerProperties(
        fillColor: [
          'coalesce',
          ['get', 'color'],
          '#FFD60A',
        ],
        fillOpacity: 0.18,
        fillOutlineColor: [
          'coalesce',
          ['get', 'color'],
          '#FFD60A',
        ],
      ),
    );

    await _mapController!.addLineLayer(
      contestedSourceId,
      contestedOutlineLayerId,
      LineLayerProperties(
        lineColor: [
          'coalesce',
          ['get', 'color'],
          '#FFD60A',
        ],
        lineWidth: 2.5,
        lineOpacity: 0.75,
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

  Future<void> updateRouteSamples(List<PositionSample> route) async {
    if (_mapController == null) return;
    final now = DateTime.now();
    if (now.difference(_lastRouteUpdate) < throttleDuration) return;
    _lastRouteUpdate = now;

    final geoJson = _buildRouteSamplesGeoJson(route);
    await _mapController!.setGeoJsonSource(routeSourceId, geoJson);
  }

  Future<void> updateRouteColor(String color) async {
    if (_mapController == null) return;

    await _mapController!.setLayerProperties(
      routeGlowLayerId,
      LineLayerProperties(lineColor: color),
    );
    await _mapController!.setLayerProperties(
      routeCoreLayerId,
      LineLayerProperties(lineColor: color),
    );
    await _mapController!.setLayerProperties(
      territoryFillLayerId,
      FillLayerProperties(
        fillColor: color,
        fillOpacity: previewTerritoryFillOpacity,
        fillOutlineColor: color,
      ),
    );
    await _mapController!.setLayerProperties(
      territoryOutlineLayerId,
      LineLayerProperties(
        lineColor: color,
        lineOpacity: territoryOutlineOpacity,
        lineWidth: 1.4,
      ),
    );
    // Also update current position color to match
    await _mapController!.setLayerProperties(
      currentPosGlowLayerId,
      CircleLayerProperties(circleColor: color),
    );
    await _mapController!.setLayerProperties(
      currentPosLayerId,
      CircleLayerProperties(circleColor: color),
    );
  }

  Future<void> updateTerritoryPolygon(
    List<latlong.LatLng> route, {
    double closeToleranceMeters = loopCloseToleranceMeters,
  }) async {
    if (_mapController == null) return;

    final territoryLoop = _extractLatestClosedLoop(route, closeToleranceMeters);
    final geoJson = territoryLoop != null
        ? _buildTerritoryGeoJson(territoryLoop)
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

  Future<void> updatePresenceLines(
    List<({List<latlong.LatLng> route, String color})> lines,
  ) async {
    if (_mapController == null) return;
    final geoJson = _buildPresenceGeoJson(lines);
    await _mapController!.setGeoJsonSource(presenceSourceId, geoJson);
  }

  Future<void> updateHistoryLines(List<List<latlong.LatLng>> lines) async {
    if (_mapController == null) return;
    final geoJson = _buildHistoryGeoJson(lines);
    await _mapController!.setGeoJsonSource(historySourceId, geoJson);
  }

  Future<void> updateMasteredTerritories(
    List<({Map<String, dynamic> geoJson, String color})> territories,
  ) async {
    if (_mapController == null) return;

    final fillGeoJson = {
      'type': 'FeatureCollection',
      'features': territories.map((t) {
        return {
          'type': 'Feature',
          'properties': {'color': t.color},
          'geometry': t.geoJson,
        };
      }).toList(),
    };

    final hatchGeoJson = {
      'type': 'FeatureCollection',
      'features': territories
          .expand((t) => _buildTerritoryHatchFeatures(t.geoJson, t.color))
          .toList(),
    };

    await _mapController!.setGeoJsonSource(
      masteredTerritorySourceId,
      fillGeoJson,
    );
    await _mapController!.setGeoJsonSource(
      masteredTerritoryHatchSourceId,
      hatchGeoJson,
    );
  }

  Future<void> updateContestedZones(
    List<
      ({
        latlong.LatLng center,
        double radiusMeters,
        String color,
        int runnerCount,
        String severity,
      })
    >
    zones,
  ) async {
    if (_mapController == null) return;

    if (zones.isEmpty) {
      await _mapController!.setGeoJsonSource(
        contestedSourceId,
        _emptyTerritoryGeoJson(),
      );
      return;
    }

    final geoJson = {
      'type': 'FeatureCollection',
      'features': zones.map((zone) {
        return {
          'type': 'Feature',
          'properties': {
            'color': zone.color,
            'runner_count': zone.runnerCount,
            'severity': zone.severity,
          },
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              _buildCircleRing(
                zone.center,
                zone.radiusMeters,
              ).map((point) => [point.longitude, point.latitude]).toList(),
            ],
          },
        };
      }).toList(),
    };

    await _mapController!.setGeoJsonSource(contestedSourceId, geoJson);
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

  Map<String, dynamic> _buildRouteSamplesGeoJson(List<PositionSample> route) {
    if (route.isEmpty) {
      return _emptyRouteGeoJson();
    }

    final segments = <List<List<double>>>[];
    var currentSegment = <List<double>>[];

    for (int i = 0; i < route.length; i++) {
      final point = route[i];
      if (i > 0) {
        final previous = route[i - 1];
        final elapsed = point.ts.difference(previous.ts).inSeconds;
        if (elapsed >= routeGapSplitSeconds && currentSegment.length >= 2) {
          segments.add(currentSegment);
          currentSegment = <List<double>>[];
        }
      }

      currentSegment.add([point.lng, point.lat]);
    }

    if (currentSegment.length >= 2) {
      segments.add(currentSegment);
    } else if (segments.isEmpty && currentSegment.isNotEmpty) {
      segments.add(currentSegment);
    }

    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': segments.length <= 1 ? 'LineString' : 'MultiLineString',
            'coordinates': segments.length <= 1
                ? (segments.isEmpty ? <List<double>>[] : segments.first)
                : segments,
          },
        },
      ],
    };
  }

  List<latlong.LatLng>? _extractLatestClosedLoop(
    List<latlong.LatLng> route,
    double closeToleranceMeters,
  ) {
    if (route.length < 3) return null;
    final last = route.last;

    for (int i = route.length - 3; i >= 0; i--) {
      final anchor = route[i];
      final gapMeters = Geolocator.distanceBetween(
        anchor.latitude,
        anchor.longitude,
        last.latitude,
        last.longitude,
      );
      if (gapMeters > closeToleranceMeters) {
        continue;
      }

      double maxDisplacement = 0.0;
      for (int j = i + 1; j < route.length; j++) {
        final displacement = Geolocator.distanceBetween(
          anchor.latitude,
          anchor.longitude,
          route[j].latitude,
          route[j].longitude,
        );
        if (displacement > maxDisplacement) {
          maxDisplacement = displacement;
        }
      }

      if (maxDisplacement > minLoopDisplacementMeters) {
        final loop = route.sublist(i).toList();
        final first = loop.first;
        final loopLast = loop.last;
        if (first.latitude != loopLast.latitude ||
            first.longitude != loopLast.longitude) {
          loop.add(first);
        }
        return loop;
      }
    }

    return null;
  }

  Map<String, dynamic> _buildTerritoryGeoJson(List<latlong.LatLng> route) {
    // ARCHITECTURAL FIX:
    // To avoid "holes" caused by self-intersections (even-odd rule),
    // we should ideally compute a Convex Hull or Alpha Shape.
    // For now, we ensure the ring is closed and use a simple polygon.
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
          'properties': {
            'kind': 'territory',
            'fill-rule': 'nonzero', // Attempt to override even-odd if supported
          },
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

  Map<String, dynamic> _buildPresenceGeoJson(
    List<({List<latlong.LatLng> route, String color})> lines,
  ) {
    if (lines.isEmpty) return _emptyRouteGeoJson();

    return {
      'type': 'FeatureCollection',
      'features': lines.map((line) {
        // Very simple downsampling to improve performance if many lines
        final step = line.route.length > 50 ? 5 : 1;
        final simplified = <latlong.LatLng>[];
        for (int i = 0; i < line.route.length; i += step) {
          simplified.add(line.route[i]);
        }
        if (simplified.isNotEmpty && simplified.last != line.route.last) {
          simplified.add(line.route.last);
        }

        return {
          'type': 'Feature',
          'properties': {'color': line.color},
          'geometry': {
            'type': 'LineString',
            'coordinates': simplified
                .map((p) => [p.longitude, p.latitude])
                .toList(),
          },
        };
      }).toList(),
    };
  }

  Map<String, dynamic> _buildHistoryGeoJson(List<List<latlong.LatLng>> lines) {
    if (lines.isEmpty) return _emptyRouteGeoJson();

    return {
      'type': 'FeatureCollection',
      'features': lines.map((line) {
        final step = line.length > 50 ? 5 : 1;
        final simplified = <latlong.LatLng>[];
        for (int i = 0; i < line.length; i += step) {
          simplified.add(line[i]);
        }
        if (simplified.isNotEmpty && simplified.last != line.last) {
          simplified.add(line.last);
        }

        return {
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': 'LineString',
            'coordinates': simplified
                .map((p) => [p.longitude, p.latitude])
                .toList(),
          },
        };
      }).toList(),
    };
  }

  List<latlong.LatLng> _buildCircleRing(
    latlong.LatLng center,
    double radiusMeters,
  ) {
    const segments = 28;
    final ring = <latlong.LatLng>[];
    final latRadians = center.latitude * math.pi / 180.0;
    final metersPerLat = 111320.0;
    final metersPerLng = 111320.0 * math.cos(latRadians);

    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      final dx = math.cos(angle) * radiusMeters;
      final dy = math.sin(angle) * radiusMeters;
      final lat = center.latitude + (dy / metersPerLat);
      final lng =
          center.longitude + (metersPerLng == 0 ? 0 : dx / metersPerLng);
      ring.add(latlong.LatLng(lat, lng));
    }

    return ring;
  }

  List<Map<String, dynamic>> _buildTerritoryHatchFeatures(
    Map<String, dynamic> geometry,
    String color,
  ) {
    final type = geometry['type'];
    final rawCoordinates = geometry['coordinates'];
    if (rawCoordinates is! List) {
      return const [];
    }

    final features = <Map<String, dynamic>>[];
    if (type == 'Polygon') {
      features.addAll(_buildPolygonHatchFeatures(rawCoordinates, color));
    } else if (type == 'MultiPolygon') {
      for (final polygon in rawCoordinates) {
        if (polygon is List) {
          features.addAll(_buildPolygonHatchFeatures(polygon, color));
        }
      }
    }
    return features;
  }

  List<Map<String, dynamic>> _buildPolygonHatchFeatures(
    List<dynamic> polygonCoordinates,
    String color,
  ) {
    if (polygonCoordinates.isEmpty) {
      return const [];
    }

    final outerRing = _toRing(polygonCoordinates.first);
    if (outerRing.length < 3) {
      return const [];
    }

    final holes = polygonCoordinates.skip(1).map(_toRing).toList();
    final bbox = _computeRingBounds(outerRing);
    final width = bbox.$3 - bbox.$1;
    final height = bbox.$4 - bbox.$2;
    if (width <= 0 || height <= 0) {
      return const [];
    }

    final spacing = math.max(width, height) / 9;
    final padding = spacing * 1.5;
    final segments = <Map<String, dynamic>>[];
    final minOffset = -height - padding;
    final maxOffset = width + padding;

    for (double offset = minOffset; offset <= maxOffset; offset += spacing) {
      final start = <double>[bbox.$1 + offset, bbox.$2 - padding];
      final end = <double>[
        bbox.$1 + offset + height + padding * 2,
        bbox.$4 + padding,
      ];
      final clipped = _clipSegmentToPolygon(start, end, outerRing, holes);
      if (clipped.length < 2) {
        continue;
      }

      segments.add({
        'type': 'Feature',
        'properties': {'color': color},
        'geometry': {'type': 'LineString', 'coordinates': clipped},
      });
    }

    return segments;
  }

  List<List<double>> _clipSegmentToPolygon(
    List<double> start,
    List<double> end,
    List<List<double>> outerRing,
    List<List<List<double>>> holes,
  ) {
    const samples = 28;
    final insidePoints = <List<double>>[];
    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final point = <double>[
        start[0] + (end[0] - start[0]) * t,
        start[1] + (end[1] - start[1]) * t,
      ];
      if (_pointInPolygon(point, outerRing, holes)) {
        insidePoints.add(point);
      }
    }

    if (insidePoints.length < 2) {
      return const [];
    }

    return insidePoints;
  }

  bool _pointInPolygon(
    List<double> point,
    List<List<double>> outerRing,
    List<List<List<double>>> holes,
  ) {
    if (!_pointInRing(point, outerRing)) {
      return false;
    }
    for (final hole in holes) {
      if (_pointInRing(point, hole)) {
        return false;
      }
    }
    return true;
  }

  bool _pointInRing(List<double> point, List<List<double>> ring) {
    var inside = false;
    for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i][0];
      final yi = ring[i][1];
      final xj = ring[j][0];
      final yj = ring[j][1];
      final intersects =
          ((yi > point[1]) != (yj > point[1])) &&
          (point[0] <
              (xj - xi) *
                      (point[1] - yi) /
                      ((yj - yi) == 0 ? 0.0000001 : (yj - yi)) +
                  xi);
      if (intersects) {
        inside = !inside;
      }
    }
    return inside;
  }

  List<List<double>> _toRing(dynamic rawRing) {
    if (rawRing is! List) {
      return const [];
    }
    return rawRing
        .whereType<List>()
        .map(
          (point) => [
            (point[0] as num).toDouble(),
            (point[1] as num).toDouble(),
          ],
        )
        .toList();
  }

  (double, double, double, double) _computeRingBounds(List<List<double>> ring) {
    var minLng = ring.first[0];
    var minLat = ring.first[1];
    var maxLng = ring.first[0];
    var maxLat = ring.first[1];

    for (final point in ring.skip(1)) {
      minLng = math.min(minLng, point[0]);
      minLat = math.min(minLat, point[1]);
      maxLng = math.max(maxLng, point[0]);
      maxLat = math.max(maxLat, point[1]);
    }

    return (minLng, minLat, maxLng, maxLat);
  }
}
