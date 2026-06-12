import '../models/position_sample.dart';

abstract class TrackingSource {
  Future<bool> requestPermission();
  Stream<PositionSample> watchPosition();
}
