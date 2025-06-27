// lib/providers/task_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Controls whether completed tasks are shown
final showCompletedTasksProvider = StateProvider<bool>((ref) => false);