import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/theme/app_theme.dart';
import '../features/workout/application/workout_controller.dart';
import '../core/domain/models/workout_session.dart';
import 'dev_providers.dart';
import 'fake_location_service.dart';

class DevMenu extends ConsumerStatefulWidget {
  const DevMenu({super.key});

  @override
  ConsumerState<DevMenu> createState() => _DevMenuState();
}

class _DevMenuState extends ConsumerState<DevMenu> {
  late final TextEditingController _centerLatController =
      TextEditingController();
  late final TextEditingController _centerLngController =
      TextEditingController();
  late final TextEditingController _loopDistanceController =
      TextEditingController();
  late final TextEditingController _durationController =
      TextEditingController();
  late final TextEditingController _sampleIntervalController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _applyConfigToControllers(ref.read(devFakeLocationConfigProvider));
  }

  @override
  void dispose() {
    _centerLatController.dispose();
    _centerLngController.dispose();
    _loopDistanceController.dispose();
    _durationController.dispose();
    _sampleIntervalController.dispose();
    super.dispose();
  }

  void _applyConfigToControllers(FakeLocationConfig config) {
    _centerLatController.text = config.centerLat.toStringAsFixed(6);
    _centerLngController.text = config.centerLng.toStringAsFixed(6);
    _loopDistanceController.text = config.loopDistanceMeters.toStringAsFixed(0);
    _durationController.text = config.durationSeconds.toString();
    _sampleIntervalController.text = config.sampleInterval.inSeconds.toString();
  }

  Future<void> _applyConfig() async {
    final notifier = ref.read(devFakeLocationConfigProvider.notifier);
    await notifier.setField(
      centerLat: double.tryParse(_centerLatController.text),
      centerLng: double.tryParse(_centerLngController.text),
      loopDistanceMeters: double.tryParse(_loopDistanceController.text),
      durationSeconds: int.tryParse(_durationController.text),
      sampleInterval: Duration(
        seconds: int.tryParse(_sampleIntervalController.text) ?? 1,
      ),
    );
    if (ref.read(fakeLocationActiveProvider)) {
      ref.read(workoutControllerProvider.notifier).refreshTrackingSource();
    }
  }

  Future<void> _setFakeEnabled(bool enabled) async {
    await ref.read(useFakeLocationPrefProvider.notifier).setEnabled(enabled);
    if (ref.read(workoutControllerProvider).state == WorkoutState.running) {
      ref.read(workoutControllerProvider.notifier).refreshTrackingSource();
    }
  }

  Future<void> _applyPreset(FakeLocationConfig config) async {
    await ref.read(devFakeLocationConfigProvider.notifier).applyPreset(config);
    _applyConfigToControllers(config);
    if (ref.read(fakeLocationActiveProvider)) {
      ref.read(workoutControllerProvider.notifier).refreshTrackingSource();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appMode = ref.watch(appModeProvider);
    final useFake = ref.watch(useFakeLocationPrefProvider);
    final config = ref.watch(devFakeLocationConfigProvider);
    final isActive = ref.watch(fakeLocationActiveProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('DEV MENU'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fake GPS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: useFake,
                      onChanged: appMode == AppMode.dev
                          ? _setFakeEnabled
                          : null,
                      activeThumbColor: AppTheme.sapphire,
                    ),
                  ],
                ),
                Text(
                  appMode == AppMode.dev
                      ? 'Dev mode enabled. Toggle controls locationStreamProvider.'
                      : 'Production mode. Fake GPS is disabled.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${isActive ? 'FAKE_LOCATION_ACTIVE' : 'Real GPS'}',
                  style: const TextStyle(color: AppTheme.sapphire),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scenario',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Circular Run (Simple Loop)'),
                  leading: Radio<FakeScenario>(
                    value: FakeScenario.circular,
                    groupValue: config.scenario,
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(devFakeLocationConfigProvider.notifier).setField(scenario: v);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Config',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _numberField('Center Lat', _centerLatController),
                _numberField('Center Lng', _centerLngController),
                _numberField('Loop Distance M', _loopDistanceController),
                _numberField('Duration Sec', _durationController),
                _numberField('Sample Interval Sec', _sampleIntervalController),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _actionButton('Apply Config', _applyConfig),
                    _actionButton(
                      'Start Fake Run',
                      () => _setFakeEnabled(true),
                    ),
                    _actionButton(
                      'Stop Fake Run',
                      () => _setFakeEnabled(false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Presets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _actionButton(
                      '5km / 30min',
                      () => _applyPreset(const FakeLocationConfig.defaults()),
                    ),
                    _actionButton(
                      '5km / 5min',
                      () => _applyPreset(
                        FakeLocationConfig.defaults().copyWith(
                          durationSeconds: 300,
                        ),
                      ),
                    ),
                    _actionButton(
                      '1km Walk',
                      () => _applyPreset(
                        FakeLocationConfig.defaults().copyWith(
                          loopDistanceMeters: 1000,
                          durationSeconds: 1200,
                          variablePace: false,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  config.debugLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debug Overlays',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _debugToggle(
                  'rawPoints',
                  config.showRawPoints,
                  (value) => ref
                      .read(devFakeLocationConfigProvider.notifier)
                      .setField(showRawPoints: value),
                ),
                _debugToggle(
                  'displayPoints',
                  config.showDisplayPoints,
                  (value) => ref
                      .read(devFakeLocationConfigProvider.notifier)
                      .setField(showDisplayPoints: value),
                ),
                _debugToggle(
                  'sampleRate',
                  config.showSampleRate,
                  (value) => ref
                      .read(devFakeLocationConfigProvider.notifier)
                      .setField(showSampleRate: value),
                ),
                _debugToggle(
                  'lastAccuracy',
                  config.showLastAccuracy,
                  (value) => ref
                      .read(devFakeLocationConfigProvider.notifier)
                      .setField(showLastAccuracy: value),
                ),
                _debugToggle(
                  'cumulativeDistance',
                  config.showCumulativeDistance,
                  (value) => ref
                      .read(devFakeLocationConfigProvider.notifier)
                      .setField(showCumulativeDistance: value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Network Overlays',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _debugToggle(
                  'Supabase Connection Logs',
                  ref.watch(lariDevLogEnabledProvider),
                  (value) async {
                    ref.read(lariDevLogEnabledProvider.notifier).toggle(value);
                  },
                ),
                _debugToggle(
                  'Use Mock Backend',
                  ref.watch(useMockBackendPrefProvider),
                  (value) async {
                    await ref.read(useMockBackendPrefProvider.notifier).setEnabled(value);
                  },
                ),
                _debugToggle(
                  'Connect to Local Go (localhost)',
                  ref.watch(useLocalBackendPrefProvider),
                  (value) async {
                    await ref.read(useLocalBackendPrefProvider.notifier).setEnabled(value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassBase.withOpacity(0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.sapphire.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: AppTheme.sapphire.withOpacity(0.06), blurRadius: 14),
        ],
      ),
      child: child,
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _actionButton(String label, Future<void> Function() onPressed) {
    return ElevatedButton(
      onPressed: () async => onPressed(),
      child: Text(label),
    );
  }

  Widget _debugToggle(
    String label,
    bool value,
    Future<void> Function(bool) onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: (next) async => onChanged(next),
    );
  }
}
