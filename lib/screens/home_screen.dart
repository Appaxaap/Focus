import 'package:flutter/material.dart';
import 'dart:ui';
import '../providers/show_completed_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../models/quadrant_enum.dart';
import '../models/task_models.dart';
import '../providers/filter_provider.dart';
import '../providers/task_provider.dart';
import '../screens/task_edit_screen.dart';
import '../widgets/grouped_buttons.dart';
import '../widgets/quadrant_card.dart';
import '../widgets/quadrant_edit_dialog.dart';
import '../widgets/settings_bottomsheet.dart';
import '../widgets/task_tile.dart';
import '../providers/quadrant_names_provider.dart';
import '../widgets/app_dialog.dart';

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
  late final ProviderSubscription<List<Task>> _taskSubscription;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

    _taskSubscription = ref.listenManual<List<Task>>(taskProvider, (
      previous,
      current,
    ) {
      if (!mounted || previous == null || previous.length <= current.length) {
        return;
      }
      final completedTask = previous
          .where((task) => !current.any((t) => t.id == task.id))
          .firstOrNull;
      if (completedTask != null) {
        _showTaskCompletedSnackbar(context, completedTask, ref);
      }
    });
  }

  @override
  void dispose() {
    _taskSubscription.close();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() {
      _isSearching = true;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tasks = ref.watch(taskProvider);
    final filter = ref.watch(filterProvider);
    final viewMode = ref.watch(viewModeProvider);
    final showCompletedAsync = ref.watch(showCompletedTasksProvider);
    final showCompleted = showCompletedAsync.value ?? false;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      key: const ValueKey('header'),
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
                          onSearchPressed: _openSearch,
                          onFilterPressed: () async =>
                              _showFilterDialog(context, ref),
                          onSettingsPressed: () async =>
                              showSettingsBottomSheet(context),
                          showSearchButton: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Main Content
                    Expanded(
                      child: _isSearching
                          ? _buildSearchResults(tasks, theme, colorScheme)
                          : viewMode == ViewMode.card
                          ? _buildCardView(tasks, showCompleted, colorScheme)
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
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isSearching
                          ? _buildSearchBar(colorScheme, theme)
                          : _buildTopSearchActionBar(colorScheme, theme),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSearchActionBar(ColorScheme colorScheme, ThemeData theme) {
    return Row(
      key: const ValueKey('top_search_action_bar'),
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: _openSearch,
              child: Ink(
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search for anything...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _navigateToAddTask(context),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHigh,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Icon(Icons.add_rounded, color: colorScheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme, ThemeData theme) {
    return Row(
      key: const ValueKey('searchbar'),
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _closeSearch,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurface,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(
    List<Task> tasks,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (_searchQuery.trim().isEmpty) {
      return Center(
        child: Text(
          'Type to search tasks',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final query = _searchQuery.trim().toLowerCase();
    final results = tasks.where((task) {
      return task.title.toLowerCase().contains(query) ||
          (task.notes?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No tasks found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final task = results[index];
        final quadrantColor = _getQuadrantColor(task.quadrant);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _closeSearch();
              Navigator.push(context, _fastRoute(TaskEditScreen(task: task)));
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: quadrantColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: task.isCompleted
                                ? colorScheme.onSurface.withValues(alpha: 0.4)
                                : colorScheme.onSurface,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.notes != null && task.notes!.isNotEmpty)
                          Text(
                            task.notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: quadrantColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getQuadrantTitle(task.quadrant),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: quadrantColor,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildCardView(
    List<Task> tasks,
    bool showCompleted,
    ColorScheme colorScheme,
  ) {
    final quadrantNames = ref.watch(quadrantNamesProvider);
    final byQuadrant = {
      for (final quadrant in Quadrant.values) quadrant: <Task>[],
    };
    for (final task in tasks) {
      if (!showCompleted && task.isCompleted) continue;
      byQuadrant[task.quadrant]!.add(task);
    }

    final q1 = byQuadrant[Quadrant.urgentImportant]!;
    final q2 = byQuadrant[Quadrant.notUrgentImportant]!;
    final q3 = byQuadrant[Quadrant.urgentNotImportant]!;
    final q4 = byQuadrant[Quadrant.notUrgentNotImportant]!;

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildMatrixCard(
                  quadrant: Quadrant.urgentImportant,
                  title: quadrantNames[Quadrant.urgentImportant] ?? 'Do First',
                  description: 'Urgent • Important',
                  accentColor: const Color(0xFFFF4757),
                  taskCount: q1.length,
                  colorScheme: colorScheme,
                  child: QuadrantCard(
                    quadrant: Quadrant.urgentImportant,
                    tasks: q1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMatrixCard(
                  quadrant: Quadrant.notUrgentImportant,
                  title:
                      quadrantNames[Quadrant.notUrgentImportant] ?? 'Schedule',
                  description: 'Not Urgent • Important',
                  accentColor: const Color(0xFF2ED573),
                  taskCount: q2.length,
                  colorScheme: colorScheme,
                  child: QuadrantCard(
                    quadrant: Quadrant.notUrgentImportant,
                    tasks: q2,
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
                  quadrant: Quadrant.urgentNotImportant,
                  title:
                      quadrantNames[Quadrant.urgentNotImportant] ?? 'Delegate',
                  description: 'Urgent • Not Important',
                  accentColor: const Color(0xFFFFA726),
                  taskCount: q3.length,
                  colorScheme: colorScheme,
                  child: QuadrantCard(
                    quadrant: Quadrant.urgentNotImportant,
                    tasks: q3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMatrixCard(
                  quadrant: Quadrant.notUrgentNotImportant,
                  title:
                      quadrantNames[Quadrant.notUrgentNotImportant] ??
                      'Eliminate',
                  description: 'Not Urgent • Not Important',
                  accentColor: const Color(0xFF747D8C),
                  taskCount: q4.length,
                  colorScheme: colorScheme,
                  child: QuadrantCard(
                    quadrant: Quadrant.notUrgentNotImportant,
                    tasks: q4,
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
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
    final weeklyCutoff = startOfTomorrow.add(const Duration(days: 7));

    final completedTasks = <Task>[];
    final quadrantGroups = {
      for (final quadrant in Quadrant.values) quadrant: <Task>[],
    };

    for (final task in tasks) {
      var matchesFilter = true;
      final dueDate = task.dueDate;

      switch (filter) {
        case TaskViewFilter.daily:
          matchesFilter = dueDate != null && dueDate.isSameDay(now);
          break;
        case TaskViewFilter.weekly:
          matchesFilter =
              dueDate != null &&
              dueDate.isAfter(
                startOfToday.subtract(const Duration(seconds: 1)),
              ) &&
              dueDate.isBefore(weeklyCutoff);
          break;
        case TaskViewFilter.monthly:
          matchesFilter =
              dueDate != null &&
              dueDate.year == now.year &&
              dueDate.month == now.month;
          break;
        case TaskViewFilter.all:
          matchesFilter = true;
          break;
      }

      if (!matchesFilter) continue;
      if (task.isCompleted) {
        if (showCompleted) completedTasks.add(task);
        continue;
      }
      quadrantGroups[task.quadrant]!.add(task);
    }

    final quadrantNames = ref.watch(quadrantNamesProvider);
    final hasIncompleteTasks = quadrantGroups.values.any(
      (group) => group.isNotEmpty,
    );
    final hasAnyTasks = completedTasks.isNotEmpty || hasIncompleteTasks;
    // Check if there are any tasks to show (completed or incomplete)
    if (!hasAnyTasks) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                size: 28,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              filter == TaskViewFilter.all && !showCompleted
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
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tap to add task',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
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
        // Show completed tasks section only if showCompleted is true and there are completed tasks
        if (showCompleted && completedTasks.isNotEmpty)
          _buildCompletedTasksSection(completedTasks, theme, colorScheme),
        // Show quadrant sections only for incomplete tasks
        ...Quadrant.values.map((quadrant) {
          final quadrantTasks = quadrantGroups[quadrant]!;
          if (quadrantTasks.isEmpty) return const SizedBox.shrink();

          return _buildListSection(
            quadrant,
            quadrantNames[quadrant] ?? _getQuadrantTitle(quadrant),
            _getQuadrantDescription(quadrant),
            _getQuadrantColor(quadrant),
            quadrantTasks,
            theme,
            colorScheme,
          );
        }),
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
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
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
              color: colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
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
              children: completedTasks.map((task) {
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
    Quadrant quadrant,
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
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () {
              HapticFeedback.mediumImpact();
              showAppDialog(
                context: context,
                builder: (_) =>
                    QuadrantEditDialog(quadrant: quadrant, currentName: title),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.2),
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
                      color: accentColor.withValues(alpha: 0.2),
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
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: tasks.map((task) {
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
    required Quadrant quadrant,
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
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () {
              HapticFeedback.mediumImpact();
              showAppDialog(
                context: context,
                builder: (_) =>
                    QuadrantEditDialog(quadrant: quadrant, currentName: title),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.2),
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
                            color: accentColor.withValues(alpha: 0.2),
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
                  SizedBox(
                    height: 32,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        description,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: DragTarget<Task>(
                onWillAcceptWithDetails: (details) =>
                    details.data.quadrant != quadrant,
                onAcceptWithDetails: (details) {
                  final updatedTask = details.data.copyWith(quadrant: quadrant);
                  ref.read(taskProvider.notifier).updateTask(updatedTask);
                  HapticFeedback.mediumImpact();
                },
                builder: (context, candidateData, rejectedData) {
                  final isDraggingOver = candidateData.isNotEmpty;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDraggingOver
                          ? accentColor.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: isDraggingOver
                          ? Border.all(
                              color: accentColor.withValues(alpha: 0.4),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: child,
                  );
                },
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
    Navigator.push(context, _fastRoute(const TaskEditScreen()));
  }

  PageRouteBuilder<void> _fastRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (_, __, ___, child) => child,
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentFilter = ref.read(filterProvider);

    showAppDialog(
      context: context,
      builder: (context) {
        return AppDialogContainer(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? colorScheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
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
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFilterDisplayName(TaskViewFilter filter) {
    switch (filter) {
      case TaskViewFilter.all:
        return 'All Tasks';
      case TaskViewFilter.daily:
        return 'Today';
      case TaskViewFilter.weekly:
        return 'This Week';
      case TaskViewFilter.monthly:
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
                    color: colorScheme.onPrimary.withValues(alpha: 0.8),
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
          ref
              .read(taskProvider.notifier)
              .updateTask(completedTask.copyWith(isCompleted: false));
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
