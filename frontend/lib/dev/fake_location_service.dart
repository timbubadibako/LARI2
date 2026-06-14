import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/domain/models/position_sample.dart';
import '../core/domain/repositories/tracking_source.dart';

enum FakeScenario {
  circular,    // Traditional circle around current location
  lasso        // A to B (linear), then B-C-B (loop), leaves A-B open
}

class FakeLocationConfig {
  final double centerLat;
  final double centerLng;
  final double loopDistanceMeters;
  final int durationSeconds;
  final Duration sampleInterval;
  final double accuracyMeanMeters;
  final double accuracyStdMeters;
  final bool includeJitter;
  final bool loopForever;
  final double? startAngleDeg;
  final bool variablePace;
  final bool simulateDropouts;
  final double dropoutProbability;
  final bool paused;
  final FakeScenario scenario;
  
  // Debug Display Toggles
  final bool showRawPoints;
  final bool showDisplayPoints;
  final bool showSampleRate;
  final bool showLastAccuracy;
  final bool showCumulativeDistance;

  const FakeLocationConfig({
    required this.centerLat,
    required this.centerLng,
    required this.loopDistanceMeters,
    required this.durationSeconds,
    required this.sampleInterval,
    required this.accuracyMeanMeters,
    required this.accuracyStdMeters,
    required this.includeJitter,
    required this.loopForever,
    required this.startAngleDeg,
    required this.variablePace,
    required this.simulateDropouts,
    required this.dropoutProbability,
    required this.paused,
    this.scenario = FakeScenario.circular,
    this.showRawPoints = false,
    this.showDisplayPoints = true,
    this.showSampleRate = false,
    this.showLastAccuracy = false,
    this.showCumulativeDistance = false,
  });

  const FakeLocationConfig.defaults()
    : centerLat = 0,
      centerLng = 0,
      loopDistanceMeters = 1000, 
      durationSeconds = 600,     
      sampleInterval = const Duration(seconds: 1),
      accuracyMeanMeters = 5,
      accuracyStdMeters = 1.5,
      includeJitter = true,
      loopForever = false,
      startAngleDeg = null,
      variablePace = true,
      simulateDropouts = false,
      dropoutProbability = 0.02,
      paused = false,
      scenario = FakeScenario.circular,
      showRawPoints = false,
      showDisplayPoints = true,
      showSampleRate = false,
      showLastAccuracy = false,
      showCumulativeDistance = false;

  FakeLocationConfig copyWith({
    double? centerLat,
    double? centerLng,
    double? loopDistanceMeters,
    int? durationSeconds,
    Duration? sampleInterval,
    double? accuracyMeanMeters,
    double? accuracyStdMeters,
    bool? includeJitter,
    bool? loopForever,
    double? startAngleDeg,
    bool? variablePace,
    bool? simulateDropouts,
    double? dropoutProbability,
    bool? paused,
    FakeScenario? scenario,
    bool? showRawPoints,
    bool? showDisplayPoints,
    bool? showSampleRate,
    bool? showLastAccuracy,
    bool? showCumulativeDistance,
  }) {
    return FakeLocationConfig(
      centerLat: centerLat ?? this.centerLat,
      centerLng: centerLng ?? this.centerLng,
      loopDistanceMeters: loopDistanceMeters ?? this.loopDistanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sampleInterval: sampleInterval ?? this.sampleInterval,
      accuracyMeanMeters: accuracyMeanMeters ?? this.accuracyMeanMeters,
      accuracyStdMeters: accuracyStdMeters ?? this.accuracyStdMeters,
      includeJitter: includeJitter ?? this.includeJitter,
      loopForever: loopForever ?? this.loopForever,
      startAngleDeg: startAngleDeg ?? this.startAngleDeg,
      variablePace: variablePace ?? this.variablePace,
      simulateDropouts: simulateDropouts ?? this.simulateDropouts,
      dropoutProbability: dropoutProbability ?? this.dropoutProbability,
      paused: paused ?? this.paused,
      scenario: scenario ?? this.scenario,
      showRawPoints: showRawPoints ?? this.showRawPoints,
      showDisplayPoints: showDisplayPoints ?? this.showDisplayPoints,
      showSampleRate: showSampleRate ?? this.showSampleRate,
      showLastAccuracy: showLastAccuracy ?? this.showLastAccuracy,
      showCumulativeDistance: showCumulativeDistance ?? this.showCumulativeDistance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'centerLat': centerLat,
      'centerLng': centerLng,
      'loopDistanceMeters': loopDistanceMeters,
      'durationSeconds': durationSeconds,
      'sampleIntervalSeconds': sampleInterval.inSeconds,
      'accuracyMeanMeters': accuracyMeanMeters,
      'accuracyStdMeters': accuracyStdMeters,
      'includeJitter': includeJitter,
      'loopForever': loopForever,
      'startAngleDeg': startAngleDeg,
      'variablePace': variablePace,
      'simulateDropouts': simulateDropouts,
      'dropoutProbability': dropoutProbability,
      'paused': paused,
      'scenario': scenario.name,
      'showRawPoints': showRawPoints,
      'showDisplayPoints': showDisplayPoints,
      'showSampleRate': showSampleRate,
      'showLastAccuracy': showLastAccuracy,
      'showCumulativeDistance': showCumulativeDistance,
    };
  }

  factory FakeLocationConfig.fromJson(Map<String, dynamic> json) {
    return FakeLocationConfig(
      centerLat: (json['centerLat'] as num?)?.toDouble() ?? -6.225014,
      centerLng: (json['centerLng'] as num?)?.toDouble() ?? 106.827143,
      loopDistanceMeters: (json['loopDistanceMeters'] as num?)?.toDouble() ?? 1000,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 600,
      sampleInterval: Duration(seconds: (json['sampleIntervalSeconds'] as num?)?.toInt() ?? 1),
      accuracyMeanMeters: (json['accuracyMeanMeters'] as num?)?.toDouble() ?? 5,
      accuracyStdMeters: (json['accuracyStdMeters'] as num?)?.toDouble() ?? 1.5,
      includeJitter: json['includeJitter'] as bool? ?? true,
      loopForever: json['loopForever'] as bool? ?? false,
      startAngleDeg: (json['startAngleDeg'] as num?)?.toDouble(),
      variablePace: json['variablePace'] as bool? ?? true,
      simulateDropouts: json['simulateDropouts'] as bool? ?? false,
      dropoutProbability: (json['dropoutProbability'] as num?)?.toDouble() ?? 0.02,
      paused: json['paused'] as bool? ?? false,
      scenario: FakeScenario.values.firstWhere((e) => e.name == json['scenario'], orElse: () => FakeScenario.circular),
      showRawPoints: json['showRawPoints'] as bool? ?? false,
      showDisplayPoints: json['showDisplayPoints'] as bool? ?? true,
      showSampleRate: json['showSampleRate'] as bool? ?? false,
      showLastAccuracy: json['showLastAccuracy'] as bool? ?? false,
      showCumulativeDistance: json['showCumulativeDistance'] as bool? ?? false,
    );
  }

  String get debugLabel => 'scenario=${scenario.name} center=($centerLat,$centerLng) dist=${loopDistanceMeters}m';
}

class FakeLocationService implements TrackingSource {
  static FakeLocationService? _instance;
  
  factory FakeLocationService({required FakeLocationConfig config, Random? random}) {
    _instance ??= FakeLocationService._internal(config: config, random: random);
    _instance!._config = config;
    return _instance!;
  }

  FakeLocationService._internal({required FakeLocationConfig config, Random? random})
    : _config = config,
      _random = random ?? Random();

  final Random _random;
  FakeLocationConfig _config;

  StreamController<PositionSample>? _controller;
  Timer? _timer;
  bool _isStarted = false;
  bool _isPaused = false;
  int _emittedSamples = 0;
  double _angleRad = 0;

  late double _targetLat;
  late double _targetLng;
  bool _reachedTarget = false;

  FakeLocationConfig get config => _config;
  set config(FakeLocationConfig value) => _config = value;

  @override
  Future<bool> requestPermission() async => true;

  Stream<PositionSample> start() {
    if (_isStarted && _controller != null) return _controller!.stream;

    _controller = StreamController<PositionSample>.broadcast(
      onCancel: () { if (_controller?.hasListener == false) stop(); },
    );
    _isStarted = true;
    _isPaused = _config.paused;
    _emittedSamples = 0;
    _angleRad = 0;
    _reachedTarget = false;

    if (_config.scenario == FakeScenario.lasso) {
      _targetLat = _config.centerLat + _metersToLat(200);
      _targetLng = _config.centerLng;
    }

    if (kDebugMode) debugPrint('FAKE_LOCATION_START ${_config.debugLabel}');

    _timer = Timer.periodic(_config.sampleInterval, (_) => _emitNextSample());
    return _controller!.stream;
  }

  @override
  Stream<PositionSample> watchPosition() => start();

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_controller != null && !_controller!.isClosed) _controller!.close();
    _controller = null;
    _isStarted = false;
  }

  void _emitNextSample() {
    if (_controller == null || _controller!.isClosed || _isPaused) return;

    try {
      PositionSample sample;
      switch (_config.scenario) {
        case FakeScenario.lasso:
          sample = _generateLassoSample();
          break;
        case FakeScenario.circular:
        default:
          sample = _generateCircularSample();
      }

      if (_controller != null && !_controller!.isClosed) {
        _controller!.add(sample);
        _emittedSamples++;
      }
    } catch (e, stack) {
      debugPrint('FAKE_LOCATION_EMIT_ERROR: $e\n$stack');
      // Don't stop the timer, maybe next one works, or we could stop it if critical
    }
  }

  PositionSample _generateCircularSample() {
    final baseSpeed = _config.loopDistanceMeters / _config.durationSeconds;
    final speedMps = max(0.4, baseSpeed);
    final intervalSeconds = _config.sampleInterval.inMilliseconds / 1000.0;
    final stepMeters = speedMps * intervalSeconds;
    final radiusMeters = max(1.0, _config.loopDistanceMeters / (2 * pi));
    
    _angleRad = (_angleRad + stepMeters / radiusMeters) % (2 * pi);

    final x = radiusMeters * cos(_angleRad);
    final y = radiusMeters * sin(_angleRad);

    return PositionSample(
      ts: DateTime.now(),
      lat: _config.centerLat + _metersToLat(y),
      lng: _config.centerLng + _metersToLng(x, _config.centerLat),
      accuracyMeters: _config.accuracyMeanMeters,
      speedMps: speedMps,
      bearingDeg: (_angleRad * 180 / pi + 90) % 360,
    );
  }

  PositionSample _generateLassoSample() {
    if (!_reachedTarget) {
      final currentLat = _config.centerLat + _metersToLat(_emittedSamples * 2);
      final distToTarget = Geolocator.distanceBetween(currentLat, _config.centerLng, _targetLat, _targetLng);
      
      if (distToTarget < 5) {
        _reachedTarget = true;
        _angleRad = pi;
      }

      return PositionSample(
        ts: DateTime.now(),
        lat: currentLat,
        lng: _config.centerLng,
        accuracyMeters: 5,
        speedMps: 2.0,
        bearingDeg: 0,
      );
    } 
    
    final radiusMeters = 50.0;
    final speedMps = 2.0;
    final stepRad = speedMps / radiusMeters;
    _angleRad += stepRad;

    final x = radiusMeters * cos(_angleRad);
    final y = radiusMeters * sin(_angleRad) + radiusMeters;

    return PositionSample(
      ts: DateTime.now(),
      lat: _targetLat + _metersToLat(y),
      lng: _targetLng + _metersToLng(x, _targetLat),
      accuracyMeters: 5,
      speedMps: speedMps,
      bearingDeg: (_angleRad * 180 / pi + 90) % 360,
    );
  }

  double _metersToLat(double meters) => meters / 111320.0;
  double _metersToLng(double meters, double lat) {
    final scale = 111320.0 * cos(lat * pi / 180.0);
    return scale == 0 ? 0 : meters / scale;
  }
}
