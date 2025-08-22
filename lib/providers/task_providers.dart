// lib/providers/task_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_service.dart';
import '../main.dart';

// Controls whether completed tasks are shown
final showCompletedTasksProvider = StateProvider<bool>((ref) => false);

// Provider that automatically saves the show completed preference when it changes
final showCompletedTasksNotifierProvider = StateNotifierProvider<ShowCompletedTasksNotifier, bool>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return ShowCompletedTasksNotifier(hiveService);
});

class ShowCompletedTasksNotifier extends StateNotifier<bool> {
  final HiveService _hiveService;

  ShowCompletedTasksNotifier(this._hiveService) : super(false) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final preference = await _hiveService.getShowCompletedPreference();
    state = preference;
  }

  Future<void> toggle() async {
    state = !state;
    await _hiveService.setShowCompletedPreference(state);
  }

  Future<void> setValue(bool value) async {
    state = value;
    await _hiveService.setShowCompletedPreference(state);
  }
}