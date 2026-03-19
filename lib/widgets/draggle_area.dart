import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class DraggableArea extends StatelessWidget {
  final Widget child;
  final double height;
  final Color? backgroundColor;

  const DraggableArea({
    super.key,
    required this.child,
    this.height = 72,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: backgroundColor ?? Colors.transparent,
      child: Stack(
        children: [
          // Draggable region (invisible)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (_) => windowManager.startDragging(),
              onDoubleTap: () async {
                bool isMaximized = await windowManager.isMaximized();
                if (isMaximized) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // Actual content
          child,
        ],
      ),
    );
  }
}