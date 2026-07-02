import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../../../ui/theme/stride_colors.dart';
import '../../../../ui/theme/stride_typography.dart';
import '../../../../ui/components/v3_shapes.dart';
import '../../../../core/services/geospatial_service.dart';
import '../../../../dev/dev_providers.dart';
import '../../../profile/application/profile_controller.dart';
import '../../../workout/application/workout_controller.dart';
import '../../../social/application/presence_provider.dart';
import '../../application/territory_controller.dart';
import '../../application/current_location_provider.dart';
import '../../application/location_permission_provider.dart';
import '../../application/map_actions_provider.dart';
import '../../../history/application/history_controller.dart';
import '../../../../core/domain/models/run_history.dart';

import 'map_route_line_layer_controller.dart';

class StrideMapView extends ConsumerStatefulWidget {
  final CameraPosition? initialCameraPositionOverride;
  final List<latlong.LatLng>? staticPath;
  final bool isCaptured;
  final bool isPreviewMode;

  const StrideMapView({
    super.key,
    this.initialCameraPositionOverride,
    this.staticPath,
    this.isCaptured = false,
    this.isPreviewMode = false,
  });

  @override
  ConsumerState<StrideMapView> createState() => _StrideMapViewState();
}

class _StrideMapViewState extends ConsumerState<StrideMapView> {
  final GeospatialService _geoService = GeospatialService();
  MapLibreMapController? mapController;
  late final MapRouteLineLayerController _routeLayerController;
  Timer? _territoryRefreshTimer;

  @override
  void initState() {
    super.initState();
    _routeLayerController = MapRouteLineLayerController();
    // 🔥 Ensure we have fresh global territory data on map load
    Future.microtask(() {
      ref.invalidate(allTerritoriesProvider);
    });
    if (!widget.isPreviewMode) {
      _territoryRefreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
        ref.invalidate(allTerritoriesProvider);
      });
    }
  }

  @override
  void dispose() {
    _territoryRefreshTimer?.cancel();
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    mapController = controller;
    _routeLayerController.setMapController(controller);
  }

  void _onCameraIdle() async {
    if (mapController == null) return;
    try {
      final bounds = await mapController!.getVisibleRegion();
      ref
          .read(territoryViewportBoundsProvider.notifier)
          .updateBounds(
            TerritoryViewportBounds(
              lonMin: bounds.southwest.longitude,
              latMin: bounds.southwest.latitude,
              lonMax: bounds.northeast.longitude,
              latMax: bounds.northeast.latitude,
            ),
          );
    } catch (e) {
      debugPrint('Error getting visible region bounds: $e');
    }
  }

  void _onStyleLoadedCallback() async {
    await _routeLayerController.initialize();
    _generateGrid();
    _onCameraIdle();

    // Set initial route color based on profile
    final profile = ref.read(profileControllerProvider).value;
    if (profile?.territoryColor != null) {
      await _routeLayerController.updateRouteColor(profile!.territoryColor!);
    } else {
      await _routeLayerController.updateRouteColor(
        '#CCFF00',
      ); // Default Neon Green
    }

    // 🔥 STATIC PATH PRIORITY
    if (widget.staticPath != null && widget.staticPath!.isNotEmpty) {
      await _routeLayerController.updateRoute(widget.staticPath!);
      if (widget.isCaptured) {
        await _routeLayerController.updateTerritoryPolygon(widget.staticPath!);
      }
      await _fitRouteBounds(
        widget.staticPath!,
        isPreviewMode: widget.isPreviewMode,
      );
    } else {
      final route = ref.read(workoutControllerProvider).points;
      final routePoints = route
          .map((point) => latlong.LatLng(point.lat, point.lng))
          .toList();
      await _routeLayerController.updateRouteSamples(route);
      await _routeLayerController.updateTerritoryPolygon(routePoints);
      if (routePoints.isNotEmpty) {
        if (!widget.isPreviewMode) {
          await _routeLayerController.updateCurrentPosition(routePoints.last);
          await _routeLayerController.updateRunnerMarker(
            routePoints.last,
            bearingDeg: route.isNotEmpty ? route.last.bearingDeg : null,
          );
        }
        await _fitRouteBounds(routePoints, isPreviewMode: widget.isPreviewMode);
      }
    }

    final presenceData = ref.read(presenceLinesProvider);
    await _routeLayerController.updatePresenceLines(
      presenceData.map((p) => (route: p.route, color: p.color)).toList(),
    );
    final contestedZones = ref.read(contestedZonesProvider);
    await _routeLayerController.updateContestedZones(
      contestedZones
          .map(
            (zone) => (
              center: zone.center,
              radiusMeters: zone.radiusMeters,
              color: zone.colorHex,
              runnerCount: zone.runnerCount,
              severity: zone.severity,
            ),
          )
          .toList(),
    );

    final territories =
        ref.read(allTerritoriesProvider).value ?? <UserTerritory>[];
    await _routeLayerController.updateMasteredTerritories(
      territories
          .map((UserTerritory t) => (geoJson: t.geoJson, color: t.color))
          .toList(),
    );

    // Initial history load
    final history = ref.read(userHistoryProvider).value ?? [];
    _updateHistoryFromData(history);
  }

  Future<void> _fitRouteBounds(
    List<latlong.LatLng> route, {
    bool isPreviewMode = false,
  }) async {
    if (mapController == null || route.isEmpty) return;

    if (route.length == 1) {
      final point = route.first;
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(point.latitude, point.longitude),
          isPreviewMode
              ? 16.6
              : (ref.read(fakeLocationActiveProvider) ? 17.0 : 16.0),
        ),
      );
      if (isPreviewMode) {
        await mapController!.animateCamera(CameraUpdate.tiltTo(44));
      }
      return;
    }

    double minLat = route.first.latitude;
    double maxLat = route.first.latitude;
    double minLng = route.first.longitude;
    double maxLng = route.first.longitude;

    for (final point in route.skip(1)) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    const minSpan = 0.0015;
    final latSpan = (maxLat - minLat).abs().clamp(minSpan, 999.0);
    final lngSpan = (maxLng - minLng).abs().clamp(minSpan, 999.0);
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    if (isPreviewMode) {
      final dominantSpan = math.max(latSpan, lngSpan);
      final zoom = (16.9 - (math.log(dominantSpan / minSpan) / math.ln2)).clamp(
        14.3,
        17.2,
      );
      await mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(centerLat - latSpan * 0.08, centerLng),
            zoom: zoom,
            bearing: -12,
            tilt: 48,
          ),
        ),
      );
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - latSpan * 0.18, minLng - lngSpan * 0.18),
      northeast: LatLng(maxLat + latSpan * 0.18, maxLng + lngSpan * 0.18),
    );

    await mapController!.moveCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        left: isPreviewMode ? 56 : 36,
        top: isPreviewMode ? 56 : 36,
        right: isPreviewMode ? 56 : 36,
        bottom: isPreviewMode ? 56 : 36,
      ),
    );
  }

  void _generateGrid() {
    if (mapController == null) return;

    final target = mapController!.cameraPosition?.target ?? const LatLng(0, 0);
    if (target.latitude == 0 && target.longitude == 0) return;

    final centerH3 = _geoService.coordinateToH3Index(
      target.latitude,
      target.longitude,
      resolution: 9,
    );
    final neighbors = _geoService.getNeighbors(centerH3, k: 3);

    for (String hex in neighbors) {
      final boundary = _geoService.getH3Boundary(hex);
      final points = boundary
          .map((coord) => LatLng(coord.lat, coord.lon))
          .toList();
      String hexColor = '#ffffff';
      double opacity = 0.02;
      mapController!.addFill(
        FillOptions(
          geometry: [points],
          fillColor: hexColor,
          fillOpacity: opacity,
          fillOutlineColor: hexColor,
        ),
      );
    }
  }

  void _updateHistoryFromData(List<RunHistory> history) {
    final List<List<latlong.LatLng>> lines = [];
    for (var mission in history) {
      if (mission.pathWkt != null &&
          mission.pathWkt!.startsWith('LINESTRING')) {
        final coords = _parseWKTLineString(mission.pathWkt!);
        if (coords.isNotEmpty) lines.add(coords);
      }
    }
    _routeLayerController.updateHistoryLines(lines);
  }

  List<latlong.LatLng> _parseWKTLineString(String wkt) {
    try {
      final content = wkt.replaceAll('LINESTRING(', '').replaceAll(')', '');
      final pairs = content.split(',');
      return pairs.map((pair) {
        final parts = pair.trim().split(' ');
        return latlong.LatLng(double.parse(parts[1]), double.parse(parts[0]));
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _locateUser() async {
    if (mapController == null) return;

    if (ref.read(fakeLocationActiveProvider)) {
      final config = ref.read(devFakeLocationConfigProvider);
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(config.centerLat, config.centerLng),
          16.0,
        ),
      );
      return;
    }

    try {
      Position? position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          16.0,
        ),
      );
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialPositionAsync = ref.watch(userInitialPositionProvider);
    final fakeActive = ref.watch(fakeLocationActiveProvider);

    // Listen for recenter trigger
    ref.listen<int>(mapRecenterTriggerProvider, (previous, next) {
      if (next > 0) {
        _locateUser();
      }
    });

    // Watch profile for color updates
    ref.listen(profileControllerProvider, (previous, next) {
      next.whenData((profile) {
        if (profile?.territoryColor != null) {
          _routeLayerController.updateRouteColor(profile!.territoryColor!);
        }
      });
    });

    // 1. Listeners for reactive updates
    if (widget.staticPath == null) {
      ref.listen(workoutControllerProvider, (previous, next) {
        final route = next.points
            .map((p) => latlong.LatLng(p.lat, p.lng))
            .toList();
        if (route.isNotEmpty) {
          _routeLayerController.updateRoute(route);
          _routeLayerController.updateTerritoryPolygon(route);
          if (!widget.isPreviewMode) {
            _routeLayerController.updateCurrentPosition(route.last);
            _routeLayerController.updateRunnerMarker(
              route.last,
              bearingDeg: next.points.last.bearingDeg,
            );
          }
        }
      });

      ref.listen(presenceLinesProvider, (previous, next) {
        _routeLayerController.updatePresenceLines(
          next.map((p) => (route: p.route, color: p.color)).toList(),
        );
      });

      ref.listen(contestedZonesProvider, (previous, next) {
        _routeLayerController.updateContestedZones(
          next
              .map(
                (zone) => (
                  center: zone.center,
                  radiusMeters: zone.radiusMeters,
                  color: zone.colorHex,
                  runnerCount: zone.runnerCount,
                  severity: zone.severity,
                ),
              )
              .toList(),
        );
      });
    }

    ref.listen(allTerritoriesProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final List<UserTerritory> territories = next.value!;
        _routeLayerController.updateMasteredTerritories(
          territories
              .map((UserTerritory t) => (geoJson: t.geoJson, color: t.color))
              .toList(),
        );
      }
    });

    ref.listen(userHistoryProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        _updateHistoryFromData(next.value!);
      }
    });

    // 2. Conditional Rendering

    // Override case (History / Detail)
    if (widget.initialCameraPositionOverride != null) {
      return _buildMap(context, widget.initialCameraPositionOverride!);
    }

    // Fake GPS case
    if (fakeActive) {
      final config = ref.read(devFakeLocationConfigProvider);
      return _buildMap(
        context,
        CameraPosition(
          target: LatLng(config.centerLat, config.centerLng),
          zoom: 16.0,
        ),
      );
    }

    // Real GPS Lifecycle
    return initialPositionAsync.when(
      data: (position) {
        if (position == null) {
          return _buildLocationPrompt('PLEASE TURN YOUR LOCATION ON');
        }
        return _buildMap(
          context,
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        );
      },
      loading: () => _buildLoadingView(),
      error: (err, stack) => _buildLocationPrompt('RECONNAISSANCE ERROR'),
    );
  }

  Widget _buildMap(BuildContext context, CameraPosition initialPos) {
    final bool isFake = ref.read(fakeLocationActiveProvider);
    final bool isStaticMode = widget.staticPath != null || widget.isPreviewMode;
    return MapLibreMap(
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoadedCallback,
      initialCameraPosition: initialPos,
      styleString:
          'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json',
      myLocationEnabled: isStaticMode ? false : !isFake,
      compassEnabled: false,
      myLocationRenderMode: isStaticMode
          ? MyLocationRenderMode.normal
          : (isFake
                ? MyLocationRenderMode.normal
                : MyLocationRenderMode.compass),
      scrollGesturesEnabled: !widget.isPreviewMode,
      zoomGesturesEnabled: !widget.isPreviewMode,
      rotateGesturesEnabled: !widget.isPreviewMode,
      tiltGesturesEnabled: !widget.isPreviewMode,
      doubleClickZoomEnabled: !widget.isPreviewMode,
      dragEnabled: !widget.isPreviewMode,
      onCameraIdle: _onCameraIdle,
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: StrideColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: StrideColors.neonGreen),
            const SizedBox(height: 24),
            Text(
              'ESTABLISHING SATELLITE LINK...',
              style: StrideTypography.labelTactical.copyWith(
                fontSize: 10,
                color: StrideColors.neonGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPrompt(String message) {
    return Container(
      color: StrideColors.background,
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              color: StrideColors.white,
              size: 48,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: StrideTypography.headlineMD.copyWith(
                fontSize: 18,
                color: StrideColors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'GRID SYNC REQUIRES ACTIVE GPS SIGNAL.',
              textAlign: TextAlign.center,
              style: StrideTypography.labelTactical.copyWith(
                fontSize: 8,
                color: StrideColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            V3SkewBox(
              child: ElevatedButton(
                onPressed: () => ref
                    .read(locationPermissionProvider.notifier)
                    .requestPermission(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: StrideColors.white,
                  foregroundColor: StrideColors.background,
                ),
                child: const Text('INITIATE REQUEST'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
