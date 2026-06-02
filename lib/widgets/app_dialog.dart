import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A consistent animated dialog used across the entire app.
/// Shows a scale-in animation with rounded corners and theme-aware colors.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 350),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: const Cubic(0.05, 0.7, 0.1, 1.0),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: child,
        ),
        child: builder(context),
      ),
    ),
  );
}

class AppDialogContainer extends StatelessWidget {
  final Widget child;

  const AppDialogContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AppDialogButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool isDestructive;
  final VoidCallback onTap;

  const AppDialogButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = isDestructive
        ? Colors.red.shade600
        : isPrimary
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest;

    final textColor = (isDestructive || isPrimary)
        ? Colors.white
        : colorScheme.onSurface;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
