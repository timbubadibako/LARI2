import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../workout/application/workout_controller.dart';
import '../../services/share_service.dart';
import '../widgets/static_carto_map.dart';
import '../widgets/route_line_painter.dart';

class SocialGridShareOverlay extends ConsumerStatefulWidget {
  const SocialGridShareOverlay({super.key});

  @override
  ConsumerState<SocialGridShareOverlay> createState() =>
      _SocialGridShareOverlayState();
}

class _SocialGridShareOverlayState
    extends ConsumerState<SocialGridShareOverlay> {
  final GlobalKey _globalKey = GlobalKey();
  int _currentIndex = 0;
  static const Color _purpleAccent = Color(0xFFB58CFF);

  void _captureAndShare(bool saveOnly, {bool transparent = false}) async {
    // Give time for UI to update without BottomSheet if needed
    await Future.delayed(const Duration(milliseconds: 100));

    final shareService = ref.read(shareServiceProvider);
    final bytes = await shareService.captureWidget(_globalKey);

    if (bytes != null && mounted) {
      if (saveOnly) {
        final success = await shareService.saveToGallery(
          bytes,
          isTransparent: transparent,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'Saved to Gallery!' : 'Failed to save image.',
              ),
              backgroundColor: success ? AppTheme.sapphire : AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await shareService.shareImage(bytes, text: _generateShareText());
      }
    }
  }

  void _copyText() async {
    final shareService = ref.read(shareServiceProvider);
    await shareService.copyToClipboard(_generateShareText());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caption copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _generateShareText() {
    final workout = ref.read(workoutControllerProvider);
    final distKm = (workout.distanceMeters / 1000).toStringAsFixed(2);
    return 'I just claimed the grid! Total distance: ${distKm}km on Lari-Lari. The grid is yours to take! ⚡';
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(workoutControllerProvider);
    final distKm = (workout.distanceMeters / 1000).toStringAsFixed(2);
    final minutes = (workout.durationSeconds / 60).floor();
    final seconds = workout.durationSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final paceStr = workout.avgPaceSecondsPerKm != null
        ? '${(workout.avgPaceSecondsPerKm! / 60).floor().toString().padLeft(2, '0')}:${(workout.avgPaceSecondsPerKm! % 60).floor().toString().padLeft(2, '0')}'
        : '--:--';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Backdrop Filter (Deep Dark 80% opacity with blur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(color: const Color(0xFF0A0A0B).withValues(alpha: 0.8)),
            ),
          ),

          // Carousel Area
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 20),

                // Carousel Area
                Expanded(
                  child: PageView.builder(
                    itemCount: 7,
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      return Center(
                        child: RepaintBoundary(
                          key: index == _currentIndex ? _globalKey : null,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: MediaQuery.of(context).size.height * 0.55,
                            margin: const EdgeInsets.symmetric(horizontal: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: _buildTemplateVariant(
                              index,
                              workout,
                              distKm,
                              timeStr,
                              paceStr,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Indicators (Fake carousel)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      7,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentIndex ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _currentIndex
                              ? AppTheme.sapphire
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Action Sheet
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  decoration: BoxDecoration(
                    color: AppTheme.glassBase,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.sapphire.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Social Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSocialButton(
                            Icons.camera_alt,
                            'IG/FB',
                            () => _captureAndShare(false),
                          ),
                          _buildSocialButton(
                            Icons.chat,
                            'WhatsApp',
                            () => _captureAndShare(false),
                          ),
                          _buildSocialButton(
                            Icons.directions_run,
                            'Strava',
                            () => _captureAndShare(false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Download Section
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _captureAndShare(true, transparent: false),
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('Save Image'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.sapphire,
                                foregroundColor: AppTheme.obsidian,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _captureAndShare(true, transparent: true),
                              icon: const Icon(
                                Icons.download_outlined,
                                size: 18,
                              ),
                              label: const Text('Save Transparent'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.sapphire,
                                side: const BorderSide(
                                  color: AppTheme.sapphire,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Clipboard Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: _copyText,
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy Caption'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed:
                                _copyText, // Copying text as fallback for link
                            icon: const Icon(Icons.link, size: 16),
                            label: const Text('Copy Link'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color?.withValues(alpha: 0.7) ?? Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMapLayer(
    dynamic workout,
    double centerLat,
    double centerLng, {
    required Color routeColor,
    int zoom = 15,
    bool showVignette = true,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        StaticCartoMap(
          centerLat: centerLat,
          centerLng: centerLng,
          zoom: zoom,
          isLightMode: false,
        ),
        CustomPaint(
          painter: RouteLinePainter(
            points: workout.points,
            drawGrid: false,
            isLightMode: false,
            zoom: zoom,
            accentColor: routeColor,
          ),
          child: Container(),
        ),
        if (showVignette)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.15,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.42),
                  ],
                  stops: const [0.55, 0.8, 1.0],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTemplateVariant(
    int index,
    dynamic workout,
    String distKm,
    String timeStr,
    String paceStr,
  ) {
    double centerLat = -6.225014;
    double centerLng = 106.827143;
    if (workout.points.isNotEmpty) {
      double minLat = workout.points.first.lat;
      double maxLat = workout.points.first.lat;
      double minLng = workout.points.first.lng;
      double maxLng = workout.points.first.lng;
      for (var p in workout.points) {
        if (p.lat < minLat) minLat = p.lat;
        if (p.lat > maxLat) maxLat = p.lat;
        if (p.lng < minLng) minLng = p.lng;
        if (p.lng > maxLng) maxLng = p.lng;
      }
      centerLat = (minLat + maxLat) / 2;
      centerLng = (minLng + maxLng) / 2;
    }

    switch (index) {
      case 0:
        // Template 1: Classic Glassmorphism Overlay
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _buildMapLayer(
                workout,
                centerLat,
                centerLng,
                routeColor: AppTheme.sapphire,
                zoom: 15,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'LARI-LARI',
                            style: TextStyle(
                              color: AppTheme.sapphire,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const Icon(
                            Icons.bolt,
                            color: AppTheme.sapphire,
                            size: 24,
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text(
                        '12 HEXAGONS CLAIMED',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            distKm,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 56,
                              height: 1.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'KM',
                              style: TextStyle(
                                color: AppTheme.sapphire,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetric('PACE', paceStr),
                          _buildMetric('TIME', timeStr),
                          _buildMetric(
                            'KCAL',
                            '${workout.caloriesEstimate.toStringAsFixed(0)}',
                          ),
                          _buildMetric('BPM', '142'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case 1:
        // Template 2: Minimalist Dark Solid background with Map on Top Half
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101019),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.sapphire.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: _buildMapLayer(
                    workout,
                    centerLat,
                    centerLng,
                    routeColor: AppTheme.sapphire,
                    zoom: 15,
                  ),
                ),
              ),
              Container(height: 2, color: AppTheme.sapphire),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'DOMINANCE RECORD',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'LARI-LARI',
                            style: TextStyle(
                              color: AppTheme.sapphire,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                distKm,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                              const Text(
                                'KILOMETERS',
                                style: TextStyle(
                                  color: AppTheme.sapphire,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                paceStr,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case 2:
        // Template 3: Cyberpunk Vertical Split
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1326),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _purpleAccent.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: _purpleAccent.withValues(alpha: 0.16),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 12, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'LARI-LARI',
                          style: TextStyle(
                            color: _purpleAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildMetric(
                        'DISTANCE',
                        '$distKm KM',
                        color: _purpleAccent,
                      ),
                      const SizedBox(height: 16),
                      _buildMetric('PACE', paceStr, color: Colors.white),
                      const SizedBox(height: 16),
                      _buildMetric('TIME', timeStr, color: Colors.white),
                    ],
                  ),
                ),
              ),
              Container(width: 1, color: _purpleAccent.withValues(alpha: 0.35)),
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(24),
                  ),
                  child: _buildMapLayer(
                    workout,
                    centerLat,
                    centerLng,
                    routeColor: _purpleAccent,
                    zoom: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      case 3:
        // Template 4: Central Floating Card over Map
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _buildMapLayer(
                workout,
                centerLat,
                centerLng,
                routeColor: AppTheme.sapphire,
                zoom: 15,
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: AppTheme.background.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.sapphire.withValues(alpha: 0.2),
                      blurRadius: 20,
                    ),
                  ],
                  border: Border.all(color: AppTheme.sapphire),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'MISSION ACCOMPLISHED',
                      style: TextStyle(
                        color: AppTheme.sapphire,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$distKm KM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMetric('PACE', paceStr),
                        _buildMetric('TIME', timeStr),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 4:
        // Template 5: Pure Data Dashboard (No Map)
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D11),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            image: const DecorationImage(
              image: NetworkImage(
                'https://www.transparenttextures.com/patterns/cubes.png',
              ), // Mock pattern
              opacity: 0.1,
              repeat: ImageRepeat.repeat,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hub, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Text(
                    'GRID DOMINATION',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                distKm,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const Text(
                'KILOMETERS CAPTURED',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetric('AVG PACE', paceStr, color: Colors.white),
                  _buildMetric('ELAPSED', timeStr, color: Colors.white),
                  _buildMetric('HEXAGONS', '12', color: Colors.amber),
                ],
              ),
            ],
          ),
        );
      case 5:
        // Template 6: Polaroid Map Style with static route (no MapLibre to avoid crashes)
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F3FF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _purpleAccent.withValues(alpha: 0.22)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      StaticCartoMap(
                        centerLat: centerLat,
                        centerLng: centerLng,
                        zoom: 14,
                        isLightMode: true,
                      ),
                      CustomPaint(
                        painter: RouteLinePainter(
                          points: workout.points,
                          drawGrid: false,
                          isLightMode: true,
                          zoom: 14,
                          accentColor: _purpleAccent,
                        ),
                        child: Container(),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.04),
                              _purpleAccent.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STRIDE.IO',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateTime.now().toLocal().toString().split(' ')[0],
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$distKm km',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case 6:
      default:
        // Template 7: Bottom Gradient
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _buildMapLayer(
                workout,
                centerLat,
                centerLng,
                routeColor: AppTheme.sapphire,
                zoom: 14,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '12 HEXAGONS',
                    style: TextStyle(
                      color: _purpleAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '$distKm KM',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.speed, color: Colors.white54, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        paceStr,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: AppTheme.sapphire),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
