import 'package:flutter/material.dart';
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
    return GestureDetector(
      onTap: () => _navigateToAddTask(context, quadrant),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child:
            tasks.isEmpty ? _buildEmptyState(context) : _buildTaskList(tasks),
      ),
    );
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

  Widget _buildTaskList(List<Task> tasks) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: tasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskTile(task: task, key: ValueKey(task.id));
      },
    );
  }

  void _navigateToAddTask(BuildContext context, Quadrant quadrant) {
    DateTime? suggestedDueDate;
    if (quadrant == Quadrant.urgentImportant || quadrant == Quadrant.urgentNotImportant) {
      // Do First or Delegate → Today
      suggestedDueDate = DateTime.now();
    } else if (quadrant == Quadrant.notUrgentImportant) {
      // Schedule → Tomorrow
      suggestedDueDate = DateTime.now().add(const Duration(days: 1));
    }
    // Eliminate → no due date

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
