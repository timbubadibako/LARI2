import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'location_permission_provider.dart';

final userInitialPositionProvider = FutureProvider<Position?>((ref) async {
  // 1. Wait for permission state to be determined
  final permissionStatus = ref.watch(locationPermissionProvider);
  
  if (permissionStatus == null) {
    // Still checking permissions
    return null;
  }
  
  if (permissionStatus == false) {
    // Permission denied or Service disabled
    return null;
  }

  try {
    // 2. Try to get the last known position first (fast)
    Position? position = await Geolocator.getLastKnownPosition();
    
    // 3. If no last known, get current position (slower)
    position ??= await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );
    
    return position;
  } catch (e) {
    return null;
  }
});
