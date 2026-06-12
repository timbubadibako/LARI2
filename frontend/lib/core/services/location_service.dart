import 'package:geolocator/geolocator.dart';
import '../domain/models/position_sample.dart';
import '../domain/repositories/tracking_source.dart';

class LocationService implements TrackingSource {
  @override
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  @override
  Stream<PositionSample> watchPosition() async* {
    Position? lastPosition;
    
    await for (final position in Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // minimum 5 meters movement
      ),
    )) {
      // Ignore if accuracy is worse than 40m
      if (position.accuracy > 40.0) continue;
      
      // Ignore duplicate points exactly at same coordinate
      if (lastPosition != null && 
          lastPosition.latitude == position.latitude && 
          lastPosition.longitude == position.longitude) {
        continue;
      }
      
      lastPosition = position;
      
      final sample = PositionSample(
        ts: position.timestamp,
        lat: position.latitude,
        lng: position.longitude,
        accuracyMeters: position.accuracy,
        altitudeMeters: position.altitude,
        speedMps: position.speed,
        bearingDeg: position.heading,
      );
      
      // Debug Output
      print('[GPS Stream] Lat: ${sample.lat}, Lng: ${sample.lng}, Accuracy: ${sample.accuracyMeters}m, Speed: ${sample.speedMps}m/s');
      
      yield sample;
    }
  }
}
