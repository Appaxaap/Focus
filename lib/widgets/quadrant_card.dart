import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quadrant_enum.dart';
import '../models/task_models.dart';
import '../screens/task_edit_screen.dart';
import '../widgets/task_tile.dart';

class QuadrantCard extends ConsumerWidget {
  final Quadrant quadrant;
  final List<Task> tasks;

  const QuadrantCard({super.key, required this.quadrant, required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return tasks.isEmpty
        ? GestureDetector(
            onTap: () => _navigateToAddTask(context, quadrant),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: _buildEmptyState(context),
            ),
          )
        : _buildTaskList(context, ref, tasks);
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: colorScheme.onSurface.withOpacity(0.4),
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Tap to add task',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, WidgetRef ref, List<Task> tasks) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: tasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return LongPressDraggable<Task>(
          data: task,
          delay: const Duration(milliseconds: 300),
          onDragStarted: () => HapticFeedback.mediumImpact(),
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.85,
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getQuadrantColor(task.quadrant).withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: TaskTile(task: task, key: ValueKey(task.id)),
          ),
          child: TaskTile(task: task, key: ValueKey(task.id)),
        );
      },
    );
  }

  Color _getQuadrantColor(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.urgentImportant:
        return const Color(0xFFFF4757);
      case Quadrant.notUrgentImportant:
        return const Color(0xFF2ED573);
      case Quadrant.urgentNotImportant:
        return const Color(0xFFFFA726);
      case Quadrant.notUrgentNotImportant:
        return const Color(0xFF747D8C);
    }
  }

  void _navigateToAddTask(BuildContext context, Quadrant quadrant) {
    DateTime? suggestedDueDate;
    if (quadrant == Quadrant.urgentImportant ||
        quadrant == Quadrant.urgentNotImportant) {
      suggestedDueDate = DateTime.now();
    } else if (quadrant == Quadrant.notUrgentImportant) {
      suggestedDueDate = DateTime.now().add(const Duration(days: 1));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEditScreen(
          initialQuadrant: quadrant,
          suggestedDueDate: suggestedDueDate,
        ),
      ),
    );
  }
}
