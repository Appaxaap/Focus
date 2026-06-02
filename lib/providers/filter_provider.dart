import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TaskViewFilter { daily, weekly, monthly, all }

final filterProvider = StateProvider<TaskViewFilter>((ref) {
  return TaskViewFilter.all;
});
