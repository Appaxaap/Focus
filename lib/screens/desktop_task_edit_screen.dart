import 'dart:io';
import '../providers/quadrant_names_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import '../models/quadrant_enum.dart';
import '../models/task_models.dart';
import '../providers/task_provider.dart';
import '../widgets/app_dialog.dart';
import '../widgets/draggle_area.dart';

class SaveTaskIntent extends Intent {
  const SaveTaskIntent();
}

class CancelTaskIntent extends Intent {
  const CancelTaskIntent();
}

class ShowShortcutsIntent extends Intent {
  const ShowShortcutsIntent();
}

class ToggleQuadrantPanelIntent extends Intent {
  const ToggleQuadrantPanelIntent();
}

class CycleDateIntent extends Intent {
  const CycleDateIntent();
}

class DesktopTaskEditScreen extends ConsumerStatefulWidget {
  final Task? task;
  final Quadrant? initialQuadrant;
  final DateTime? suggestedDueDate;

  const DesktopTaskEditScreen({
    super.key,
    this.task,
    this.initialQuadrant,
    this.suggestedDueDate,
  });

  @override
  ConsumerState<DesktopTaskEditScreen> createState() =>
      _DesktopTaskEditScreenState();
}

class _DesktopTaskEditScreenState extends ConsumerState<DesktopTaskEditScreen>
{
  late TextEditingController titleController;
  late TextEditingController notesController;
  late Quadrant? selectedQuadrant;
  late DateTime? selectedDate;
  late TimeOfDay? selectedTime;

  String? _titleError;
  String? _quadrantError;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _showShortcuts = false;
  bool _isQuadrantPanelCollapsed = false;
  int _currentQuickDateIndex =
      -1; // -1 = none, 0 = today, 1 = tomorrow, 2 = next week

  BoxDecoration _glassPanel(ColorScheme colorScheme, {double radius = 16}) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return BoxDecoration(
      color: colorScheme.surface.withValues(alpha: isDark ? 0.72 : 0.90),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: colorScheme.onSurface.withValues(alpha: isDark ? 0.10 : 0.18),
        width: 0.5,
      ),
    );
  }

  // Focus nodes
  final _titleFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.task?.title ?? '');
    notesController = TextEditingController(text: widget.task?.notes ?? '');

    // Track changes
    titleController.addListener(_onContentChanged);
    notesController.addListener(_onContentChanged);

    if (widget.task == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
      });
    }

    selectedQuadrant = widget.task?.quadrant ?? widget.initialQuadrant;
    selectedDate = widget.task?.dueDate ?? widget.suggestedDueDate;
    selectedTime = widget.task?.dueDate != null
        ? TimeOfDay.fromDateTime(widget.task!.dueDate!)
        : null;

    // Auto-suggest quadrant
    if (selectedQuadrant == null && selectedDate != null) {
      final now = DateTime.now();
      final diff = selectedDate!.difference(now).inDays;
      if (diff <= 1) {
        selectedQuadrant = Quadrant.urgentImportant;
      } else if (diff <= 3) {
        selectedQuadrant = Quadrant.notUrgentImportant;
      }
    }

  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    notesController.dispose();
    _titleFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  Map<Quadrant, Map<String, dynamic>> get quadrantInfo => {
    Quadrant.urgentImportant: {
      'color': const Color(0xFFFF4757),
      'icon': Icons.local_fire_department_rounded,
      'title': 'Do',
      'subtitle': 'Critical',
      'description': 'Urgent & Important',
    },
    Quadrant.notUrgentImportant: {
      'color': const Color(0xFF2ED573),
      'icon': Icons.calendar_today_rounded,
      'title': 'Plan',
      'subtitle': 'Important',
      'description': 'Not Urgent & Important',
    },
    Quadrant.urgentNotImportant: {
      'color': const Color(0xFFFFA726),
      'icon': Icons.people_outline_rounded,
      'title': 'Delegate',
      'subtitle': 'Quick wins',
      'description': 'Urgent & Not Important',
    },
    Quadrant.notUrgentNotImportant: {
      'color': const Color(0xFF747D8C),
      'icon': Icons.remove_circle_outline_rounded,
      'title': 'Delete',
      'subtitle': 'Low priority',
      'description': 'Not Urgent & Not Important',
    },
  };

  void _validateAndSave() {
    if (_isSaving) return;

    final title = titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleError = 'Task title is required';
      });
      _titleFocusNode.requestFocus();
      return;
    }

    if (selectedQuadrant == null) {
      setState(() {
        _quadrantError = 'Please select a priority';
      });
      return;
    }

    _saveTask();
  }

  void _cycleQuickDates() {
    setState(() {
      _currentQuickDateIndex = (_currentQuickDateIndex + 1) % 4;

      switch (_currentQuickDateIndex) {
        case 0: // Today
          selectedDate = DateTime.now();
          break;
        case 1: // Tomorrow
          selectedDate = DateTime.now().add(const Duration(days: 1));
          break;
        case 2: // Next Week
          selectedDate = DateTime.now().add(const Duration(days: 7));
          break;
        case 3: // Clear
          selectedDate = null;
          selectedTime = null;
          _currentQuickDateIndex = -1;
          return;
      }

      if (selectedTime == null && selectedDate != null) {
        selectedTime = const TimeOfDay(hour: 9, minute: 0);
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialogContainer(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unsaved Changes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'You have unsaved changes. Discard them?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppDialogButton(
                      label: 'Keep Editing',
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDialogButton(
                      label: 'Discard',
                      isDestructive: true,
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return shouldPop ?? false;
  }

  Widget _buildEditorContent(
    ThemeData theme,
    ColorScheme colorScheme,
    double maxWidth,
  ) {
    final isCompact = maxWidth < 1020;
    if (isCompact) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              children: [
                _buildMainForm(theme, colorScheme),
                const SizedBox(height: 14),
                _buildQuadrantPanel(theme, colorScheme),
                const SizedBox(height: 14),
                _buildQuickDateSelector(theme, colorScheme),
                const SizedBox(height: 14),
                _buildSmartSuggestions(theme, colorScheme),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildMainForm(theme, colorScheme),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    _buildQuadrantPanel(theme, colorScheme),
                    const SizedBox(height: 16),
                    _buildQuickDateSelector(theme, colorScheme),
                    const SizedBox(height: 16),
                    _buildSmartSuggestions(theme, colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.enter, control: true):
          const SaveTaskIntent(),
      const SingleActivator(LogicalKeyboardKey.escape):
          const CancelTaskIntent(),
      const SingleActivator(LogicalKeyboardKey.slash, shift: true):
          const ShowShortcutsIntent(),
      const SingleActivator(LogicalKeyboardKey.keyQ, control: true):
          const ToggleQuadrantPanelIntent(),
      const SingleActivator(LogicalKeyboardKey.keyD, control: true):
          const CycleDateIntent(),
    };

    final actions = <Type, Action<Intent>>{
      SaveTaskIntent: CallbackAction<SaveTaskIntent>(
        onInvoke: (intent) => _validateAndSave(),
      ),
      CancelTaskIntent: CallbackAction<CancelTaskIntent>(
        onInvoke: (intent) async {
          if (await _onWillPop()) {
            Navigator.pop(context);
          }
        },
      ),
      ShowShortcutsIntent: CallbackAction<ShowShortcutsIntent>(
        onInvoke: (intent) {
          setState(() => _showShortcuts = !_showShortcuts);
        },
      ),
      ToggleQuadrantPanelIntent: CallbackAction<ToggleQuadrantPanelIntent>(
        onInvoke: (intent) {
          setState(
            () => _isQuadrantPanelCollapsed = !_isQuadrantPanelCollapsed,
          );
          HapticFeedback.lightImpact();
        },
      ),
      CycleDateIntent: CallbackAction<CycleDateIntent>(
        onInvoke: (intent) {
          _cycleQuickDates();
          HapticFeedback.selectionClick();
        },
      ),
    };

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Actions(
        actions: actions,
        child: Shortcuts(
          shortcuts: shortcuts,
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            body: Stack(
              children: [
                Column(
                  children: [
                    _buildCompactTopBar(theme, colorScheme, isEditing),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return _buildEditorContent(
                            theme,
                            colorScheme,
                            constraints.maxWidth,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (_showShortcuts) _buildShortcutsOverlay(theme, colorScheme),
                if (_isSaving) _buildLoadingOverlay(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartSuggestions(ThemeData theme, ColorScheme colorScheme) {
    if (selectedQuadrant == null && selectedDate == null)
      return const SizedBox.shrink();

    String suggestion = '';
    IconData icon = Icons.lightbulb_outline_rounded;
    Color suggestionColor = colorScheme.primary;

    if (selectedDate != null && selectedQuadrant != null) {
      final diff = selectedDate!.difference(DateTime.now()).inDays;
      final quadrantColor = quadrantInfo[selectedQuadrant]!['color'] as Color;

      if (selectedQuadrant == Quadrant.urgentImportant && diff > 3) {
        suggestion =
            'This task is due in $diff days. Consider moving to "Plan" quadrant.';
        icon = Icons.info_outline_rounded;
        suggestionColor = const Color(0xFF2ED573);
      } else if (selectedQuadrant == Quadrant.notUrgentImportant && diff <= 1) {
        suggestion = 'This task is due soon! Consider moving to "Do" quadrant.';
        icon = Icons.warning_amber_rounded;
        suggestionColor = const Color(0xFFFF4757);
      } else {
        suggestion = 'Great choice! This matches the Eisenhower Matrix.';
        icon = Icons.check_circle_outline_rounded;
        suggestionColor = quadrantColor;
      }
    } else if (selectedQuadrant != null) {
      suggestion = 'Add a due date to better prioritize this task.';
      icon = Icons.calendar_today_rounded;
    }

    if (suggestion.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: suggestionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: suggestionColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: suggestionColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              suggestion,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(ColorScheme colorScheme) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Saving task...',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutsOverlay(ThemeData theme, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => setState(() => _showShortcuts = false),
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.keyboard_rounded, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Keyboard Shortcuts',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => _showShortcuts = false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildShortcutRow('Ctrl + Enter', 'Save task'),
                _buildShortcutRow('Esc', 'Cancel'),
                _buildShortcutRow('Ctrl + Q', 'Toggle priority panel'),
                _buildShortcutRow('Ctrl + D', 'Cycle quick dates'),
                _buildShortcutRow('?', 'Show shortcuts'),
                _buildShortcutRow('Tab', 'Navigate fields'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutRow(String keys, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),

            child: Text(
              keys,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(description)),
        ],
      ),
    );
  }

  Widget _buildQuickDateSelector(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassPanel(colorScheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Quick Dates',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Ctrl+D',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickDateButton('Today', DateTime.now(), theme, colorScheme),
          const SizedBox(height: 8),
          _buildQuickDateButton(
            'Tomorrow',
            DateTime.now().add(const Duration(days: 1)),
            theme,
            colorScheme,
          ),
          const SizedBox(height: 8),
          _buildQuickDateButton(
            'Next Week',
            DateTime.now().add(const Duration(days: 7)),
            theme,
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateButton(
    String label,
    DateTime date,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isSelected =
        selectedDate != null &&
        selectedDate!.year == date.year &&
        selectedDate!.month == date.month &&
        selectedDate!.day == date.day;

    return InkWell(
      onTap: () {
        setState(() {
          selectedDate = date;
          if (selectedTime == null) {
            selectedTime = const TimeOfDay(hour: 9, minute: 0);
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTopBar(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isEditing,
  ) {
    return DraggableArea(
      height: 64,
      backgroundColor: Colors.transparent,
      child: Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.10),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(
                0.5,
              ),
              foregroundColor: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.edit_note_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Task' : 'New Task',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (_hasUnsavedChanges)
                Text(
                  'Unsaved changes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _showShortcuts = !_showShortcuts),
                      icon: const Icon(Icons.keyboard_rounded, size: 18),
                      tooltip: 'Keyboard Shortcuts (?)',
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isEditing) ...[
                      OutlinedButton.icon(
                        onPressed: () => _showDeleteConfirmation(context),
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSaving ? null : _validateAndSave,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: colorScheme.onSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isEditing ? 'Update' : 'Create',
                                style: TextStyle(
                                  color: colorScheme.onSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMainForm(ThemeData theme, ColorScheme colorScheme) {
    final titleLength = titleController.text.length;
    final maxTitleLength = 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _glassPanel(colorScheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Task Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Title',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontSize: 13,
                ),
              ),
              Text(
                '$titleLength/$maxTitleLength',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: titleLength > maxTitleLength
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            focusNode: _titleFocusNode,
            controller: titleController,
            maxLength: maxTitleLength,
            onSubmitted: (_) => _notesFocusNode.requestFocus(),
            onChanged: (_) => setState(() => _titleError = null),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'What needs to be done?',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontSize: 14,
              ),
              filled: true,
              fillColor: colorScheme.surface,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              errorText: _titleError,
              errorStyle: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                height: 1.2,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Notes',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            focusNode: _notesFocusNode,
            controller: notesController,
            maxLines: 5,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Add details, context, or notes...',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontSize: 14,
              ),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Due Date & Time',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          _buildDateTimeSelector(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _showInlineDatePicker(theme, colorScheme),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selectedDate != null
                        ? colorScheme.primary.withOpacity(0.1)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selectedDate != null
                          ? colorScheme.primary.withOpacity(0.3)
                          : colorScheme.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: selectedDate != null
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedDate != null
                            ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                            : 'Pick Date',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: selectedDate != null
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: selectedDate != null
                    ? () => _showInlineTimePicker(theme, colorScheme)
                    : null,
                borderRadius: BorderRadius.circular(10),
                child: Opacity(
                  opacity: selectedDate == null ? 0.4 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selectedTime != null
                          ? colorScheme.primary.withOpacity(0.1)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedTime != null
                            ? colorScheme.primary.withOpacity(0.3)
                            : colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: selectedTime != null
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedTime != null
                              ? selectedTime!.format(context)
                              : 'Pick Time',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: selectedTime != null
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (selectedDate != null || selectedTime != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedDate = null;
                    selectedTime = null;
                    _currentQuickDateIndex = -1;
                  });
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer.withOpacity(0.5),
                  foregroundColor: colorScheme.error,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showInlineDatePicker(ThemeData theme, ColorScheme colorScheme) {
    DateTime displayMonth = selectedDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final daysInMonth = DateUtils.getDaysInMonth(
              displayMonth.year,
              displayMonth.month,
            );
            final firstWeekday =
                DateTime(displayMonth.year, displayMonth.month, 1).weekday % 7;
            final today = DateTime.now();

            return Dialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: 320,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_monthName(displayMonth.month)} ${displayMonth.year}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => setDialogState(() {
                              displayMonth = DateTime(
                                displayMonth.year,
                                displayMonth.month - 1,
                              );
                            }),
                            icon: const Icon(Icons.chevron_left_rounded),
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(32, 32),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setDialogState(() {
                              displayMonth = DateTime(
                                displayMonth.year,
                                displayMonth.month + 1,
                              );
                            }),
                            icon: const Icon(Icons.chevron_right_rounded),
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(32, 32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                            .map(
                              (d) => SizedBox(
                                width: 36,
                                child: Center(
                                  child: Text(
                                    d,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                              childAspectRatio: 1,
                            ),
                        itemCount: firstWeekday + daysInMonth,
                        itemBuilder: (context, index) {
                          if (index < firstWeekday) return const SizedBox();
                          final day = index - firstWeekday + 1;
                          final date = DateTime(
                            displayMonth.year,
                            displayMonth.month,
                            day,
                          );
                          final isToday =
                              date.year == today.year &&
                              date.month == today.month &&
                              date.day == today.day;
                          final isSelected =
                              selectedDate != null &&
                              date.year == selectedDate!.year &&
                              date.month == selectedDate!.month &&
                              date.day == selectedDate!.day;
                          final isPast = date.isBefore(
                            DateTime(today.year, today.month, today.day),
                          );

                          return GestureDetector(
                            onTap: isPast
                                ? null
                                : () {
                                    setState(() {
                                      selectedDate = date;
                                      _currentQuickDateIndex = -1;
                                      if (selectedTime == null) {
                                        selectedTime = const TimeOfDay(
                                          hour: 9,
                                          minute: 0,
                                        );
                                      }
                                    });
                                    Navigator.pop(context);
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : isToday
                                    ? colorScheme.primary.withOpacity(0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '$day',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isPast
                                        ? colorScheme.onSurfaceVariant
                                              .withOpacity(0.3)
                                        : isSelected
                                        ? colorScheme.onPrimary
                                        : isToday
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showInlineTimePicker(ThemeData theme, ColorScheme colorScheme) {
    int hour = selectedTime?.hour ?? 9;
    int minute = selectedTime?.minute ?? 0;
    bool isAm = hour < 12;
    int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: 280,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select time',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _timeSpinner(
                            value: displayHour,
                            min: 1,
                            max: 12,
                            onChanged: (v) => setDialogState(() {
                              displayHour = v;
                              hour = isAm
                                  ? (v == 12 ? 0 : v)
                                  : (v == 12 ? 12 : v + 12);
                            }),
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              ':',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w300,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          _timeSpinner(
                            value: minute,
                            min: 0,
                            max: 59,
                            padZero: true,
                            step: 1,
                            onChanged: (v) => setDialogState(() => minute = v),
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            children: [
                              _amPmButton(
                                label: 'AM',
                                selected: isAm,
                                onTap: () => setDialogState(() {
                                  isAm = true;
                                  hour = displayHour == 12 ? 0 : displayHour;
                                }),
                                theme: theme,
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 6),
                              _amPmButton(
                                label: 'PM',
                                selected: !isAm,
                                onTap: () => setDialogState(() {
                                  isAm = false;
                                  hour = displayHour == 12
                                      ? 12
                                      : displayHour + 12;
                                }),
                                theme: theme,
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                selectedTime = TimeOfDay(
                                  hour: hour,
                                  minute: minute,
                                );
                              });
                              Navigator.pop(context);
                            },
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _timeSpinner({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    required ThemeData theme,
    required ColorScheme colorScheme,
    bool padZero = false,
    int step = 1,
  }) {
    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              int next = value + step;
              if (next > max) next = min;
              onChanged(next);
            },
            icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
            padding: const EdgeInsets.symmetric(vertical: 4),
            constraints: const BoxConstraints(),
          ),
          Text(
            padZero ? value.toString().padLeft(2, '0') : value.toString(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: () {
              int next = value - step;
              if (next < min) next = max;
              onChanged(next);
            },
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            padding: const EdgeInsets.symmetric(vertical: 4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _amPmButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildQuadrantPanel(ThemeData theme, ColorScheme colorScheme) {
    final quadrantNames = ref.watch(quadrantNamesProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(24),
      decoration: _glassPanel(colorScheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Priority',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Ctrl+Q',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(
                    () =>
                        _isQuadrantPanelCollapsed = !_isQuadrantPanelCollapsed,
                  );
                  HapticFeedback.lightImpact();
                },
                icon: Icon(
                  _isQuadrantPanelCollapsed
                      ? Icons.expand_more_rounded
                      : Icons.expand_less_rounded,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
          if (!_isQuadrantPanelCollapsed) ...[
            const SizedBox(height: 6),
            Text(
              'Choose urgency & importance',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            if (_quadrantError != null) ...[
              const SizedBox(height: 4),
              Text(
                _quadrantError!,
                style: TextStyle(color: colorScheme.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            ...Quadrant.values.asMap().entries.map((entry) {
              final quadrant = entry.value;
              final info = quadrantInfo[quadrant]!;
              final isSelected = selectedQuadrant == quadrant;
              final customName =
                  quadrantNames[quadrant] ?? info['title'] as String;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedQuadrant = quadrant;
                      _quadrantError = null;
                    });
                    HapticFeedback.selectionClick();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (info['color'] as Color).withOpacity(0.1)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? (info['color'] as Color)
                            : colorScheme.outlineVariant.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (info['color'] as Color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            info['icon'] as IconData,
                            color: info['color'] as Color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                info['subtitle'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected
                              ? (info['color'] as Color)
                              : colorScheme.onSurfaceVariant.withOpacity(0.4),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ] else ...[
            const SizedBox(height: 12),
            if (selectedQuadrant != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (quadrantInfo[selectedQuadrant]!['color'] as Color)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: quadrantInfo[selectedQuadrant]!['color'] as Color,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      quadrantInfo[selectedQuadrant]!['icon'] as IconData,
                      color: quadrantInfo[selectedQuadrant]!['color'] as Color,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      quadrantNames[selectedQuadrant] ??
                          quadrantInfo[selectedQuadrant]!['title'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'No priority selected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveTask() async {
    setState(() => _isSaving = true);

    final String title = titleController.text.trim();
    final String? notes = notesController.text.trim().isEmpty
        ? null
        : notesController.text.trim();

    DateTime? finalDateTime;
    if (selectedDate != null) {
      try {
        finalDateTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          selectedTime?.hour ?? 9,
          selectedTime?.minute ?? 0,
        );

        final tz.TZDateTime tzDateTime = tz.TZDateTime.from(
          finalDateTime,
          tz.local,
        );

        if (!tzDateTime.isAfter(tz.TZDateTime.now(tz.local))) {
          setState(() => _isSaving = false);
          _showSnackbar(
            context,
            'Please select a future date and time',
            isError: true,
          );
          return;
        }
      } catch (e) {
        setState(() => _isSaving = false);
        _showSnackbar(context, 'Invalid date/time selection', isError: true);
        return;
      }
    }

    final notificationService = NotificationService();
    final bool isEditing = widget.task != null;
    final String taskId = widget.task?.id ?? const Uuid().v4();
    final int notificationId = notificationService.notificationIdForTask(taskId);

    if (isEditing) {
      await notificationService.cancelNotification(notificationId);
    }

    bool notificationScheduled = false;
    String? notificationError;

    if (finalDateTime != null) {
      try {
        await notificationService.onReady;
        final hasPermissions = await notificationService
            .requestAllPermissions();

        if (!hasPermissions) {
          notificationError = 'Notification permissions required';
        } else {
          final tz.TZDateTime scheduledTime = tz.TZDateTime.from(
            finalDateTime,
            tz.local,
          );
          await notificationService.scheduleNotification(
            id: notificationId,
            title: 'Task Due: $title',
            body: notes ?? "Time for your task: $title",
            scheduledDate: scheduledTime,
            payload: taskId,
          );
          notificationScheduled = true;
        }
      } catch (e) {
        notificationError = 'Failed to schedule notification';
      }
    }

    final newTask = Task(
      id: taskId,
      title: title,
      notes: notes,
      quadrant: selectedQuadrant!,
      dueDate: finalDateTime,
      isCompleted: widget.task?.isCompleted ?? false,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref.read(taskProvider.notifier).updateTask(newTask);

    setState(() => _isSaving = false);

    if (context.mounted) {
      if (notificationScheduled && finalDateTime != null) {
        final timeUntil = finalDateTime.difference(DateTime.now());
        final hoursUntil = timeUntil.inHours;
        final minutesUntil = timeUntil.inMinutes % 60;

        String timeMessage = '';
        if (hoursUntil > 0) {
          timeMessage = ' (in ${hoursUntil}h ${minutesUntil}m)';
        } else if (minutesUntil > 0) {
          timeMessage = ' (in ${minutesUntil}m)';
        } else {
          timeMessage = ' (soon!)';
        }

        _showSnackbar(
          context,
          'Task saved with reminder$timeMessage',
          isError: false,
        );
      } else if (notificationError != null) {
        _showSnackbar(context, notificationError, isError: true);
      } else {
        _showSnackbar(context, 'Task saved successfully!', isError: false);
      }

      await Future.delayed(const Duration(milliseconds: 300));
      Navigator.pop(context);
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showAppDialog(
      context: context,
      builder: (context) => AppDialogContainer(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete Task',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This action cannot be undone. Are you sure?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppDialogButton(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDialogButton(
                      label: 'Delete',
                      isDestructive: true,
                      onTap: () {
                        ref.read(taskProvider.notifier).deleteTask(widget.task!.id);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackbar(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = Platform.isWindows ? 48.0 : 0.0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? colorScheme.error : const Color(0xFF2ED573),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
