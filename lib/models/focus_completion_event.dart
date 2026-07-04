import 'package:hive/hive.dart';

import 'quadrant_enum.dart';

part 'focus_completion_event.g.dart';

@HiveType(typeId: 1)
class FocusCompletionEvent {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String taskId;

  @HiveField(2)
  final DateTime completedAt;

  @HiveField(3)
  final Quadrant quadrantAtCompletion;

  @HiveField(4)
  final String titleSnapshot;

  const FocusCompletionEvent({
    required this.id,
    required this.taskId,
    required this.completedAt,
    required this.quadrantAtCompletion,
    required this.titleSnapshot,
  });

  FocusCompletionEvent copyWith({
    String? id,
    String? taskId,
    DateTime? completedAt,
    Quadrant? quadrantAtCompletion,
    String? titleSnapshot,
  }) {
    return FocusCompletionEvent(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      completedAt: completedAt ?? this.completedAt,
      quadrantAtCompletion: quadrantAtCompletion ?? this.quadrantAtCompletion,
      titleSnapshot: titleSnapshot ?? this.titleSnapshot,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'completedAt': completedAt.toIso8601String(),
      'quadrantAtCompletion': _quadrantToString(quadrantAtCompletion),
      'titleSnapshot': titleSnapshot,
    };
  }

  static FocusCompletionEvent fromJson(Map<String, dynamic> json) {
    return FocusCompletionEvent(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      quadrantAtCompletion: _stringToQuadrant(
        json['quadrantAtCompletion'] as String,
      ),
      titleSnapshot: json['titleSnapshot'] as String? ?? '',
    );
  }

  static String _quadrantToString(Quadrant quadrant) {
    return quadrant.toString().split('.').last;
  }

  static Quadrant _stringToQuadrant(String str) {
    return Quadrant.values.firstWhere(
      (q) => q.toString().split('.').last == str,
      orElse: () => Quadrant.urgentImportant,
    );
  }
}
