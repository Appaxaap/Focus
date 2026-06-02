import 'package:hive/hive.dart';
import 'dart:convert';
import 'quadrant_enum.dart';

part 'task_models.g.dart'; // Generated file by Hive

@HiveType(typeId: 0)
class Task {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final Quadrant quadrant;

  @HiveField(3)
  final String? notes;

  @HiveField(4)
  final DateTime? dueDate;

  @HiveField(5)
  final bool isCompleted;

  @HiveField(6)
  late final DateTime createdAt;

  @HiveField(7)
  late final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.notes,
    required this.quadrant,
    this.dueDate,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? notes,
    Quadrant? quadrant,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      quadrant: quadrant ?? this.quadrant,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts [Task] to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'quadrant': _quadrantToString(quadrant),
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Reconstructs [Task] from a JSON map
  static Task fromJson(Map<String, dynamic> json) {
    final String quadStr = json['quadrant'];
    final Quadrant quadrant = _stringToQuadrant(quadStr);

    return Task(
      id: json['id'],
      title: json['title'],
      notes: json['notes'],
      quadrant: quadrant,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Helper: Convert Quadrant enum to string
  static String _quadrantToString(Quadrant quadrant) {
    return quadrant.toString().split('.').last;
  }

  /// Helper: Convert string back to Quadrant enum
  static Quadrant _stringToQuadrant(String str) {
    return Quadrant.values.firstWhere(
      (q) => q.toString().split('.').last == str,
      orElse: () => Quadrant.urgentImportant,
    );
  }
}
