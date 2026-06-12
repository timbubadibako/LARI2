import 'dart:math' as math;
import 'package:h3_flutter/h3_flutter.dart';

class GeospatialService {
  late final H3 _h3;

  GeospatialService() {
    _h3 = const H3Factory().load();
  }

  /// Converts a GPS coordinate (latitude, longitude) to an H3 Index string.
  /// [resolution] defines the size of the hexagon.
  /// Default resolution is 9, which represents roughly a neighborhood block.
  String coordinateToH3Index(double latitude, double longitude, {int resolution = 9}) {
    final coord = GeoCoord(lat: latitude, lon: longitude);
    final h3Index = _h3.geoToCell(coord, resolution);
    return h3Index.toRadixString(16);
  }

  /// Gets the polygon boundaries (GeoCoord list) for a specific H3 Index string.
  List<GeoCoord> getH3Boundary(String h3IndexString) {
    final h3Index = BigInt.parse(h3IndexString, radix: 16);
    return _h3.cellToBoundary(h3Index);
  }

  /// Gets the center coordinate for a given H3 Index string.
  GeoCoord getH3Center(String h3IndexString) {
    final h3Index = BigInt.parse(h3IndexString, radix: 16);
    return _h3.cellToGeo(h3Index);
  }
  
  /// Gets the neighboring H3 indices for a given H3 Index within a specific distance (k-ring).
  List<String> getNeighbors(String h3IndexString, {int k = 1}) {
    final h3Index = BigInt.parse(h3IndexString, radix: 16);
    final neighbors = _h3.gridDisk(h3Index, k);
    return neighbors.map((index) => index.toRadixString(16)).toList();
  }

  /// Simplifies a path of points using the Ramer-Douglas-Peucker (RDP) algorithm.
  /// [epsilon] defines the tolerance in meters. Points closer than this to the simplified line are dropped.
  List<({double lat, double lng})> simplifyPath(List<({double lat, double lng})> points, {double epsilon = 5.0}) {
    if (points.length < 3) return points;

    double dmax = 0.0;
    int index = 0;
    final end = points.length - 1;

    for (int i = 1; i < end; i++) {
      final d = _perpendicularDistance(points[i], points[0], points[end]);
      if (d > dmax) {
        index = i;
        dmax = d;
      }
    }

    if (dmax > epsilon) {
      final recResults1 = simplifyPath(points.sublist(0, index + 1), epsilon: epsilon);
      final recResults2 = simplifyPath(points.sublist(index, end + 1), epsilon: epsilon);

      final result = <({double lat, double lng})>[];
      result.addAll(recResults1.sublist(0, recResults1.length - 1));
      result.addAll(recResults2);
      return result;
    } else {
      return [points[0], points[end]];
    }
  }

  /// Calculates the perpendicular distance (in roughly meters) from a point to a line segment.
  /// This is an approximation using the Haversine formula base for small distances.
  double _perpendicularDistance(({double lat, double lng}) pt, ({double lat, double lng}) lineStart, ({double lat, double lng}) lineEnd) {
    // Equirectangular approximation for small distances (treating lat/lng as Cartesian locally)
    // 1 deg lat ~ 111.32 km. 1 deg lng ~ 111.32 * cos(lat) km.
    final R = 6371000.0; // Earth radius in meters
    
    final x0 = pt.lng * math.pi / 180.0 * R * math.cos(lineStart.lat * math.pi / 180.0);
    final y0 = pt.lat * math.pi / 180.0 * R;

    final x1 = lineStart.lng * math.pi / 180.0 * R * math.cos(lineStart.lat * math.pi / 180.0);
    final y1 = lineStart.lat * math.pi / 180.0 * R;

    final x2 = lineEnd.lng * math.pi / 180.0 * R * math.cos(lineStart.lat * math.pi / 180.0);
    final y2 = lineEnd.lat * math.pi / 180.0 * R;

    final area = ((x2 - x1) * (y1 - y0) - (x1 - x0) * (y2 - y1)).abs();
    final bottom = math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));

    if (bottom == 0) {
      // lineStart and lineEnd are the same point
      return math.sqrt(math.pow(x0 - x1, 2) + math.pow(y0 - y1, 2));
    }

    return area / bottom;
  }

  /// Converts a list of coordinates to a PostGIS-compatible WKT LineString.
  String pointsToWktLineString(List<({double lat, double lng})> points) {
    if (points.isEmpty) return 'LINESTRING EMPTY';
    final coords = points.map((p) => '${p.lng} ${p.lat}').join(',');
    return 'LINESTRING($coords)';
  }

  /// Converts a list of coordinates to a PostGIS-compatible WKT Polygon.
  /// Ensures the polygon is closed (last point equals first point).
  String pointsToWktPolygon(List<({double lat, double lng})> points) {
    if (points.isEmpty) return 'POLYGON EMPTY';
    
    final closedPoints = List<({double lat, double lng})>.from(points);
    if (points.first.lat != points.last.lat || points.first.lng != points.last.lng) {
      closedPoints.add(points.first);
    }
    
    final coords = closedPoints.map((p) => '${p.lng} ${p.lat}').join(',');
    return 'POLYGON(($coords))';
  }
}
