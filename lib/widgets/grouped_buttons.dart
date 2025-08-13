import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/home_screen.dart';

// Add provider for tracking which button is active
enum ActiveButton { none, list, filter, settings }

final activeButtonProvider = StateProvider<ActiveButton>(
  (ref) => ActiveButton.none,
);

class GroupedButtons extends ConsumerWidget {
  final ViewMode viewMode;
  final Future<void> Function() onFilterPressed;
  final Future<void> Function() onSettingsPressed;

  const GroupedButtons({
    super.key,
    required this.viewMode,
    required this.onFilterPressed,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeButton = ref.watch(activeButtonProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left Button (List/Grid Toggle)
        _CustomIconButton(
          onPressed: () {
            final newMode = viewMode == ViewMode.card
                ? ViewMode.list
                : ViewMode.card;
            ref.read(viewModeProvider.notifier).state = newMode;

            if (activeButton == ActiveButton.list) {
              ref.read(activeButtonProvider.notifier).state = ActiveButton.none;
            } else {
              ref.read(activeButtonProvider.notifier).state = ActiveButton.list;
            }
            HapticFeedback.selectionClick();
          },
          icon: Icon(
            viewMode == ViewMode.card
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded,
            color: colorScheme.onSurface,
          ),
          borderRadius: activeButton == ActiveButton.list
              ? BorderRadius.circular(40)
              : const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  bottomLeft: Radius.circular(40),
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
          isActive: activeButton == ActiveButton.list,
          colorScheme: colorScheme,
        ),

        const SizedBox(width: 2),

        // Center Button (Filter)
        _CustomIconButton(
          onPressed: () async {
            // Set filter as active
            ref.read(activeButtonProvider.notifier).state = ActiveButton.filter;

            try {
              await onFilterPressed(); // await actual dialog Future
            } finally {
              // Reset active state after dialog closed
              ref.read(activeButtonProvider.notifier).state = ActiveButton.none;
            }
          },
          icon: Icon(Icons.filter_list_rounded, color: colorScheme.onSurface),
          borderRadius: activeButton == ActiveButton.filter
              ? BorderRadius.circular(40)
              : BorderRadius.circular(4),
          isActive: activeButton == ActiveButton.filter,
          colorScheme: colorScheme,
        ),

        const SizedBox(width: 2),

        // Right Button (Settings)
        _CustomIconButton(
          onPressed: () async {
            // Set settings as active
            ref.read(activeButtonProvider.notifier).state =
                ActiveButton.settings;

            try {
              await onSettingsPressed(); // await actual bottom sheet Future
            } finally {
              // Reset active state after sheet closed
              ref.read(activeButtonProvider.notifier).state = ActiveButton.none;
            }
          },
          icon: Icon(Icons.settings, color: colorScheme.onSurface),
          borderRadius: activeButton == ActiveButton.settings
              ? BorderRadius.circular(40)
              : const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                  topRight: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
          isActive: activeButton == ActiveButton.settings,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _CustomIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final BorderRadius borderRadius;
  final bool isActive;
  final ColorScheme colorScheme;

  const _CustomIconButton({
    required this.onPressed,
    required this.icon,
    required this.borderRadius,
    required this.isActive,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHigh,
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius,
          child: Container(padding: const EdgeInsets.all(12), child: icon),
        ),
      ),
    );
  }
}
