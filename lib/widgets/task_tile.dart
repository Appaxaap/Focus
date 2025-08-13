import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/task_models.dart';
import '../providers/task_provider.dart';
import '../screens/task_edit_screen.dart';

class TaskTile extends ConsumerStatefulWidget {
  final Task task;

  const TaskTile({super.key, required this.task});

  @override
  ConsumerState<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<TaskTile> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Check every minute if task becomes overdue
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted &&
          widget.task.dueDate != null &&
          !widget.task.isCompleted &&
          widget.task.dueDate!.isBefore(DateTime.now())) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isOverdue =
        widget.task.dueDate != null &&
        widget.task.dueDate!.isBefore(DateTime.now()) &&
        !widget.task.isCompleted;

    final isDueSoon =
        widget.task.dueDate != null &&
        !widget.task.isCompleted &&
        !isOverdue &&
        widget.task.dueDate!.difference(DateTime.now()).inMinutes <= 60;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskEditScreen(task: widget.task),
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
                ? colorScheme.error.withOpacity(0.3)
                : colorScheme.outline.withOpacity(0.4),
            width: isOverdue ? 1.5 : 1.0,
          ),
          boxShadow: isOverdue
              ? [
                  BoxShadow(
                    color: colorScheme.error.withOpacity(0.1),
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
            // First row: Checkbox and Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Checkbox
                GestureDetector(
                  onTap: () {
                    ref
                        .read(taskProvider.notifier)
                        .toggleTaskCompletion(widget.task.id);
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.task.isCompleted
                          ? colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.task.isCompleted
                            ? colorScheme.primary
                            : isOverdue
                            ? colorScheme.error
                            : colorScheme.outline,
                        width: 1.5,
                      ),
                    ),
                    child: widget.task.isCompleted
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
                    widget.task.title,
                    style: textTheme.bodyMedium?.copyWith(
                      color: widget.task.isCompleted
                          ? colorScheme.onSurface.withOpacity(0.5)
                          : isOverdue
                          ? colorScheme.error
                          : colorScheme.onSurface,
                      fontWeight: widget.task.isCompleted
                          ? FontWeight.normal
                          : FontWeight.w600,
                      decoration: widget.task.isCompleted
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
            if (widget.task.notes != null && widget.task.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  widget.task.notes!,
                  style: textTheme.bodySmall?.copyWith(
                    color: isOverdue
                        ? colorScheme.error.withOpacity(0.8)
                        : colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Third row: Due Date and Time (if available)
            if (widget.task.dueDate != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: _buildDateTimeChip(
                  context,
                  widget.task.dueDate!,
                  isOverdue,
                  isDueSoon,
                ),
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
    bool isDueSoon,
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

    Color chipColor;
    Color textColor;
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
              ? colorScheme.error.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              dateText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isDueSoon) ...[
            const SizedBox(width: 4),
            Text(
              '• Due soon',
              style: theme.textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
