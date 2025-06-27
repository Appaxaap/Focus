import 'dart:ui';

import 'package:hive/hive.dart';

part 'quadrant_enum.g.dart'; // Generated file by Hive

@HiveType(typeId: 1) // Unique typeId different from Task model (which uses 0)
enum Quadrant {
  @HiveField(0)
  urgentImportant,

  @HiveField(1)
  notUrgentImportant,

  @HiveField(2)
  urgentNotImportant,

  @HiveField(3)
  notUrgentNotImportant,
}

extension QuadrantExtension on Quadrant {
  /// Human-readable title for UI
  String get title {
    switch (this) {
      case Quadrant.urgentImportant:
        return 'Urgent & Important';
      case Quadrant.notUrgentImportant:
        return 'Not Urgent but Important';
      case Quadrant.urgentNotImportant:
        return 'Urgent but Not Important';
      case Quadrant.notUrgentNotImportant:
        return 'Not Urgent & Not Important';
    }
  }

  /// Short string representation, e.g., "urgentImportant"
  String get key {
    return this.toString().split('.').last;
  }

  /// Returns a color associated with each quadrant
  Color get color {
    switch (this) {
      case Quadrant.urgentImportant:
        return const Color(0xFFFF4757); // Red
      case Quadrant.notUrgentImportant:
        return const Color(0xFF2ED573); // Green
      case Quadrant.urgentNotImportant:
        return const Color(0xFFFFA726); // Orange
      case Quadrant.notUrgentNotImportant:
        return const Color(0xFF747D8C); // Gray
    }
  }

  /// Get Quadrant from its string representation
  static Quadrant fromKey(String key) {
    return Quadrant.values.firstWhere(
          (q) => q.key == key,
      orElse: () => Quadrant.urgentImportant,
    );
  }
}