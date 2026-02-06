import 'package:flutter/material.dart';
import 'package:focus/screens/desktop_task_edit_screen.dart';
import '../providers/show_completed_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../models/quadrant_enum.dart';
import '../models/task_models.dart';
import '../providers/filter_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/command_palatte.dart';
import '../widgets/settings_bottomsheet.dart';
import '../widgets/task_tile.dart';
import 'dart:math' as math;

class OpenCommandPaletteIntent extends Intent {
  const OpenCommandPaletteIntent();
}

class ToggleFocusModeIntent extends Intent {
  const ToggleFocusModeIntent();
}

class AddTaskIntent extends Intent {
  const AddTaskIntent();
}

class ToggleShowCompletedIntent extends Intent {
  const ToggleShowCompletedIntent();
}

class SelectQuadrantIntent extends Intent {
  final Quadrant quadrant;
  const SelectQuadrantIntent(this.quadrant);
}

class OpenCommandPaletteAction extends Action<OpenCommandPaletteIntent> {
  final BuildContext context;
  OpenCommandPaletteAction(this.context);

  @override
  void invoke(OpenCommandPaletteIntent intent) {
    showDialog(context: context, builder: (context) => const CommandPalette());
  }
}

class ConfettiPainter extends CustomPainter {
  final double animation;
  final List<Offset> positions;

  ConfettiPainter({required this.animation, required this.positions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = math.Random();

    for (int i = 0; i < positions.length; i++) {
      final progress = animation * (0.8 + random.nextDouble() * 0.2);
      if (progress > 1.0) continue;

      final offset = positions[i];
      final x = offset.dx + (random.nextDouble() - 0.5) * 200 * progress;
      final y = offset.dy - 300 * progress + 50 * math.sin(progress * math.pi);

      paint.color = Color.fromARGB(
        (1.0 - progress).clamp(0, 1) * 255 ~/ 1,
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
      );

      canvas.drawCircle(Offset(x, y), 4 + 2 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DesktopHomeScreen extends ConsumerStatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  ConsumerState<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends ConsumerState<DesktopHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _confettiController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  Quadrant? _selectedQuadrant;
  final FocusNode _focusNode = FocusNode();

  bool _isFocusMode = false;
  Quadrant? _focusedQuadrant;
  int _tasksCompletedToday = 0;
  bool _showCelebration = false;
  List<Offset> _confettiPositions = [];

  bool _hasShownMorningPrompt = false;
  bool _hasShownEveningReview = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _checkDailyRituals();
  }

  void _checkDailyRituals() async {
    final now = DateTime.now();
    final hour = now.hour;
    if (hour >= 7 && hour <= 10 && !_hasShownMorningPrompt) {
      _showMorningPrompt();
      _hasShownMorningPrompt = true;
    }
    if (hour >= 18 && hour <= 21 && !_hasShownEveningReview) {
      final tasks = ref.read(taskProvider);
      final completedToday = tasks
          .where(
            (t) =>
                t.isCompleted &&
                t.updatedAt.isAfter(DateTime(now.year, now.month, now.day)),
          )
          .isNotEmpty;
      if (completedToday) {
        _showEveningReview();
        _hasShownEveningReview = true;
      }
    }
  }

  void _showMorningPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sunny, color: Color(0xFFFFA726)),
            SizedBox(width: 12),
            Text('Good Morning ☀️'),
          ],
        ),
        content: const Text(
          'Take 2 minutes to plan your priorities for today.',
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Maybe later'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plan Now'),
          ),
        ],
      ),
    );
  }

  void _showEveningReview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.nightlight_round, color: Color(0xFF2ED573)),
            SizedBox(width: 12),
            Text('Great Work Today 🌙'),
          ],
        ),
        content: const Text(
          'Review what you accomplished and plan for tomorrow.',
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }

  void _triggerCelebration() {
    setState(() {
      _showCelebration = true;
      _confettiPositions = List.generate(
        50,
        (index) => Offset(
          math.Random().nextDouble() * MediaQuery.of(context).size.width,
          math.Random().nextDouble() * 300 + 200,
        ),
      );
    });
    _confettiController.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showCelebration = false);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tasks = ref.watch(taskProvider);
    final filter = ref.watch(filterProvider);
    final showCompletedAsync = ref.watch(showCompletedTasksProvider);
    final showCompleted = showCompletedAsync.value ?? false;

    final filteredTasks = _getFilteredTasks(tasks, filter, showCompleted);
    final urgentTasks = filteredTasks
        .where((t) => !t.isCompleted && _isUrgent(t))
        .length;
    final completedToday = tasks
        .where(
          (t) =>
              t.isCompleted &&
              t.updatedAt.isAfter(
                DateTime.now().subtract(const Duration(days: 1)),
              ),
        )
        .length;
    final productivityScore = _calculateProductivityScore(tasks);
    final shouldShowBurnoutWarning = _shouldShowBurnoutWarning(tasks);

    ref.listen(taskProvider, (List? previous, List current) {
      if (previous != null && previous.length > current.length) {
        final completedTask = previous.firstWhere(
          (task) => !current.any((currentTask) => currentTask.id == task.id),
          orElse: () => null,
        );
        if (completedTask != null) {
          setState(() => _tasksCompletedToday++);
          _showTaskCompletedSnackbar(context, completedTask as Task, ref);
          if (_tasksCompletedToday % 5 == 0) _triggerCelebration();
        }
      }
    });

    final shortcuts = <ShortcutActivator, Intent>{
      // Command Palette
      const SingleActivator(LogicalKeyboardKey.keyK, control: true):
          const OpenCommandPaletteIntent(),
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
          const OpenCommandPaletteIntent(),
      // Focus Mode
      const SingleActivator(LogicalKeyboardKey.keyF, control: true):
          const ToggleFocusModeIntent(),
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
          const ToggleFocusModeIntent(),
      // Add Task
      const SingleActivator(LogicalKeyboardKey.keyN, control: true):
          const AddTaskIntent(),
      const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
          const AddTaskIntent(),
      // Toggle Completed
      const SingleActivator(LogicalKeyboardKey.keyH, control: true):
          const ToggleShowCompletedIntent(),
      const SingleActivator(LogicalKeyboardKey.keyH, meta: true):
          const ToggleShowCompletedIntent(),
      // Quadrant Navigation
      const SingleActivator(LogicalKeyboardKey.digit1):
          const SelectQuadrantIntent(Quadrant.urgentImportant),
      const SingleActivator(LogicalKeyboardKey.digit2):
          const SelectQuadrantIntent(Quadrant.notUrgentImportant),
      const SingleActivator(LogicalKeyboardKey.digit3):
          const SelectQuadrantIntent(Quadrant.urgentNotImportant),
      const SingleActivator(LogicalKeyboardKey.digit4):
          const SelectQuadrantIntent(Quadrant.notUrgentNotImportant),
    };

    final actions = <Type, Action<Intent>>{
      OpenCommandPaletteIntent: OpenCommandPaletteAction(context),
      ToggleFocusModeIntent: CallbackAction<ToggleFocusModeIntent>(
        onInvoke: (intent) => _toggleFocusMode(),
      ),
      AddTaskIntent: CallbackAction<AddTaskIntent>(
        onInvoke: (intent) => _navigateToAddTask(context),
      ),
      ToggleShowCompletedIntent: CallbackAction<ToggleShowCompletedIntent>(
        onInvoke: (intent) =>
            ref.read(showCompletedTasksProvider.notifier).toggle(),
      ),
      SelectQuadrantIntent: CallbackAction<SelectQuadrantIntent>(
        onInvoke: (intent) {
          setState(() => _selectedQuadrant = intent.quadrant);
          HapticFeedback.selectionClick();
          return null;
        },
      ),
    };

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      child: Actions(
        actions: actions,
        child: Shortcuts(
          shortcuts: shortcuts,
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: _isFocusMode
                    ? colorScheme.surface.withValues(alpha: 0.95)
                    : colorScheme.surface,
                body: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      if (!_isFocusMode)
                        _buildCompactTopBar(
                          theme,
                          colorScheme,
                          filter,
                          urgentTasks,
                          completedToday,
                        ),
                      if (_isFocusMode)
                        _buildFocusModeHeader(theme, colorScheme),
                      if (shouldShowBurnoutWarning && !_isFocusMode)
                        _buildBurnoutWarning(theme, colorScheme),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _isFocusMode
                              ? _buildFocusView(
                                  filteredTasks,
                                  colorScheme,
                                  theme,
                                )
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: _buildMatrixGrid(
                                        filteredTasks,
                                        colorScheme,
                                        theme,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 320,
                                      child: _buildInsightsPanel(
                                        filteredTasks,
                                        theme,
                                        colorScheme,
                                        completedToday,
                                        productivityScore,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showCelebration)
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _confettiController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ConfettiPainter(
                          animation: _confettiController.value,
                          positions: _confettiPositions,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowBurnoutWarning(List<Task> tasks) {
    final overdue = tasks
        .where(
          (t) =>
              !t.isCompleted &&
              t.dueDate != null &&
              t.dueDate!.isBefore(DateTime.now()),
        )
        .length;
    return overdue > 3;
  }

  Widget _buildBurnoutWarning(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4757).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF4757).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: const Color(0xFFFF4757)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You have several overdue tasks. Consider delegating or rescheduling to avoid burnout.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  double _calculateProductivityScore(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.isCompleted).length;
    final onTime = tasks
        .where(
          (t) =>
              t.isCompleted &&
              t.dueDate != null &&
              t.updatedAt.isBefore(t.dueDate!),
        )
        .length;
    final completionRate = completed / tasks.length;
    final onTimeRate = completed > 0 ? onTime / completed : 0.0;
    return (completionRate * 0.6 + onTimeRate * 0.4) * 100;
  }

  void _toggleFocusMode() {
    setState(() {
      _isFocusMode = !_isFocusMode;
      if (_isFocusMode && _selectedQuadrant != null) {
        _focusedQuadrant = _selectedQuadrant;
      }
    });
    HapticFeedback.mediumImpact();
  }

  Widget _buildFocusModeHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary.withOpacity(0.1), colorScheme.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.center_focus_strong_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            'Focus Mode',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          FilledButton.tonalIcon(
            onPressed: _toggleFocusMode,
            icon: const Icon(Icons.exit_to_app_rounded, size: 18),
            label: const Text('Exit Focus'),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusView(
    List<Task> tasks,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final quadrant = _focusedQuadrant ?? Quadrant.urgentImportant;
    final quadrantTasks = tasks
        .where((t) => t.quadrant == quadrant && !t.isCompleted)
        .toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getQuadrantColor(quadrant).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getQuadrantColor(quadrant).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getQuadrantIcon(quadrant),
                    color: _getQuadrantColor(quadrant),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getQuadrantName(quadrant),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${quadrantTasks.length} tasks remaining',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: quadrantTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.celebration_rounded,
                            size: 64,
                            color: _getQuadrantColor(quadrant).withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'All clear! 🎉',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No tasks in this quadrant',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: quadrantTasks.length,
                      itemBuilder: (context, index) {
                        final task = quadrantTasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TaskTile(
                              task: task,
                              key: ValueKey('${task.id}_${task.isCompleted}'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getQuadrantName(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.urgentImportant:
        return 'Do First';
      case Quadrant.notUrgentImportant:
        return 'Schedule';
      case Quadrant.urgentNotImportant:
        return 'Delegate';
      case Quadrant.notUrgentNotImportant:
        return 'Eliminate';
    }
  }

  IconData _getQuadrantIcon(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.urgentImportant:
        return Icons.local_fire_department_rounded;
      case Quadrant.notUrgentImportant:
        return Icons.calendar_today_rounded;
      case Quadrant.urgentNotImportant:
        return Icons.people_outline_rounded;
      case Quadrant.notUrgentNotImportant:
        return Icons.remove_circle_outline_rounded;
    }
  }

  Widget _buildCompactTopBar(
    ThemeData theme,
    ColorScheme colorScheme,
    TaskViewFilter filter,
    int urgentCount,
    int completedToday,
  ) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: Icon(
              Icons.grid_view_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),
          Text(
            'Focus',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 24),
          if (completedToday > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2ED573),
                borderRadius: BorderRadius.circular(20),
              ),

              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$completedToday done today',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
          if (urgentCount > 0)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4757).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF4757),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFFF4757),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$urgentCount urgent',
                          style: const TextStyle(
                            color: Color(0xFFFF4757),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const Spacer(),
          _buildQuickFilterChips(filter, colorScheme, theme),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToAddTask(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: colorScheme.onSurface,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'New',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => showSettingsBottomSheet(context),
            icon: const Icon(Icons.settings_outlined, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(
                0.5,
              ),
              foregroundColor: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChips(
    TaskViewFilter filter,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final filters = [
      TaskViewFilter.All,
      TaskViewFilter.Daily,
      TaskViewFilter.Weekly,
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: filters.map((f) {
          final isSelected = filter == f;
          return GestureDetector(
            onTap: () {
              ref.read(filterProvider.notifier).state = f;
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getShortFilterName(f),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,

                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getShortFilterName(TaskViewFilter filter) {
    switch (filter) {
      case TaskViewFilter.All:
        return 'All';
      case TaskViewFilter.Daily:
        return 'Today';
      case TaskViewFilter.Weekly:
        return 'Week';
      case TaskViewFilter.Monthly:
        return 'Month';
    }
  }

  Widget _buildMatrixGrid(
    List<Task> tasks,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildQuadrantCard(
                  quadrant: Quadrant.urgentImportant,
                  title: 'Do',
                  subtitle: 'Critical',
                  icon: Icons.local_fire_department_rounded,
                  accentColor: const Color(0xFFFF4757),
                  tasks: tasks
                      .where((t) => t.quadrant == Quadrant.urgentImportant)
                      .toList(),
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuadrantCard(
                  quadrant: Quadrant.notUrgentImportant,
                  title: 'Plan',
                  subtitle: 'Important',
                  icon: Icons.calendar_today_rounded,
                  accentColor: const Color(0xFF2ED573),
                  tasks: tasks
                      .where((t) => t.quadrant == Quadrant.notUrgentImportant)
                      .toList(),
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildQuadrantCard(
                  quadrant: Quadrant.urgentNotImportant,
                  title: 'Delegate',
                  subtitle: 'Quick wins',
                  icon: Icons.people_outline_rounded,
                  accentColor: const Color(0xFFFFA726),
                  tasks: tasks
                      .where((t) => t.quadrant == Quadrant.urgentNotImportant)
                      .toList(),
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuadrantCard(
                  quadrant: Quadrant.notUrgentNotImportant,
                  title: 'Delete',
                  subtitle: 'Low priority',
                  icon: Icons.remove_circle_outline_rounded,
                  accentColor: const Color(0xFF747D8C),
                  tasks: tasks
                      .where(
                        (t) => t.quadrant == Quadrant.notUrgentNotImportant,
                      )
                      .toList(),
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuadrantCard({
    required Quadrant quadrant,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<Task> tasks,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    final isSelected = _selectedQuadrant == quadrant;
    final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();
    final progress = tasks.isEmpty
        ? 0.0
        : tasks.where((t) => t.isCompleted).length / tasks.length;

    return DragTarget<Task>(
      onAccept: (Task droppedTask) {
        if (droppedTask.quadrant != quadrant) {
          final updatedTask = droppedTask.copyWith(quadrant: quadrant);
          ref.read(taskProvider.notifier).updateTask(updatedTask);
          HapticFeedback.mediumImpact();
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isDraggingOver = candidateData.isNotEmpty;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedQuadrant = quadrant);
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isDraggingOver
                    ? accentColor.withOpacity(0.08)
                    : colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDraggingOver
                      ? accentColor
                      : isSelected
                      ? accentColor
                      : colorScheme.outlineVariant.withOpacity(0.2),
                  width: isDraggingOver || isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            incompleteTasks.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tasks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: accentColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation(accentColor),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: incompleteTasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: accentColor.withOpacity(0.3),
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'All clear',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            itemCount: incompleteTasks.length,
                            itemBuilder: (context, index) {
                              final task = incompleteTasks[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildDraggableTaskTile(
                                  task,
                                  colorScheme,
                                  theme,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableTaskTile(
    Task task,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: LongPressDraggable<Task>(
        data: task,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _getQuadrantColor(task.quadrant).withOpacity(0.5),
              ),
            ),
            child: Text(
              task.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        child: _buildTaskTileWithHoverActions(task, colorScheme, theme),
      ),
    );
  }

  Widget _buildTaskTileWithHoverActions(
    Task task,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool _isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Container(
            decoration: BoxDecoration(
              color: _isHovered ? colorScheme.surfaceContainerHighest : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TaskTile(
                    task: task,
                    key: ValueKey('${task.id}_${task.isCompleted}'),
                  ),
                ),
                if (_isHovered)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          final updatedTask = task.copyWith(
                            isCompleted: true,
                            updatedAt: DateTime.now(),
                          );
                          ref
                              .read(taskProvider.notifier)
                              .updateTask(updatedTask);
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DesktopTaskEditScreen(task: task),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            ref.read(taskProvider.notifier).deleteTask(task.id),
                        icon: const Icon(Icons.delete_outlined, size: 18),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightsPanel(
    List<Task> tasks,
    ThemeData theme,
    ColorScheme colorScheme,
    int completedToday,
    double productivityScore,
  ) {
    final incomplete = tasks.where((t) => !t.isCompleted).toList();
    final overdue = incomplete
        .where((t) => t.dueDate != null && t.dueDate!.isBefore(DateTime.now()))
        .toList();
    final urgent = incomplete.where(_isUrgent).toList();

    final upcoming = incomplete
      ..sort((a, b) {
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

    String dayTone;
    if (overdue.isNotEmpty) {
      dayTone = 'The day is carrying unresolved weight.';
    } else if (urgent.length > 2) {
      dayTone = 'Attention is fragmented today.';
    } else if (incomplete.isEmpty) {
      dayTone = 'You have breathing room today.';
    } else {
      dayTone = 'The workload looks manageable.';
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              dayTone,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSignalRow(
                'Completed today',
                completedToday.toString(),
                completedToday > 0
                    ? const Color(0xFF2ED573)
                    : colorScheme.onSurfaceVariant,
                theme,
              ),
              _buildSignalRow(
                'Pending tasks',
                incomplete.length.toString(),
                colorScheme.primary,
                theme,
              ),
              _buildSignalRow(
                'Overdue',
                overdue.length.toString(),
                overdue.isNotEmpty
                    ? const Color(0xFFFF4757)
                    : colorScheme.onSurfaceVariant,
                theme,
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
            child: upcoming.isEmpty
                ? Text(
                    'No immediate commitments ahead.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next anchor',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        upcoming.first.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (upcoming.first.dueDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatDueDate(upcoming.first.dueDate!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalRow(
    String label,
    String value,
    Color valueColor,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  bool _isUrgent(Task task) {
    if (task.dueDate == null) return false;
    final daysUntil = task.dueDate!.difference(DateTime.now()).inDays;
    return daysUntil <= 1;
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    if (difference < 0) return 'Overdue';
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference < 7) return '${difference}d';
    return '${date.day}/${date.month}';
  }

  List<Task> _getFilteredTasks(
    List<Task> tasks,
    TaskViewFilter filter,
    bool showCompleted,
  ) {
    List<Task> filteredTasks = tasks;
    final now = DateTime.now();
    switch (filter) {
      case TaskViewFilter.Daily:
        filteredTasks = tasks
            .where(
              (task) => task.dueDate != null && task.dueDate!.isSameDay(now),
            )
            .toList();
        break;
      case TaskViewFilter.Weekly:
        filteredTasks = tasks
            .where(
              (task) =>
                  task.dueDate != null &&
                  task.dueDate!.isAfter(
                    now.subtract(const Duration(days: 1)),
                  ) &&
                  task.dueDate!.isBefore(now.add(const Duration(days: 7))),
            )
            .toList();
        break;
      case TaskViewFilter.Monthly:
        filteredTasks = tasks
            .where(
              (task) =>
                  task.dueDate != null &&
                  task.dueDate!.year == now.year &&
                  task.dueDate!.month == now.month,
            )
            .toList();
        break;
      case TaskViewFilter.All:
      default:
        if (!showCompleted) {
          filteredTasks = tasks.where((task) => !task.isCompleted).toList();
        }
        break;
    }
    return filteredTasks;
  }

  Color _getQuadrantColor(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.urgentImportant:
        return const Color(0xFFFF4757);
      case Quadrant.notUrgentImportant:
        return const Color(0xFF2ED573);
      case Quadrant.urgentNotImportant:
        return const Color(0xFFFFA726);
      case Quadrant.notUrgentNotImportant:
        return const Color(0xFF747D8C);
    }
  }

  void _navigateToAddTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DesktopTaskEditScreen()),
    );
  }
}

void _showTaskCompletedSnackbar(
  BuildContext context,
  Task completedTask,
  WidgetRef ref,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Completed!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  completedTask.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF2ED573),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'UNDO',
        textColor: Colors.white,
        onPressed: () {
          final currentTasks = ref.read(taskProvider);
          final updatedTask = completedTask.copyWith(isCompleted: false);
          ref.read(taskProvider.notifier).state = [
            ...currentTasks,
            updatedTask,
          ];
          HapticFeedback.lightImpact();
        },
      ),
    ),
  );
}

extension DateTimeExtension on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
