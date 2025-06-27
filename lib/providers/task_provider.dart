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
      await _hiveService.updateTask(updatedTask.copyWith(updatedAt: DateTime.now()));
    } else {
      // New task
      await _hiveService.addTask(updatedTask);
    }
    await _loadTasks();
  }

  // Deletes a task
  Future<void> deleteTask(String taskId) async {
    await _hiveService.deleteTask(taskId);
    await _loadTasks();
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = state[taskIndex];
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await _hiveService.updateTask(updatedTask);
      await _loadTasks();
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