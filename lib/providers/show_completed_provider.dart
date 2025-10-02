import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

class ShowCompletedTasksNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final hiveService = ref.read(hiveServiceProvider);
    return await hiveService.getShowCompletedPreference();
  }

  Future<void> toggle() async {
    final newValue = !(state.value ?? false);
    state = AsyncData(newValue);
    final hiveService = ref.read(hiveServiceProvider);
    await hiveService.setShowCompletedPreference(newValue);
  }

  Future<void> set(bool value) async {
    state = AsyncData(value);
    final hiveService = ref.read(hiveServiceProvider);
    await hiveService.setShowCompletedPreference(value);
  }
}

final showCompletedTasksProvider =
AsyncNotifierProvider<ShowCompletedTasksNotifier, bool>(
  ShowCompletedTasksNotifier.new,
);