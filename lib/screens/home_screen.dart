import 'package:flutter/material.dart';
import '../providers/task_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../models/quadrant_enum.dart';
import '../models/task_models.dart';
import '../providers/filter_provider.dart';
import '../providers/task_provider.dart';
import '../screens/task_edit_screen.dart';
import '../widgets/grouped_buttons.dart';
import '../widgets/quadrant_card.dart';
import '../widgets/settings_bottomsheet.dart';
import '../widgets/task_tile.dart';

enum ViewMode { card, list }

final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.card);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tasks = ref.watch(taskProvider);
    final filter = ref.watch(filterProvider);
    final viewMode = ref.watch(viewModeProvider);
    final showCompleted = ref.watch(showCompletedTasksNotifierProvider);

    final completedTasks = tasks.where((task) => task.isCompleted).toList();
    final incompleteTasks = tasks.where((task) => !task.isCompleted).toList();

    ref.listen(taskProvider, (List? previous, List current) {
      if (previous != null && previous.length > current.length) {
        final completedTask = previous.firstWhere(
          (task) => !current.any((currentTask) => currentTask.id == task.id),
          orElse: () => null,
        );

        if (completedTask != null) {
          _showTaskCompletedSnackbar(context, completedTask as Task, ref);
        }
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with Grouped Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Focus',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Eisenhower Matrix App',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    GroupedButtons(
                      viewMode: viewMode,
                      onFilterPressed: () async => _showFilterDialog(context, ref),

                      onSettingsPressed: () async => showSettingsBottomSheet(context),

                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Content
                Expanded(
                  child:
                      viewMode == ViewMode.card
                          ? _buildCardView(
                            showCompleted ? tasks : incompleteTasks,
                            colorScheme,
                          )
                          : _buildListView(
                            tasks,
                            filter,
                            showCompleted,
                            theme,
                            colorScheme,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),

      // floating button for task adding
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTask(context),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCardView(List<Task> tasks, ColorScheme colorScheme) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildMatrixCard(
                  title: 'Do First',
                  description: 'Urgent • Important',
                  accentColor: const Color(0xFFFF4757),
                  taskCount:
                      tasks
                          .where(
                            (task) => task.quadrant == Quadrant.urgentImportant,
                          )
                          .length,
                  colorScheme: colorScheme,
                  child: QuadrantCard(
                    quadrant: Quadrant.urgentImportant,
                    tasks:
                        tasks
                            .where(
                              (task) =>
                                  task.quadrant == Quadrant.urgentImportant,
                            )
                            .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMatrixCard(
                  title: 'Schedule',
                  description: 'Not Urgent • Important',
                  accentColor: const Color(0xFF2ED573),
                  taskCount:
                      tasks
                          .where(
                            (task) =>
                                task.quadrant == Quadrant.notUrgentImportant,
                          )
                          .length,
                  colorScheme: colorScheme,
                  child: QuadrantCard(
                    quadrant: Quadrant.notUrgentImportant,
                    tasks:
                        tasks
                            .where(
                              (task) =>
                                  task.quadrant == Quadrant.notUrgentImportant,
                            )
                            .toList(),
                  ),
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
                child: _buildMatrixCard(
                  title: 'Delegate',
                  description: 'Urgent • Not Important',
                  accentColor: const Color(0xFFFFA726),
                  taskCount:
                      tasks
                          .where(
                            (task) =>
                                task.quadrant == Quadrant.urgentNotImportant,
                          )
                          .length,
                  colorScheme: colorScheme,
                  child: QuadrantCard(
                    quadrant: Quadrant.urgentNotImportant,
                    tasks:
                        tasks
                            .where(
                              (task) =>
                                  task.quadrant == Quadrant.urgentNotImportant,
                            )
                            .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMatrixCard(
                  title: 'Eliminate',
                  description: 'Not Urgent • Not Important',
                  accentColor: const Color(0xFF747D8C),
                  taskCount:
                      tasks
                          .where(
                            (task) =>
                                task.quadrant == Quadrant.notUrgentNotImportant,
                          )
                          .length,
                  colorScheme: colorScheme,
                  child: QuadrantCard(
                    quadrant: Quadrant.notUrgentNotImportant,
                    tasks:
                        tasks
                            .where(
                              (task) =>
                                  task.quadrant ==
                                  Quadrant.notUrgentNotImportant,
                            )
                            .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView(
    List<Task> tasks,
    TaskViewFilter filter,
    bool showCompleted,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    List<Task> filteredTasks = tasks;
    final now = DateTime.now();

    switch (filter) {
      case TaskViewFilter.Daily:
        filteredTasks =
            tasks
                .where(
                  (task) =>
                      task.dueDate != null && task.dueDate!.isSameDay(now),
                )
                .toList();
        break;
      case TaskViewFilter.Weekly:
        filteredTasks =
            tasks
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
        filteredTasks =
            tasks
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

    // Separate completed and incomplete tasks
    final completedTasks =
        filteredTasks.where((task) => task.isCompleted).toList();
    final incompleteTasks =
        filteredTasks.where((task) => !task.isCompleted).toList();

    // Use only incomplete tasks for quadrant grouping
    final quadrantGroups = <Quadrant, List<Task>>{};
    for (final quadrant in Quadrant.values) {
      quadrantGroups[quadrant] =
          incompleteTasks.where((task) => task.quadrant == quadrant).toList();
    }

    // Check if there are any tasks to show (completed or incomplete)
    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: colorScheme.onSurface.withOpacity(0.4),
                size: 28,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              filter == TaskViewFilter.All && !showCompleted
                  ? 'No tasks found'
                  : 'No tasks found for this filter',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            // tap to add button
            GestureDetector(
              onTap: () => _navigateToAddTask(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tap to add task',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return ListView(
      children: [
        // ✅ FIX: Show completed tasks section only if showCompleted is true and there are completed tasks
        if (showCompleted && completedTasks.isNotEmpty)
          _buildCompletedTasksSection(completedTasks, theme, colorScheme),
        // ✅ FIX: Show quadrant sections only for incomplete tasks
        ...Quadrant.values.map((quadrant) {
          final quadrantTasks = quadrantGroups[quadrant]!;
          if (quadrantTasks.isEmpty) return const SizedBox.shrink();

          return _buildListSection(
            _getQuadrantTitle(quadrant),
            _getQuadrantDescription(quadrant),
            _getQuadrantColor(quadrant),
            quadrantTasks,
            theme,
            colorScheme,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCompletedTasksSection(
    List<Task> completedTasks,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
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
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completed Tasks',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${completedTasks.length} tasks completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children:
                  completedTasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskTile(
                        task: task,
                        key: ValueKey('completed_${task.id}'),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(
    String title,
    String description,
    Color accentColor,
    List<Task> tasks,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
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
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    tasks.length.toString(),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children:
                  tasks.map((task) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskTile(
                        task: task,
                        key: ValueKey('${task.id}_${task.isCompleted}'),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixCard({
    required String title,
    required String description,
    required Color accentColor,
    required int taskCount,
    required ColorScheme colorScheme,
    required Widget child,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (taskCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          taskCount.toString(),
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    description,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getQuadrantTitle(Quadrant quadrant) {
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

  String _getQuadrantDescription(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.urgentImportant:
        return 'Urgent • Important';
      case Quadrant.notUrgentImportant:
        return 'Not Urgent • Important';
      case Quadrant.urgentNotImportant:
        return 'Urgent • Not Important';
      case Quadrant.notUrgentNotImportant:
        return 'Not Urgent • Not Important';
    }
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
      MaterialPageRoute(builder: (context) => const TaskEditScreen()),
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentFilter = ref.read(filterProvider);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: colorScheme.surfaceContainerHigh,
          surfaceTintColor: colorScheme.surfaceTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Options',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                ...TaskViewFilter.values.map((filterOption) {
                  final isSelected = currentFilter == filterOption;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isSelected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                          border: Border.all(
                            color:
                                isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                            width: 1.5,
                          ),
                        ),
                        child:
                            isSelected
                                ? Icon(
                                  Icons.check,
                                  color: colorScheme.onPrimary,
                                  size: 16,
                                )
                                : null,
                      ),
                      title: Text(
                        _getFilterDisplayName(filterOption),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      onTap: () {
                        ref.read(filterProvider.notifier).state = filterOption;
                        Navigator.pop(context);
                        HapticFeedback.selectionClick();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFilterDisplayName(TaskViewFilter filter) {
    switch (filter) {
      case TaskViewFilter.All:
        return 'All Tasks';
      case TaskViewFilter.Daily:
        return 'Today';
      case TaskViewFilter.Weekly:
        return 'This Week';
      case TaskViewFilter.Monthly:
        return 'This Month';
    }
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
          Icon(
            Icons.check_circle_outline,
            color: colorScheme.onPrimary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Task Completed!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
                Text(
                  completedTask.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'UNDO',
        textColor: colorScheme.onPrimary,
        onPressed: () {
          final currentTasks = ref.read(taskProvider);
          final updatedTask = completedTask.copyWith(isCompleted: false);
          ref.read(taskProvider.notifier).state = [
            ...currentTasks,
            updatedTask,
          ];
          HapticFeedback.selectionClick();
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
