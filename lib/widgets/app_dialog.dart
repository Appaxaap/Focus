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
        duration: const Duration(milliseconds: 160),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
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
    final isDark = colorScheme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.35)
              : colorScheme.outlineVariant.withValues(alpha: 0.55),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.14),
            blurRadius: isDark ? 24 : 20,
            offset: const Offset(0, 10),
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
    final isDark = colorScheme.brightness == Brightness.dark;

    final bgColor = isDestructive
        ? Colors.red.shade600
        : isPrimary
        ? colorScheme.primary
        : (isDark
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surfaceContainerHigh);

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

class AppDialogTitle extends StatelessWidget {
  final String text;

  const AppDialogTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }
}

class AppDialogMessage extends StatelessWidget {
  final String text;

  const AppDialogMessage(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }
}
