import 'dart:io';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/task_models.dart';

class AppBadgeService {
  Future<void> syncBadge({
    required List<Task> tasks,
    required bool enabled,
  }) async {
    if (!_supportsBadges || !enabled) {
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
    try {
      await AppBadgePlus.updateBadge(count);
    } catch (_) {}
  }

  Future<void> _clearBadge() async {
    try {
      await AppBadgePlus.updateBadge(0);
    } catch (_) {}
  }

  bool get _supportsBadges => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
}
