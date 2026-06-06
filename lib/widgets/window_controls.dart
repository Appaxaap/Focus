import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowControls extends StatelessWidget {
  final ColorScheme colorScheme;

  const WindowControls({super.key, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          type: _WindowButtonType.close,
          onPressed: () => windowManager.close(),
        ),
        const SizedBox(width: 6),
        _WindowButton(
          type: _WindowButtonType.minimize,
          onPressed: () => windowManager.minimize(),
        ),
        const SizedBox(width: 6),
        _WindowButton(
          type: _WindowButtonType.maximize,
          onPressed: () => _toggleMaximize(),
        ),
      ],
    );
  }

  Future<void> _toggleMaximize() async {
    final isMaximized = await windowManager.isMaximized();
    if (isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }
}

enum _WindowButtonType { close, minimize, maximize }

class _WindowButton extends StatefulWidget {
  final _WindowButtonType type;
  final VoidCallback onPressed;

  const _WindowButton({
    required this.type,
    required this.onPressed,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  Color get _baseColor {
    switch (widget.type) {
      case _WindowButtonType.close:
        return const Color(0xFFFF5F57);
      case _WindowButtonType.minimize:
        return const Color(0xFFFFBD2E);
      case _WindowButtonType.maximize:
        return const Color(0xFF28C840);
    }
  }

  Color get _color {
    return _baseColor.withValues(alpha: 0.55);
  }

  IconData get _icon {
    switch (widget.type) {
      case _WindowButtonType.close:
        return Icons.close_rounded;
      case _WindowButtonType.minimize:
        return Icons.remove_rounded;
      case _WindowButtonType.maximize:
        return Icons.open_in_full_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _hovered
                ? _baseColor.withValues(alpha: 0.9)
                : _color,
            shape: BoxShape.circle,
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: _hovered ? 1 : 0,
            child: Center(
              child: Icon(
                _icon,
                size: 8,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
