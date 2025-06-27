import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TaskViewFilter {
  Daily,
  Weekly,
  Monthly,
  All,
}

final filterProvider = StateProvider<TaskViewFilter>((ref) {
  return TaskViewFilter.All;
});