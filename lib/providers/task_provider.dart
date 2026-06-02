import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import '../models/quadrant_enum.dart';
import '../models/task_models.dart';
import '../services/hive_service.dart';

// Main provider for all tasks
final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  final hiveService = ref.read(hiveServiceProvider);
  return TaskNotifier(hiveService);
});

class TaskNotifier extends StateNotifier<List<Task>> {
  final HiveService _hiveService;
  bool _isLoading = false;

  TaskNotifier(this._hiveService) : super([]) {
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

  Future<void> refresh() async {
    await _loadTasks();
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
    state = [...state, task];
    try {
      await _hiveService.addTask(task);
    } catch (e) {
      await _loadTasks();
    }
  }

  // Updates an existing task
  Future<void> updateTask(Task updatedTask) async {
    final normalizedTask = updatedTask.copyWith(updatedAt: DateTime.now());
    final taskIndex = state.indexWhere((task) => task.id == updatedTask.id);
    if (taskIndex != -1) {
      final previous = state[taskIndex];
      final next = List<Task>.from(state);
      next[taskIndex] = normalizedTask;
      state = next;
      try {
        await _hiveService.updateTask(normalizedTask);
      } catch (e) {
        final rollback = List<Task>.from(state);
        final i = rollback.indexWhere((t) => t.id == previous.id);
        if (i != -1) rollback[i] = previous;
        state = rollback;
      }
    } else {
      state = [...state, normalizedTask];
      try {
        await _hiveService.addTask(normalizedTask);
      } catch (e) {
        state = state.where((task) => task.id != normalizedTask.id).toList();
      }
    }
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
    state = [...state, task];
    try {
      await _hiveService.addTask(task);
    } catch (e) {
      await _loadTasks();
    }
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
    final previous = state;
    final completedIds = previous
        .where((task) => task.isCompleted)
        .map((task) => task.id)
        .toList();
    state = previous.where((task) => !task.isCompleted).toList();
    try {
      await Future.wait(completedIds.map(_hiveService.deleteTask));
    } catch (e) {
      state = previous;
    }
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final updatedTask = state[taskIndex].copyWith(
        isCompleted: !state[taskIndex].isCompleted,
      );
      final newState = List<Task>.from(state);
      newState[taskIndex] = updatedTask;
      state = newState;

      await _hiveService.updateTask(updatedTask);
    }
  }

  // Move task to a different quadrant
  Future<void> moveTaskToQuadrant(String taskId, Quadrant newQuadrant) async {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = state[taskIndex];
      final updatedTask = task.copyWith(
        quadrant: newQuadrant,
        updatedAt: DateTime.now(),
      );
      final next = List<Task>.from(state);
      next[taskIndex] = updatedTask;
      state = next;
      try {
        await _hiveService.updateTask(updatedTask);
      } catch (e) {
        final rollback = List<Task>.from(state);
        final i = rollback.indexWhere((t) => t.id == task.id);
        if (i != -1) rollback[i] = task;
        state = rollback;
      }
    }
  }
}
