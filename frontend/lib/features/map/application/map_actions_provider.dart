import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple notifier to communicate actions from the HUD to the Map.
/// When the state is updated, it signifies a recenter request.
class MapRecenterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() {
    state++;
  }
}

final mapRecenterTriggerProvider = NotifierProvider<MapRecenterNotifier, int>(() {
  return MapRecenterNotifier();
});
