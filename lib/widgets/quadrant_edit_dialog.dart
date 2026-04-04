import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quadrant_enum.dart';
import '../providers/quadrant_names_provider.dart';

class QuadrantEditDialog extends ConsumerStatefulWidget {
  final Quadrant quadrant;
  final String currentName;

  const QuadrantEditDialog({
    super.key,
    required this.quadrant,
    required this.currentName,
  });

  @override
  ConsumerState<QuadrantEditDialog> createState() => _QuadrantEditDialogState();
}

class _QuadrantEditDialogState extends ConsumerState<QuadrantEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Rename Quadrant'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: 'Enter new name',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      ref.read(quadrantNamesProvider.notifier).updateName(widget.quadrant, name);
      Navigator.pop(context);
    }
  }
}