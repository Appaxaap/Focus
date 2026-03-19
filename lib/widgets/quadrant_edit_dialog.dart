import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quadrant_enum.dart';
import '../providers/quadrant_names_provider.dart';

class QuadrantEditDialog extends ConsumerWidget {
  final Quadrant quadrant;
  final String currentName;

  const QuadrantEditDialog({
    super.key,
    required this.quadrant,
    required this.currentName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: currentName);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Rename Quadrant'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Enter new name',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              ref.read(quadrantNamesProvider.notifier)
                  .updateName(quadrant, controller.text.trim());
              Navigator.pop(context);
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}