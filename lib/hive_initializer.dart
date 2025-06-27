import 'package:hive_flutter/hive_flutter.dart';
import 'models/task_models.dart';

class HiveInitializer {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    await Hive.openBox<Task>('tasks');
  }
}