import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionNotifier extends Notifier<bool?> {
  @override
  bool? build() {
    _checkPermission();
    return null; // null means checking
  }

  Future<void> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = false;
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      state = false;
    } else {
      state = true;
    }
  }

  Future<void> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Suggest user to turn on GPS
      await Geolocator.openLocationSettings();
    }
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (permission == LocationPermission.deniedForever) {
         await Geolocator.openAppSettings();
      }
      state = false;
    } else {
      state = true;
    }
  }
}

final locationPermissionProvider = NotifierProvider<LocationPermissionNotifier, bool?>(LocationPermissionNotifier.new);
