import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus/providers/task_provider.dart';
import '../models/quadrant_enum.dart';
import '../models/task_models.dart';

final quadrantOrderProvider = StateProvider<List<Quadrant>>((ref) {
  return Quadrant.values; // Default order
});

final filteredTasksProvider = Provider.family<List<Task>, Quadrant>((ref, quadrant) {
  final allTasks = ref.watch(taskProvider);
  return allTasks.where((task) => task.quadrant == quadrant).toList();
});