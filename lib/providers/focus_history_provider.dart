import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../models/focus_completion_event.dart';
import '../services/hive_service.dart';

final focusHistoryProvider =
    StateNotifierProvider<FocusHistoryNotifier, List<FocusCompletionEvent>>((
  ref,
) {
  final hiveService = ref.read(hiveServiceProvider);
  return FocusHistoryNotifier(hiveService);
});

class FocusHistoryNotifier extends StateNotifier<List<FocusCompletionEvent>> {
  final HiveService _hiveService;
  bool _isLoading = false;

  FocusHistoryNotifier(this._hiveService) : super([]) {
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      state = await _hiveService.getCompletionEvents();
    } catch (_) {
      state = [];
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() => _loadEvents();

  Future<void> addEvent(FocusCompletionEvent event) async {
    await _hiveService.addCompletionEvent(event);
    await _loadEvents();
  }

  Future<void> removeLatestForTask(String taskId) async {
    await _hiveService.removeLatestCompletionEventForTask(taskId);
    await _loadEvents();
  }
}
