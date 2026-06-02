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
  Box<Object?>? _prefsBox;
  Future<void>? _initializationFuture;

  // Preference keys
  static const String _showCompletedKey = 'show_completed';
  static const String _themeModeKey = 'theme_mode';
  static const String _themeKey = 'app_theme';
  static const String _localeKey = 'app_locale';
  static const String _quadrantNamesKey = 'quadrant_names';
  static const String _appIconBadgeEnabledKey = 'app_icon_badge_enabled';
  static const String _reducedMotionKey = 'reduced_motion';
  static const String _compactDensityKey = 'compact_density';

  static const String _sunriseTimestampKey = 'sunrise_timestamp';

  Future<void> initialize() async {
    if (_initializationFuture != null) {
      await _initializationFuture;
      return;
    }
    _initializationFuture = _initializeInternal();
    try {
      await _initializationFuture;
    } finally {
      _initializationFuture = null;
    }
  }

  Future<void> _initializeInternal() async {
    if (!Hive.isAdapterRegistered(TaskAdapter().typeId)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(QuadrantAdapter().typeId)) {
      Hive.registerAdapter(QuadrantAdapter());
    }

    if (_taskBox == null || !_taskBox!.isOpen) {
      _taskBox = await Hive.openBox<Task>(_taskBoxName);
    }
    if (_prefsBox == null || !_prefsBox!.isOpen) {
      _prefsBox = await Hive.openBox<Object?>(_prefsBoxName);
    }
  }

  Future<void> saveQuadrantNames(Map<String, String> names) async {
    await _ensureInitialized();
    final storableMap = names.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    await _prefsBox!.put(_quadrantNamesKey, storableMap);
  }

  // Gets the last saved timestamp for when the sunrise screen was shown.
  Future<int> getLastSunriseTimestamp() async {
    await _ensureInitialized();
    // Reads the timestamp from your preferences box. Defaults to 0 if not found.
    return _getPref<int>(_sunriseTimestampKey) ?? 0;
  }

  // Saves the current time as the last shown timestamp for the sunrise screen.
  Future<void> saveSunriseTimestamp() async {
    await _ensureInitialized();
    // Writes the current time to your preferences box.
    await _prefsBox!.put(
      _sunriseTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
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

  Future<void> upsertTasks(List<Task> tasks) async {
    if (tasks.isEmpty) return;
    await _ensureInitialized();
    final map = <String, Task>{for (final task in tasks) task.id: task};
    await _taskBox!.putAll(map);
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
      if (_taskBox?.isOpen == true) await _taskBox!.close();
      if (_prefsBox?.isOpen == true) await _prefsBox!.close();
      _taskBox = null;
      _prefsBox = null;

      final tasksBox = await Hive.openBox<Task>(_taskBoxName);
      await tasksBox.clear();
      await tasksBox.close();

      final prefsBox = await Hive.openBox<Object?>(_prefsBoxName);
      await prefsBox.clear();
      await prefsBox.close();

      await Hive.deleteBoxFromDisk(_taskBoxName);
      await Hive.deleteBoxFromDisk(_prefsBoxName);
      await initialize();

      debugPrint('All Hive data cleared successfully');
    } catch (e, stackTrace) {
      debugPrint('Error clearing Hive data: $e\n$stackTrace');
      rethrow;
    }
  }

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
    return jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
    });
  }

  Future<void> importData(List<Map<String, dynamic>> jsonList) async {
    await _ensureInitialized();
    final existing = _taskBox!.values.toList();
    final imported = <Task>[];

    for (final json in jsonList) {
      try {
        imported.add(Task.fromJson(json));
      } catch (e) {
        throw FormatException('Invalid task in import payload: $e');
      }
    }
    final toStore = <String, Task>{for (final task in imported) task.id: task};
    try {
      await _taskBox!.clear();
      await _taskBox!.putAll(toStore);
    } catch (e) {
      final rollback = <String, Task>{
        for (final task in existing) task.id: task,
      };
      await _taskBox!.clear();
      await _taskBox!.putAll(rollback);
      rethrow;
    }
  }

  // Preferences operations
  Future<void> setShowCompletedPreference(bool value) async {
    await _ensureInitialized();
    await _prefsBox!.put(_showCompletedKey, value);
  }

  Future<bool> getShowCompletedPreference() async {
    await _ensureInitialized();
    return _getPref<bool>(_showCompletedKey) ?? false;
  }

  Future<void> setThemeMode(String value) async {
    await _ensureInitialized();
    await _prefsBox!.put(_themeModeKey, value);
  }

  Future<String> getThemeMode() async {
    await _ensureInitialized();
    return _getPref<String>(_themeModeKey) ?? 'light';
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
    if (_taskBox == null ||
        _prefsBox == null ||
        !_taskBox!.isOpen ||
        !_prefsBox!.isOpen) {
      await initialize();
    }
  }

  Future<void> setLocalePreference(String localeCode) async {
    await _ensureInitialized();
    await _prefsBox!.put(_localeKey, localeCode);
  }

  Future<String> getLocalePreference() async {
    await _ensureInitialized();
    return _getPref<String>(_localeKey) ?? 'en_US';
  }

  Future<void> setAppIconBadgeEnabledPreference(bool value) async {
    await _ensureInitialized();
    await _prefsBox!.put(_appIconBadgeEnabledKey, value);
  }

  Future<bool> getAppIconBadgeEnabledPreference() async {
    await _ensureInitialized();
    return _getPref<bool>(_appIconBadgeEnabledKey) ?? true;
  }

  Future<void> setReducedMotionPreference(bool value) async {
    await _ensureInitialized();
    await _prefsBox!.put(_reducedMotionKey, value);
  }

  Future<bool> getReducedMotionPreference() async {
    await _ensureInitialized();
    return _getPref<bool>(_reducedMotionKey) ?? false;
  }

  Future<void> setCompactDensityPreference(bool value) async {
    await _ensureInitialized();
    await _prefsBox!.put(_compactDensityKey, value);
  }

  Future<bool> getCompactDensityPreference() async {
    await _ensureInitialized();
    return _getPref<bool>(_compactDensityKey) ?? false;
  }

  T? _getPref<T>(String key) {
    final value = _prefsBox!.get(key);
    return value is T ? value : null;
  }
}
