import 'package:flutter/material.dart';
import '../models/quadrant_enum.dart';

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

Color _getContainerBackgroundColor(BuildContext context) {
  final baseColor = const Color(0xFF232323);
  if (Theme.of(context).brightness == Brightness.dark) {
    return baseColor.withAlpha((255 * 0.4).toInt());
  } else {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }
}

Color _getIconColor(BuildContext context) {
  final baseColor = const Color(0xFF6C7B7F);
  if (Theme.of(context).brightness == Brightness.dark) {
    return baseColor.withAlpha((255 * 0.6).toInt());
  } else {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

class QuadrantSelector extends StatefulWidget {
  final Quadrant? initialQuadrant;
  final ValueChanged<Quadrant?>? onQuadrantSelected;
  final AnimationController? animationController;

  const QuadrantSelector({
    this.initialQuadrant,
    this.onQuadrantSelected,
    this.animationController,
    super.key,
  });

  @override
  State<QuadrantSelector> createState() => _QuadrantSelectorState();
}

class _QuadrantSelectorState extends State<QuadrantSelector>
    with TickerProviderStateMixin {
  late Quadrant? _selectedQuadrant;
  late AnimationController _animationController;
  bool _ownAnimationController = false;

  @override
  void initState() {
    super.initState();
    _selectedQuadrant = widget.initialQuadrant;

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
                    widget.onQuadrantSelected?.call(quadrant);

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
                            ? 15
                            : 40,
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
