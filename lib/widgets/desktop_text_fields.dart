import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Helper: Fluent-style container background
Color _getFluentContainerColor(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return colorScheme.surfaceContainerLow;
}

// Desktop Title Text Field (Fluent Design)
class DesktopTitleTextField extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colorScheme;

  const DesktopTitleTextField({
    super.key,
    required this.controller,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: 'Task title',
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
        hintText: 'Enter a clear, actionable title',
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
        filled: true,
        fillColor: _getFluentContainerColor(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      maxLines: 1,
    );
  }
}

// Desktop Notes Text Field (Fluent Design)
class DesktopNotesTextField extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colorScheme;

  const DesktopNotesTextField({
    super.key,
    required this.controller,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Notes (optional)',
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
        hintText: 'Add context, links, or details',
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
        filled: true,
        fillColor: _getFluentContainerColor(context),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      maxLines: 8,
      minLines: 4,
    );
  }
}

// Desktop DateTime Field (Fluent Design - Clickable Card)
class DesktopDateTimeField extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final VoidCallback? onClear;

  const DesktopDateTimeField({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onTap,
    required this.colorScheme,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = selectedDate == null
        ? 'No due date set'
        : DateFormat('EEEE, MMMM d, y').format(selectedDate!) +
              (selectedTime != null
                  ? ' at ${selectedTime!.format(context)}'
                  : '');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _getFluentContainerColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selectedDate != null
                  ? colorScheme.primary.withOpacity(0.5)
                  : colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: selectedDate != null
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due date & time',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      displayText,
                      style: TextStyle(
                        color: selectedDate != null
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant.withOpacity(0.6),
                        fontSize: 16,
                        fontWeight: selectedDate != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (selectedDate != null)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    foregroundColor: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Clear date & time',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
