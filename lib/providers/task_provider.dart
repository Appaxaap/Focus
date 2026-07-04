import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import '../models/focus_completion_event.dart';
import '../models/quadrant_enum.dart';
import '../models/task_models.dart';
import 'focus_history_provider.dart';
import '../services/hive_service.dart';

// Main provider for all tasks
final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  final hiveService = ref.read(hiveServiceProvider);
  return TaskNotifier(hiveService, ref);
});

class TaskNotifier extends StateNotifier<List<Task>> {
  final HiveService _hiveService;
  final Ref _ref;
  bool _isLoading = false;

  TaskNotifier(this._hiveService, this._ref) : super([]) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final tasks = await _hiveService.getAllTasks();
      state = tasks;
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      state = [];
    } finally {
      _isLoading = false;
    }
  }

  // Adds a new task
  Future<void> addTask({
    required String title,
    String? notes,
    required Quadrant quadrant,
    DateTime? dueDate,
  }) async {
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      notes: notes,
      quadrant: quadrant,
      dueDate: dueDate,
    );
    await _hiveService.addTask(task);
    await _loadTasks();
  }

  // Updates an existing task
  Future<void> updateTask(Task updatedTask) async {
    final taskIndex = state.indexWhere((task) => task.id == updatedTask.id);
    if (taskIndex != -1) {
      // Existing task
      await _hiveService.updateTask(
        updatedTask.copyWith(updatedAt: DateTime.now()),
      );
    } else {
      // New task
      await _hiveService.addTask(updatedTask);
    }
    await _loadTasks();
  }

  // Deletes a task
  Future<void> deleteTask(String taskId) async {
    state = state.where((task) => task.id != taskId).toList();

    try {
      await _hiveService.deleteTask(taskId);
    } catch (e) {
      await _loadTasks();
    }
  }

  // Optimistically removes from state without touching Hive (for undo delete)
  void removeFromState(String taskId) {
    state = state.where((task) => task.id != taskId).toList();
  }

  // Restores a task back to state and Hive (undo delete)
  Future<void> restoreTask(Task task) async {
    await _hiveService.addTask(task);
    await _loadTasks();
  }

  // Permanently deletes from Hive after undo window expires
  Future<void> commitDelete(String taskId) async {
    try {
      await _hiveService.deleteTask(taskId);
    } catch (e) {
      await _loadTasks();
    }
  }

  // Clear completed tasks
  Future<void> clearCompletedTasks() async {
    // Get all completed task IDs
    final completedIds = state
        .where((task) => task.isCompleted)
        .map((task) => task.id)
        .toList();

    // Delete each from Hive
    for (final id in completedIds) {
      await _hiveService.deleteTask(id);
    }

    // Reload tasks
    await _loadTasks();
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      await setTaskCompletion(taskId, !state[taskIndex].isCompleted);
    }
  }

  Future<void> setTaskCompletion(String taskId, bool completed) async {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final currentTask = state[taskIndex];
      if (currentTask.isCompleted == completed) {
        return;
      }

      final updatedAt = DateTime.now();
      final updatedTask = currentTask.copyWith(
        isCompleted: completed,
        updatedAt: updatedAt,
      );
      final newState = List<Task>.from(state);
      newState[taskIndex] = updatedTask;
      state = newState;

      await _hiveService.updateTask(updatedTask);

      final historyNotifier = _ref.read(focusHistoryProvider.notifier);
      if (completed) {
        await historyNotifier.addEvent(
          FocusCompletionEvent(
            id: '${updatedTask.id}_${updatedAt.millisecondsSinceEpoch}',
            taskId: updatedTask.id,
            completedAt: updatedAt,
            quadrantAtCompletion: updatedTask.quadrant,
            titleSnapshot: updatedTask.title,
          ),
        );
      } else {
        await historyNotifier.removeLatestForTask(updatedTask.id);
      }
    }
  }

  // Move task to a different quadrant
  Future<void> moveTaskToQuadrant(String taskId, Quadrant newQuadrant) async {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = state[taskIndex];
      final updatedTask = task.copyWith(quadrant: newQuadrant);
      await _hiveService.updateTask(updatedTask);
      await _loadTasks();
    }
  }
}
