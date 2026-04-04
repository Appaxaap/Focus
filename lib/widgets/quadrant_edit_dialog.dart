import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quadrant_enum.dart';
import '../providers/quadrant_names_provider.dart';
import 'app_dialog.dart';

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
    final theme = Theme.of(context);

    return AppDialogContainer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rename Quadrant',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Enter new name',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppDialogButton(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDialogButton(
                    label: 'Save',
                    isPrimary: true,
                    onTap: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
