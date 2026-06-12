class PositionSample {
  final DateTime ts;
  final double lat;
  final double lng;
  final double accuracyMeters;
  final double? altitudeMeters;
  final double? speedMps;
  final double? bearingDeg;
  final bool isEstimated;

  PositionSample({
    required this.ts,
    required this.lat,
    required this.lng,
    required this.accuracyMeters,
    this.altitudeMeters,
    this.speedMps,
    this.bearingDeg,
    this.isEstimated = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'ts': ts.toIso8601String(),
      'lat': lat,
      'lng': lng,
      'accuracyMeters': accuracyMeters,
      'altitudeMeters': altitudeMeters,
      'speedMps': speedMps,
      'bearingDeg': bearingDeg,
      'isEstimated': isEstimated,
    };
  }

  factory PositionSample.fromJson(Map<String, dynamic> json) {
    return PositionSample(
      ts: DateTime.parse(json['ts'] as String),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
      altitudeMeters: json['altitudeMeters'] != null
          ? (json['altitudeMeters'] as num).toDouble()
          : null,
      speedMps: json['speedMps'] != null
          ? (json['speedMps'] as num).toDouble()
          : null,
      bearingDeg: json['bearingDeg'] != null
          ? (json['bearingDeg'] as num).toDouble()
          : null,
      isEstimated: json['isEstimated'] as bool? ?? false,
    );
  }
}
