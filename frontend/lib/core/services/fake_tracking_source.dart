import 'dart:async';
import 'dart:math';
import '../domain/models/position_sample.dart';
import '../domain/repositories/tracking_source.dart';

class FakeTrackingSource implements TrackingSource {
  // Kuningan Coordinate
  double _lat = -6.225014;
  double _lng = 106.827143;
  final Random _rnd = Random();

  @override
  Future<bool> requestPermission() async => true;

  @override
  Stream<PositionSample> watchPosition() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      // move roughly ~5 meters
      _lat += (_rnd.nextDouble() - 0.2) * 0.0001;
      _lng += (_rnd.nextDouble() - 0.2) * 0.0001;
      
      yield PositionSample(
        ts: DateTime.now(),
        lat: _lat,
        lng: _lng,
        accuracyMeters: 5.0,
      );
    }
  }
}
