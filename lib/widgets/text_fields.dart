import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Helper methods
Color getTextFieldBackgroundColor(BuildContext context) {
  final baseColor = const Color(0xFF313439);
  if (Theme.of(context).brightness == Brightness.dark) {
    return baseColor.withAlpha((255 * 0.3).toInt()); // 60% opacity
  } else {
    return Theme.of(context).colorScheme.surface;
  }
}

Color getContainerBackgroundColor(BuildContext context) {
  final baseColor = const Color(0xFF232323);
  if (Theme.of(context).brightness == Brightness.dark) {
    return baseColor.withAlpha((255 * 0.4).toInt()); // 40% opacity
  } else {
    return Theme.of(context).colorScheme.surfaceVariant;
  }
}

Color getIconColor(BuildContext context) {
  final baseColor = const Color(0xFF6C7B7F);
  if (Theme.of(context).brightness == Brightness.dark) {
    return baseColor.withAlpha((255 * 0.6).toInt()); // 60% opacity
  } else {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

// 1️⃣ Custom Title Text Field
class CustomTitleTextField extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  const CustomTitleTextField({
    Key? key,
    required this.controller,
    required this.colorScheme,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 68,
      decoration: BoxDecoration(
        color: getContainerBackgroundColor(context),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            margin: const EdgeInsets.all(6.5),
            decoration: BoxDecoration(
              color: getTextFieldBackgroundColor(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(27),
                bottomLeft: Radius.circular(27),
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Icon(Icons.edit, color: getIconColor(context), size: 20),
          ),
          Expanded(
            child: Container(
              height: 55,
              margin: const EdgeInsets.only(top: 6.5, bottom: 6.5, right: 6.5),
              decoration: BoxDecoration(
                color: getTextFieldBackgroundColor(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                  topRight: Radius.circular(27),
                  bottomRight: Radius.circular(27),
                ),
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Enter task title...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 2️⃣ Custom Notes Text Field
class CustomNotesTextField extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colorScheme;

  const CustomNotesTextField({
    Key? key,
    required this.controller,
    required this.colorScheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.3, // 30% of screen height
      decoration: BoxDecoration(
        color: getContainerBackgroundColor(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 55,
            height: 55,
            margin: const EdgeInsets.all(6.5),
            decoration: BoxDecoration(
              color: getTextFieldBackgroundColor(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(27),
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Icon(Icons.edit, color: getIconColor(context), size: 20),
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              margin: const EdgeInsets.only(top: 6.5, bottom: 6.5, right: 6.5),
              decoration: BoxDecoration(
                color: getTextFieldBackgroundColor(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                  topRight: Radius.circular(27),
                  bottomRight: Radius.circular(27),
                ),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Add notes or description',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 3️⃣ Custom DateTime Field
class CustomDateTimeField extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final VoidCallback? onClear;

  const CustomDateTimeField({
    Key? key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onTap,
    required this.colorScheme,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 68,
        decoration: BoxDecoration(
          color: getContainerBackgroundColor(context),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              margin: const EdgeInsets.all(6.5),
              decoration: BoxDecoration(
                color: getTextFieldBackgroundColor(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(27),
                  bottomLeft: Radius.circular(27),
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Icon(
                Icons.calendar_today,
                color: getIconColor(context),
                size: 20,
              ),
            ),
            Expanded(
              child: Container(
                height: 55,
                margin: const EdgeInsets.only(
                  top: 6.5,
                  bottom: 6.5,
                  right: 6.5,
                ),
                decoration: BoxDecoration(
                  color: getTextFieldBackgroundColor(context),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                    topRight: Radius.circular(27),
                    bottomRight: Radius.circular(27),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Text(
                    selectedDate == null
                        ? 'No due date set'
                        : DateFormat('MMM dd, yyyy').format(selectedDate!) +
                              (selectedTime != null
                                  ? ' at ${selectedTime!.format(context)}'
                                  : ''),
                    style: TextStyle(
                      color: selectedDate == null
                          ? colorScheme.onSurface.withOpacity(0.6)
                          : colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            if (selectedDate != null)
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.clear,
                    color: getIconColor(context),
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
