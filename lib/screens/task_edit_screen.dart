import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/quadrant_enum.dart';
import '../models/task_models.dart';
import '../providers/task_provider.dart';

class TaskEditScreen extends ConsumerStatefulWidget {
  final Task? task;
  final Quadrant? initialQuadrant;

  const TaskEditScreen({super.key, this.task, this.initialQuadrant});

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  late TextEditingController titleController;
  late TextEditingController notesController;
  late Quadrant? selectedQuadrant;
  late DateTime? selectedDate;
  late TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task?.title ?? '');
    notesController = TextEditingController(text: widget.task?.notes ?? '');
    selectedQuadrant = widget.task?.quadrant ?? widget.initialQuadrant;
    selectedDate = widget.task?.dueDate;
    // Extract time from existing date if available
    selectedTime =
        widget.task?.dueDate != null
            ? TimeOfDay.fromDateTime(widget.task!.dueDate!)
            : null;
  }

  @override
  void dispose() {
    titleController.dispose();
    notesController.dispose();
    super.dispose();
  }

  // Map of quadrant info for display
  Map<Quadrant, Map<String, dynamic>> get quadrantInfo => {
    Quadrant.urgentImportant: {
      'color': const Color(0xFFFF4757),
      'title': 'Do First',
      'subtitle': 'Urgent & Important',
      'icon': Icons.priority_high,
    },
    Quadrant.notUrgentImportant: {
      'color': const Color(0xFF2ED573),
      'title': 'Schedule',
      'subtitle': 'Not Urgent but Important',
      'icon': Icons.schedule,
    },
    Quadrant.urgentNotImportant: {
      'color': const Color(0xFFFFA726),
      'title': 'Delegate',
      'subtitle': 'Urgent but Not Important',
      'icon': Icons.person_add,
    },
    Quadrant.notUrgentNotImportant: {
      'color': const Color(0xFF747D8C),
      'title': 'Eliminate',
      'subtitle': 'Not Urgent & Not Important',
      'icon': Icons.remove_circle_outline,
    },
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.task != null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text(
          isEditing ? 'Edit Task' : 'New Task',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteConfirmation(context),
              color: colorScheme.error,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Text(
              'Task Title',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: titleController,
              hint: 'Enter task title...',
            ),
            const SizedBox(height: 24),

            // Priority Section
            Text(
              'Priority Quadrant',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuadrantSelector(context),
            const SizedBox(height: 24),

            // Due Date & Time Section
            Text(
              'Due Date & Time',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _buildDateTimeSelector(context),
            const SizedBox(height: 24),

            // Notes Section
            Text(
              'Notes (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: notesController,
              hint: 'Add notes or description...',
              maxLines: 4,
            ),

            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.tonal(
                onPressed: _saveTask,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing ? 'Update Task' : 'Create Task',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildQuadrantSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children:
            Quadrant.values.map((quadrant) {
              final info = quadrantInfo[quadrant]!;
              final isSelected = selectedQuadrant == quadrant;

              return InkWell(
                onTap: () => setState(() => selectedQuadrant = quadrant),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border:
                        isSelected
                            ? Border.all(color: info['color'], width: 1.5)
                            : null,
                    color: isSelected ? info['color'].withOpacity(0.1) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: info['color'],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(info['icon'], color: info['color'], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info['title'],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected
                                        ? info['color']
                                        : colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              info['subtitle'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: info['color'],
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildDateTimeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Date Selector
          InkWell(
            onTap: _selectDate,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDate == null
                          ? 'No due date set'
                          : DateFormat('MMM dd, yyyy').format(selectedDate!),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color:
                            selectedDate == null
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (selectedDate != null)
                    InkWell(
                      onTap:
                          () => setState(() {
                            selectedDate = null;
                            selectedTime = null;
                          }),
                      child: const Icon(Icons.clear, size: 20),
                    ),
                ],
              ),
            ),
          ),

          // Time Selector (only show if date is selected)
          if (selectedDate != null) ...[
            Divider(height: 1, color: colorScheme.outlineVariant),
            InkWell(
              onTap: _selectTime,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedTime == null
                            ? 'No time set'
                            : selectedTime!.format(context),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color:
                              selectedTime == null
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (selectedTime != null)
                      InkWell(
                        onTap: () => setState(() => selectedTime = null),
                        child: const Icon(Icons.clear, size: 20),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _saveTask() {
    final String title = titleController.text.trim();
    final String? notes =
        notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim();

    if (title.isEmpty) {
      _showSnackbar(context, 'Please enter a task title', isError: true);
      return;
    }

    if (selectedQuadrant == null) {
      _showSnackbar(
        context,
        'Please select a priority quadrant',
        isError: true,
      );
      return;
    }

    // Combine date and time into a single DateTime
    DateTime? finalDateTime;
    if (selectedDate != null) {
      if (selectedTime != null) {
        finalDateTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          selectedTime!.hour,
          selectedTime!.minute,
        );
      } else {
        finalDateTime = selectedDate;
      }
    }

    final newTask = Task(
      id: widget.task?.id ?? const Uuid().v4(),
      title: title,
      notes: notes,
      quadrant: selectedQuadrant!,
      dueDate: finalDateTime,
      isCompleted: widget.task?.isCompleted ?? false,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Always use updateTask which handles both new and existing tasks
    ref.read(taskProvider.notifier).updateTask(newTask);
    Navigator.pop(context);
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colorScheme.surfaceContainerHigh,
            title: Text(
              'Delete Task',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            content: Text(
              'Are you sure you want to delete this task? This action cannot be undone.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(taskProvider.notifier).deleteTask(widget.task!.id);
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close edit screen
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showSnackbar(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? colorScheme.onError : colorScheme.onPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? colorScheme.onError : colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
