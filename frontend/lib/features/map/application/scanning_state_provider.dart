import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ScanningState { acquiringGps, gpsLocked, scanningSectors, complete }

extension ScanningStateX on ScanningState {
  String get label {
    switch (this) {
      case ScanningState.acquiringGps:
        return 'ACQUIRING GPS...';
      case ScanningState.gpsLocked:
        return 'GPS LOCKED';
      case ScanningState.scanningSectors:
        return 'SCANNING SECTORS';
      case ScanningState.complete:
        return 'READY';
    }
  }

  bool get isAnimating =>
      this == ScanningState.acquiringGps ||
      this == ScanningState.scanningSectors;
}

/// Scanning state machine provider
/// Simulates GPS acquisition → lock → scanning → complete
/// In production, this would be driven by actual GPS and sector data
final scanningStateProvider =
    NotifierProvider<_ScanningStateNotifier, ScanningState>(() {
      return _ScanningStateNotifier();
    });

class _ScanningStateNotifier extends Notifier<ScanningState> {
  @override
  ScanningState build() {
    return ScanningState.acquiringGps;
  }

  void updateState(ScanningState newState) {
    state = newState;
  }
}
