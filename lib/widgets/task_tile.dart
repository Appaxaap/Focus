import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/quadrant_enum.dart';
import '../models/task_models.dart';
import '../providers/task_provider.dart';
import '../screens/desktop_task_edit_screen.dart';
import '../screens/task_edit_screen.dart';

class TaskTile extends ConsumerWidget {
  final Task task;

  const TaskTile({super.key, required this.task});

  void _showUndoDeleteSnackbar(BuildContext context, WidgetRef ref, Task task) {
    // Optimistically remove from state but don't delete from Hive yet
    ref.read(taskProvider.notifier).removeFromState(task.id);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        persist: false,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            ref.read(taskProvider.notifier).restoreTask(task);
            HapticFeedback.selectionClick();
          },
        ),
      ),
    );

    // When snackbar closes without undo → permanently delete from Hive
    controller.closed.then((reason) {
      if (reason != SnackBarClosedReason.action) {
        ref.read(taskProvider.notifier).commitDelete(task.id);
      }
    });
  }

  void _showSnackbar(BuildContext context, Task task, String action) {
    String message;
    if (action == 'completed') {
      switch (task.quadrant) {
        case Quadrant.urgentImportant:
          message = '✅ Urgent & important task done!';
          break;
        case Quadrant.notUrgentImportant:
          message = '🎯 Important task scheduled!';
          break;
        case Quadrant.urgentNotImportant:
          message = '🤝 Delegated an urgent task!';
          break;
        case Quadrant.notUrgentNotImportant:
          message = '🗑️ Eliminated a distraction!';
          break;
      }
    } else {
      message = 'Task deleted';
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        persist: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final now = DateTime.now();
    final isOverdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(now) &&
        !task.isCompleted;

    final isDueSoon =
        task.dueDate != null &&
        !task.isCompleted &&
        !isOverdue &&
        task.dueDate!.difference(now).inMinutes <= 60;

    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    final tile = GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => isDesktop
                ? DesktopTaskEditScreen(task: task)
                : TaskEditScreen(task: task),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOverdue
                ? colorScheme.error.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.4),
            width: isOverdue ? 1.5 : 1.0,
          ),
          boxShadow: isOverdue
              ? [
                  BoxShadow(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    ref
                        .read(taskProvider.notifier)
                        .toggleTaskCompletion(task.id);
                    if (!isDesktop) {
                      HapticFeedback.lightImpact();
                      _showSnackbar(context, task, 'completed');
                    }
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted
                          ? colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: task.isCompleted
                            ? colorScheme.primary
                            : isOverdue
                            ? colorScheme.error
                            : colorScheme.outline,
                        width: 1.5,
                      ),
                    ),
                    child: task.isCompleted
                        ? Icon(
                            Icons.check,
                            color: colorScheme.onPrimary,
                            size: 12,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: textTheme.bodyMedium?.copyWith(
                      color: task.isCompleted
                          ? colorScheme.onSurface.withValues(alpha: 0.5)
                          : isOverdue
                          ? colorScheme.error
                          : colorScheme.onSurface,
                      fontWeight: task.isCompleted
                          ? FontWeight.normal
                          : FontWeight.w600,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: colorScheme.onSurface.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (task.notes != null && task.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  task.notes!,
                  style: textTheme.bodySmall?.copyWith(
                    color: isOverdue
                        ? colorScheme.error.withValues(alpha: 0.8)
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (task.dueDate != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: _buildDateTimeChip(
                  context,
                  task.dueDate!,
                  isOverdue,
                  isDueSoon,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isDesktop) {
      return tile;
    }

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Colors.green.shade100,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(Icons.check, color: Colors.green.shade700),
      ),
      secondaryBackground: Container(
        color: Colors.red.shade100,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.red.shade700),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          ref.read(taskProvider.notifier).toggleTaskCompletion(task.id);
          HapticFeedback.lightImpact();
          _showSnackbar(context, task, 'completed');
        } else if (direction == DismissDirection.endToStart) {
          HapticFeedback.mediumImpact();
          _showUndoDeleteSnackbar(context, ref, task);
        }
      },
      child: tile,
    );
  }

  Widget _buildDateTimeChip(
    BuildContext context,
    DateTime dueDate,
    bool isOverdue,
    bool isDueSoon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasTime = dueDate.hour != 0 || dueDate.minute != 0;
    String dateText = hasTime
        ? '${DateFormat('MMM d').format(dueDate)} at ${DateFormat('h:mm a').format(dueDate)}'
        : DateFormat('MMM d').format(dueDate);

    Color chipColor, textColor;
    IconData icon;

    if (isOverdue) {
      chipColor = colorScheme.errorContainer;
      textColor = colorScheme.error;
      icon = Icons.warning_amber_rounded;
    } else if (isDueSoon) {
      chipColor = colorScheme.tertiaryContainer;
      textColor = colorScheme.onTertiaryContainer;
      icon = Icons.timer_outlined;
    } else {
      chipColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
      icon = hasTime ? Icons.access_time : Icons.calendar_today;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOverdue
              ? colorScheme.error.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              isDueSoon ? '$dateText • Due soon' : dateText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
