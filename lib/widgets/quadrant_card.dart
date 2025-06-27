import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quadrant_enum.dart';
import '../models/task_models.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';

class QuadrantCard extends ConsumerWidget {
  final Quadrant quadrant;
  final List<Task> tasks;

  const QuadrantCard({
    super.key,
    required this.quadrant,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the tasks parameter that's already filtered and passed from the parent
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: tasks.isEmpty ? _buildEmptyState(context) : _buildTaskList(tasks),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt_outlined,
            color: colorScheme.onSurface.withOpacity(0.3),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'No tasks yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
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
        return TaskTile(
          task: task,
          key: ValueKey(task.id), // Add key for better performance
        );
      },
    );
  }
}