import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import '../models/quadrant_enum.dart';
import '../models/task_models.dart';
import '../providers/theme_provider.dart';

class HiveService {
  static const String _taskBoxName = 'tasks';
  static const String _prefsBoxName = 'preferences';

  Box<Task>? _taskBox;
  Box<dynamic>? _prefsBox;

  // Preference keys
  static const String _showCompletedKey = 'show_completed';
  static const String _themeModeKey = 'theme_mode';

  Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(TaskAdapter().typeId)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(QuadrantAdapter().typeId)) {
      Hive.registerAdapter(QuadrantAdapter());
    }

    // Check if boxes are already open before trying to open them
    if (_taskBox == null || !_taskBox!.isOpen) {
      _taskBox = await Hive.openBox<Task>(_taskBoxName);
    }
    if (_prefsBox == null || !_prefsBox!.isOpen) {
      _prefsBox = await Hive.openBox(_prefsBoxName);
    }
  }

  // Task operations
  Future<void> addTask(Task task) async {
    await _ensureInitialized();
    await _taskBox!.put(task.id, task);
  }

  Future<void> updateTask(Task task) async {
    await _ensureInitialized();
    await _taskBox!.put(task.id, task);
  }

  Future<void> deleteTask(String taskId) async {
    await _ensureInitialized();
    await _taskBox!.delete(taskId);
  }

  Future<List<Task>> getAllTasks() async {
    await _ensureInitialized();
    return _taskBox!.values.toList();
  }

  Future<List<Task>> getTasksByQuadrant(Quadrant quadrant) async {
    await _ensureInitialized();
    return _taskBox!.values.where((task) => task.quadrant == quadrant).toList();
  }

  Future<List<Task>> getActiveTasks() async {
    await _ensureInitialized();
    return _taskBox!.values.where((task) => !task.isCompleted).toList();
  }

  Future<List<Task>> getCompletedTasks() async {
    await _ensureInitialized();
    return _taskBox!.values.where((task) => task.isCompleted).toList();
  }

  // Data management
  Future<void> clearAllData() async {
    try {
      // Clear tasks box
      final tasksBox = await Hive.openBox<Task>('tasks');
      await tasksBox.clear();
      await tasksBox.close();

      // Clear preferences box
      final prefsBox = await Hive.openBox('preferences');
      await prefsBox.clear();
      await prefsBox.close();

      // Clear any other boxes you might have
      // If you have more boxes, add them here

      // Optional: Delete all Hive boxes completely
      await Hive.deleteBoxFromDisk('tasks');
      await Hive.deleteBoxFromDisk('preferences');

      debugPrint('All Hive data cleared successfully');
    } catch (e, stackTrace) {
      debugPrint('Error clearing Hive data: $e\n$stackTrace');
      rethrow;
    }
  }

  static const String _themeKey = 'app_theme';

  Future<void> setThemePreference(AppTheme theme) async {
    await _ensureInitialized();
    await _prefsBox!.put(_themeKey, theme.toString());
  }

  Future<AppTheme?> getThemePreference() async {
    await _ensureInitialized();
    final themeString = _prefsBox!.get(_themeKey) as String?;
    if (themeString == null) return null;
    return AppTheme.values.firstWhere(
          (e) => e.toString() == themeString,
      orElse: () => AppTheme.light,
    );
  }

  Future<String> exportData() async {
    final tasks = await getAllTasks();
    final jsonList = tasks.map((task) => task.toJson()).toList();
    return jsonEncode(jsonList);
  }

  Future<void> importData(List<Map<String, dynamic>> jsonList) async {
    await initialize();
    await _taskBox!.clear();
    for (final json in jsonList) {
      final task = Task.fromJson(json);
      await addTask(task);
    }
  }

  // Preferences operations
  Future<void> setShowCompletedPreference(bool value) async {
    await _ensureInitialized();
    await _prefsBox!.put(_showCompletedKey, value);
  }

  Future<bool> getShowCompletedPreference() async {
    await _ensureInitialized();
    return _prefsBox!.get(_showCompletedKey) as bool? ?? false;
  }

  Future<void> setThemeMode(String value) async {
    await _ensureInitialized();
    await _prefsBox!.put(_themeModeKey, value);
  }

  Future<String> getThemeMode() async {
    await _ensureInitialized();
    return _prefsBox!.get(_themeModeKey, defaultValue: 'light');
  }

  // Cleanup
  Future<void> close() async {
    if (_taskBox?.isOpen == true) await _taskBox!.close();
    if (_prefsBox?.isOpen == true) await _prefsBox!.close();
  }

  // Utility methods
  Future<int> getTaskCount() async {
    await _ensureInitialized();
    return _taskBox!.length;
  }

  Future<int> getCompletedTaskCount() async {
    return (await getCompletedTasks()).length;
  }

  // Helper method to ensure initialization
  Future<void> _ensureInitialized() async {
    if (_taskBox == null || _prefsBox == null || !_taskBox!.isOpen || !_prefsBox!.isOpen) {
      await initialize();
    }
  }


  static const String _localeKey = 'app_locale';

  Future<void> setLocalePreference(String localeCode) async {
    await _ensureInitialized();
    await _prefsBox!.put(_localeKey, localeCode);
  }

  Future<String> getLocalePreference() async {
    await _ensureInitialized();
    return _prefsBox!.get(_localeKey, defaultValue: 'en_US');
  }
}