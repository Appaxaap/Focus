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
    return SizedBox(
      height: height,
      child: DragToMoveArea(
        child: Container(
          color: backgroundColor ?? Colors.transparent,
          child: child,
        ),
      ),
    );
  }
}
