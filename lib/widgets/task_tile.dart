import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_models.dart';
import '../providers/task_provider.dart';
import '../screens/task_edit_screen.dart';

class TaskTile extends ConsumerWidget {
  final Task task;

  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isOverdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskEditScreen(task: task)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // First row: Checkbox and Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Checkbox
                GestureDetector(
                  onTap: () {
                    ref
                        .read(taskProvider.notifier)
                        .toggleTaskCompletion(task.id);
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          task.isCompleted
                              ? colorScheme.primary
                              : Colors.transparent,
                      border: Border.all(
                        color:
                            task.isCompleted
                                ? colorScheme.primary
                                : colorScheme.outline,
                        width: 1.5,
                      ),
                    ),
                    child:
                        task.isCompleted
                            ? Icon(
                              Icons.check,
                              color: colorScheme.onPrimary,
                              size: 12,
                            )
                            : null,
                  ),
                ),

                const SizedBox(width: 12),

                // Task Title
                Expanded(
                  child: Text(
                    task.title,
                    style: textTheme.bodyMedium?.copyWith(
                      color:
                          task.isCompleted
                              ? colorScheme.onSurface.withOpacity(0.5)
                              : colorScheme.onSurface,
                      fontWeight:
                          task.isCompleted
                              ? FontWeight.normal
                              : FontWeight.w600,
                      decoration:
                          task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                      decorationColor: colorScheme.onSurface.withOpacity(0.4),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Second row: Notes (if available)
            if (task.notes != null && task.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  task.notes!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Third row: Due Date and Time (if available)
            if (task.dueDate != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: _buildDateTimeChip(context, task.dueDate!, isOverdue),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeChip(
    BuildContext context,
    DateTime dueDate,
    bool isOverdue,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check if the time is meaningful (not just midnight)
    final hasTime = dueDate.hour != 0 || dueDate.minute != 0;

    String dateText;
    if (hasTime) {
      // Format with both date and time
      dateText =
          '${DateFormat('MMM d').format(dueDate)} at ${DateFormat('h:mm a').format(dueDate)}';
    } else {
      // Format with just date
      dateText = DateFormat('MMM d').format(dueDate);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isOverdue
                ? colorScheme.errorContainer
                : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              isOverdue
                  ? colorScheme.error.withOpacity(0.3)
                  : colorScheme.outline.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasTime ? Icons.access_time : Icons.calendar_today,
            size: 12,
            color: isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              dateText,
              style: theme.textTheme.labelSmall?.copyWith(
                color:
                    isOverdue
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
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
