import 'dart:io';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/task_models.dart';

class AppBadgeService {
  static bool _badgeUnavailable = false;

  Future<void> syncBadge({
    required List<Task> tasks,
    required bool enabled,
  }) async {
    // Hard-stop on unsupported platforms (Android in this app).
    // Do not call plugin methods at all.
    if (!_supportsBadges) return;

    if (!enabled || _badgeUnavailable) {
      await _clearBadge();
      return;
    }

    final dueCount = _getDueTaskCount(tasks);
    if (dueCount <= 0) {
      await _clearBadge();
      return;
    }

    await _setBadgeCount(dueCount);
  }

  int _getDueTaskCount(List<Task> tasks) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return tasks
        .where(
          (task) =>
              !task.isCompleted &&
              task.dueDate != null &&
              !task.dueDate!.isAfter(endOfToday),
        )
        .length;
  }

  Future<void> _setBadgeCount(int count) async {
    if (_badgeUnavailable) return;
    try {
      await AppBadgePlus.updateBadge(count);
    } catch (e) {
      _badgeUnavailable = true;
      debugPrint('Badge updates disabled for this session: $e');
    }
  }

  Future<void> _clearBadge() async {
    if (_badgeUnavailable) return;
    try {
      await AppBadgePlus.updateBadge(0);
    } catch (e) {
      _badgeUnavailable = true;
      debugPrint('Badge updates disabled for this session: $e');
    }
  }

  bool get _supportsBadges => !kIsWeb && Platform.isIOS;
}
