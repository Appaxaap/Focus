// quadrant_buttons.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // If needed for providers later
import '../models/quadrant_enum.dart'; // Adjust path as needed

// Define the quadrant information map directly in this file or pass it as needed.
// For self-contained widgets, defining it here is often good.
final Map<Quadrant, Map<String, dynamic>> quadrantInfo = {
  Quadrant.urgentImportant: {
    'color': const Color(0xFFFF4557),
    'icon': Icons.priority_high,
    'title': 'Urgent',
  },
  Quadrant.notUrgentImportant: {
    'color': const Color(0xFF2DD575),
    'icon': Icons.schedule,
    'title': 'Schedule',
  },
  Quadrant.urgentNotImportant: {
    'color': const Color(0xFFFCA72A),
    'icon': Icons.person_add,
    'title': 'Delegate',
  },
  Quadrant.notUrgentNotImportant: {
    'color': const Color(0xFF747D8E),
    'icon': Icons.remove_circle_outline,
    'title': 'Eliminate',
  },
};

// Helper methods (if needed by this widget and not passed in)
// You might need to decide if these should be passed in or defined here.
// For now, let's define them here for self-containment.
// Note: These require a BuildContext, so they are functions, not constants.
Color _getContainerBackgroundColor(BuildContext context) {
  final baseColor = const Color(0xFF232323);
  if (Theme.of(context).brightness == Brightness.dark) {
    return baseColor.withAlpha((255 * 0.4).toInt()); // 40% opacity
  } else {
    return Theme.of(context).colorScheme.surfaceVariant;
  }
}

Color _getIconColor(BuildContext context) {
  final baseColor = const Color(0xFF6C7B7F);
  if (Theme.of(context).brightness == Brightness.dark) {
    return baseColor.withAlpha((255 * 0.6).toInt()); // 60% opacity
  } else {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

class QuadrantSelector extends ConsumerStatefulWidget {
  final Quadrant? initialQuadrant;
  final ValueChanged<Quadrant?>? onQuadrantSelected; // Callback for selection
  final AnimationController?
  animationController; // Optional external controller

  const QuadrantSelector({
    Key? key,
    this.initialQuadrant,
    this.onQuadrantSelected,
    this.animationController,
  }) : super(key: key);

  @override
  ConsumerState<QuadrantSelector> createState() => _QuadrantSelectorState();
}

class _QuadrantSelectorState extends ConsumerState<QuadrantSelector>
    with TickerProviderStateMixin {
  late Quadrant? _selectedQuadrant;
  late AnimationController _animationController;
  bool _ownAnimationController = false;

  @override
  void initState() {
    super.initState();
    _selectedQuadrant = widget.initialQuadrant;

    // Use provided controller or create our own
    if (widget.animationController != null) {
      _animationController = widget.animationController!;
    } else {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _ownAnimationController = true;
    }
  }

  @override
  void dispose() {
    if (_ownAnimationController) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          Quadrant.values.map((quadrant) {
            final info = quadrantInfo[quadrant]!;
            final isSelected = _selectedQuadrant == quadrant;
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, _) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedQuadrant = quadrant;
                    });
                    widget.onQuadrantSelected?.call(quadrant); // Notify parent

                    if (isSelected) {
                      _animationController.forward().then((_) {
                        _animationController.reverse();
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 88,
                    height: 74,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? info['color']
                              : _getContainerBackgroundColor(context),
                      borderRadius: BorderRadius.circular(
                        isSelected && _animationController.value > 0
                            ? 40 - (25 * _animationController.value)
                            : isSelected
                            ? 15 // Selected state: 15px corners
                            : 40, // Unselected state: 40px corners
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        info['icon'],
                        color:
                            isSelected ? Colors.white : _getIconColor(context),
                        size: 24,
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
    );
  }
}
