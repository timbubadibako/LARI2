import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'current_location_provider.dart';
import '../../../dev/dev_providers.dart';

/// A provider that returns a human-readable address for the user's current location.
final currentAddressProvider = FutureProvider<String>((ref) async {
  // 1. Get current position (initial or stream)
  final positionAsync = ref.watch(locationStreamProvider);
  
  return positionAsync.when(
    data: (position) async {
      try {
        // 2. Perform reverse geocoding with timeout
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.lat,
          position.lng,
        ).timeout(const Duration(seconds: 5));

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          // Format as "CITY, REGION"
          final city = p.locality ?? p.subAdministrativeArea ?? 'UNKNOWN_SECTOR';
          final region = p.administrativeArea ?? 'UNKNOWN_REGION';
          return '${city.toUpperCase()}, ${region.toUpperCase()}';
        }
        return 'RECONNAISSANCE_FAIL';
      } catch (e) {
        return 'OFFLINE_GRID';
      }
    },
    loading: () => 'SYNCING_GRID...',
    error: (e, s) => 'GRID_ERROR',
  );
});
