import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui_load_state.dart';

class UiStateNotifier extends Notifier<UiLoadState> {
  @override
  UiLoadState build() => UiLoadState.loaded;
  void setState(UiLoadState newState) => state = newState;
}

final dashboardUiStateProvider = NotifierProvider<UiStateNotifier, UiLoadState>(UiStateNotifier.new);
final activeWorkoutUiStateProvider = NotifierProvider<UiStateNotifier, UiLoadState>(UiStateNotifier.new);
final postRunUiStateProvider = NotifierProvider<UiStateNotifier, UiLoadState>(UiStateNotifier.new);
final socialUiStateProvider = NotifierProvider<UiStateNotifier, UiLoadState>(UiStateNotifier.new);
final profileUiStateProvider = NotifierProvider<UiStateNotifier, UiLoadState>(UiStateNotifier.new);
