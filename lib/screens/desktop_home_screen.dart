import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus/screens/desktop_task_edit_screen.dart';
import 'package:window_manager/window_manager.dart';

import '../models/quadrant_enum.dart';
import '../models/task_models.dart';
import '../providers/filter_provider.dart';
import '../providers/quadrant_names_provider.dart';
import '../providers/show_completed_provider.dart';
import '../providers/task_provider.dart';
import '../providers/ui_preferences_provider.dart';
import '../services/desktop_event_bus.dart';
import '../services/desktop_offline_sync_service.dart';
import '../services/notification_service.dart';
import '../config/feature_flags.dart';
import '../widgets/command_palatte.dart';
import '../widgets/desktop_settings_flyout.dart';
import '../widgets/draggle_area.dart';
import '../widgets/app_dialog.dart';
import '../widgets/quadrant_edit_dialog.dart';
import '../widgets/task_tile.dart';
import '../widgets/window_controls.dart';

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

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class OpenShortcutHelpIntent extends Intent {
  const OpenShortcutHelpIntent();
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

const Color _q1 = Color(0xFFFF4757);
const Color _q2 = Color(0xFF2ED573);
const Color _q3 = Color(0xFFFFA726);
const Color _q4 = Color(0xFF747D8C);

Color _quadrantColor(Quadrant q) {
  switch (q) {
    case Quadrant.urgentImportant:
      return _q1;
    case Quadrant.notUrgentImportant:
      return _q2;
    case Quadrant.urgentNotImportant:
      return _q3;
    case Quadrant.notUrgentNotImportant:
      return _q4;
  }
}

String _quadrantName(Quadrant q) {
  switch (q) {
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

String _quadrantDisplayName(Map<Quadrant, String> names, Quadrant quadrant) {
  final customName = names[quadrant]?.trim();
  return customName == null || customName.isEmpty
      ? _quadrantName(quadrant)
      : customName;
}

bool _isDarkScheme(ColorScheme cs) => cs.brightness == Brightness.dark;

Color _surfaceTone(ColorScheme cs, {double dark = 0.72, double light = 0.86}) {
  return cs.surface.withValues(alpha: _isDarkScheme(cs) ? dark : light);
}

Color _surfaceInk(ColorScheme cs, {double dark = 0.55, double light = 0.72}) {
  return cs.onSurface.withValues(alpha: _isDarkScheme(cs) ? dark : light);
}

BoxDecoration _glassBox(
  ColorScheme cs, {
  double radius = 16,
  double borderOpacity = 0.10,
}) {
  return BoxDecoration(
    color: _surfaceTone(cs),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: _surfaceInk(cs, dark: borderOpacity, light: borderOpacity + 0.06),
      width: 0.5,
    ),
  );
}

ui.ImageFilter _blurFilter() => ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10);

class _PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;
  final bool filled;

  const _PillButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: filled
              ? c.withValues(alpha: 0.18)
              : _surfaceInk(cs, dark: 0.06, light: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: filled
                ? c.withValues(alpha: 0.35)
                : _surfaceInk(cs, dark: 0.10, light: 0.18),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: filled ? c : _surfaceInk(cs, dark: 0.55, light: 0.75),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: filled ? c : _surfaceInk(cs, dark: 0.55, light: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FloatingBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _surfaceInk(cs, dark: 0.07, light: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _surfaceInk(cs, dark: 0.10, light: 0.18),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chevron_left_rounded,
              size: 16,
              color: _surfaceInk(cs, dark: 0.55, light: 0.75),
            ),
            const SizedBox(width: 2),
            Text(
              'Back',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _surfaceInk(cs, dark: 0.55, light: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final cs = Theme.of(context).colorScheme;
    final filters = [
      TaskViewFilter.all,
      TaskViewFilter.daily,
      TaskViewFilter.weekly,
    ];
    final labels = ['All', 'Today', 'Week'];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _surfaceInk(cs, dark: 0.05, light: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _surfaceInk(cs, dark: 0.08, light: 0.16),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(filters.length, (i) {
          final selected = filter == filters[i];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              if (filter != filters[i]) {
                ref.read(filterProvider.notifier).state = filters[i];
              }
              if (!kIsWeb &&
                  (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS)) {
                HapticFeedback.selectionClick();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 70),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? _surfaceInk(cs, dark: 0.10, light: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? _surfaceInk(cs, dark: 0.12, light: 0.20)
                      : Colors.transparent,
                  width: 0.5,
                ),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? _surfaceInk(cs, dark: 0.92, light: 0.92)
                      : _surfaceInk(cs, dark: 0.45, light: 0.68),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _QuadrantItem extends StatelessWidget {
  final Quadrant quadrant;
  final String name;
  final bool selected;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final ValueChanged<Task>? onTaskDropped;

  const _QuadrantItem({
    required this.quadrant,
    required this.name,
    required this.selected,
    required this.count,
    required this.onTap,
    required this.onRename,
    this.onTaskDropped,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _quadrantColor(quadrant);
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) =>
          onTaskDropped != null && details.data.quadrant != quadrant,
      onAcceptWithDetails: (details) => onTaskDropped?.call(details.data),
      builder: (context, candidateData, rejectedData) {
        final dropActive = candidateData.isNotEmpty;
        final highlighted = selected || dropActive;
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: dropActive
                  ? color.withValues(alpha: 0.15)
                  : highlighted
                  ? _surfaceInk(cs, dark: 0.08, light: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: dropActive
                    ? color.withValues(alpha: 0.45)
                    : highlighted
                    ? _surfaceInk(cs, dark: 0.10, light: 0.18)
                    : Colors.transparent,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: highlighted
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: highlighted
                          ? _surfaceInk(cs, dark: 0.92, light: 0.92)
                          : _surfaceInk(cs, dark: 0.45, light: 0.68),
                    ),
                  ),
                ),
                if (highlighted) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Rename quadrant',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: onRename,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 12,
                          color: _surfaceInk(cs, dark: 0.45, light: 0.68),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: _surfaceInk(cs, dark: 0.06, light: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _surfaceInk(cs, dark: 0.08, light: 0.16),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: _surfaceInk(cs, dark: 0.45, light: 0.68),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TaskRow extends StatefulWidget {
  final Task task;
  final WidgetRef ref;
  final Map<Quadrant, String> quadrantNames;
  final ValueChanged<Quadrant> onMoveToQuadrant;

  const _TaskRow({
    required this.task,
    required this.ref,
    required this.quadrantNames,
    required this.onMoveToQuadrant,
    super.key,
  });

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final task = widget.task;

    Widget taskDragHandle(Widget child) {
      return LongPressDraggable<Task>(
        data: task,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedbackOffset: const Offset(18, 18),
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.95,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _surfaceInk(cs, dark: 0.10, light: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _surfaceInk(cs, dark: 0.14, light: 0.20),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _quadrantColor(task.quadrant),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _surfaceInk(cs, dark: 0.92, light: 0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: child),
        child: child,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: _hovered
              ? _surfaceInk(cs, dark: 0.08, light: 0.12)
              : _surfaceInk(cs, dark: 0.04, light: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered
                ? _surfaceInk(cs, dark: 0.12, light: 0.18)
                : _surfaceInk(cs, dark: 0.07, light: 0.12),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            taskDragHandle(
              TaskTile(
                task: task,
                key: ValueKey('${task.id}_${task.isCompleted}'),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              child: _hovered
                  ? Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: _surfaceInk(cs, dark: 0.07, light: 0.14),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          PopupMenuButton<Quadrant>(
                            tooltip: 'Move to quadrant',
                            color: cs.surface,
                            onSelected: widget.onMoveToQuadrant,
                            itemBuilder: (context) => Quadrant.values
                                .where((q) => q != task.quadrant)
                                .map(
                                  (q) => PopupMenuItem<Quadrant>(
                                    value: q,
                                    child: Text(
                                      _quadrantDisplayName(
                                        widget.quadrantNames,
                                        q,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            child: _stripAction(
                              icon: Icons.drive_file_move_rounded,
                              label: 'Move',
                              color: _surfaceInk(cs, dark: 0.55, light: 0.75),
                              onTap: () {},
                            ),
                          ),
                          _stripAction(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Complete',
                            color: _q2,
                            onTap: () {
                              widget.ref
                                  .read(taskProvider.notifier)
                                  .updateTask(
                                    task.copyWith(
                                      isCompleted: true,
                                      updatedAt: DateTime.now(),
                                    ),
                                  );
                            },
                          ),
                          const Spacer(),
                          _stripAction(
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete',
                            color: cs.error,
                            onTap: () => widget.ref
                                .read(taskProvider.notifier)
                                .deleteTask(task.id),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stripAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final ColorScheme colorScheme;

  const _StatChip({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: _glassBox(colorScheme, radius: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _surfaceInk(colorScheme, dark: 0.45, light: 0.68),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: valueColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _surfaceInk(cs, dark: 0.06, light: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _surfaceInk(cs, dark: 0.10, light: 0.18),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 13,
              color: _surfaceInk(cs, dark: 0.35, light: 0.58),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Search tasks…',
                style: TextStyle(
                  fontSize: 11.5,
                  color: _surfaceInk(cs, dark: 0.35, light: 0.58),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _surfaceInk(cs, dark: 0.06, light: 0.10),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _surfaceInk(cs, dark: 0.08, light: 0.16),
                  width: 0.5,
                ),
              ),
              child: Text(
                'Ctrl+K',
                style: TextStyle(
                  fontSize: 10,
                  color: _surfaceInk(cs, dark: 0.35, light: 0.58),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPill extends StatelessWidget {
  final GlobalKey settingsKey;
  const _SettingsPill({required this.settingsKey});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      key: settingsKey,
      onTap: () => showDesktopSettingsFlyout(context, settingsKey),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _surfaceInk(cs, dark: 0.06, light: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _surfaceInk(cs, dark: 0.10, light: 0.18),
            width: 0.5,
          ),
        ),
        child: Icon(
          Icons.settings_outlined,
          size: 14,
          color: _surfaceInk(cs, dark: 0.55, light: 0.75),
        ),
      ),
    );
  }
}

class _NearbySyncPill extends StatelessWidget {
  const _NearbySyncPill();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final syncService = DesktopOfflineSyncService.instance;

    return ValueListenableBuilder<DesktopSyncStatus>(
      valueListenable: syncService.statusNotifier,
      builder: (context, status, _) {
        final isHosting = status.isHosting;
        final recentlyConnected =
            status.lastClientSyncedAt != null &&
            DateTime.now().difference(status.lastClientSyncedAt!) <
                const Duration(minutes: 2);
        final dotColor = !isHosting
            ? _surfaceInk(cs, dark: 0.35, light: 0.58)
            : (recentlyConnected
                  ? const Color(0xFF2ED573)
                  : const Color(0xFFFFA726));
        final label = !isHosting
            ? 'Nearby: Offline'
            : (recentlyConnected ? 'Nearby: Connected' : 'Nearby: Hosting');

        return Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: _surfaceInk(cs, dark: 0.06, light: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _surfaceInk(cs, dark: 0.10, light: 0.18),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _surfaceInk(cs, dark: 0.55, light: 0.75),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DesktopHomeScreen extends ConsumerStatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  ConsumerState<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends ConsumerState<DesktopHomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final ProviderSubscription<List<Task>> _taskSubscription;
  final DesktopOfflineSyncService _offlineSyncService =
      DesktopOfflineSyncService.instance;
  StreamSubscription<DesktopShellEvent>? _desktopShellSub;
  Timer? _dueReminderTimer;
  Timer? _dueToastTimer;
  OverlayEntry? _dueToastEntry;
  final FocusNode _homeFocusNode = FocusNode();
  final Set<String> _dueReminderShown = <String>{};
  Quadrant _selectedQuadrant = Quadrant.urgentImportant;
  bool _isFocusMode = false;

  final GlobalKey _settingsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final reducedMotion = ref.read(uiPreferencesProvider).reducedMotion;
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reducedMotion ? 90 : 380),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    if (kEnableNearbySync) {
      _offlineSyncService.initialize();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _homeFocusNode.requestFocus();
    });

    _taskSubscription = ref.listenManual<List<Task>>(taskProvider, (
      prev,
      curr,
    ) {
      if (!mounted || prev == null) return;
      final completed = curr
          .where((t) => t.isCompleted)
          .where((t) => prev.any((p) => p.id == t.id && !p.isCompleted))
          .firstOrNull;
      if (completed != null) {
        _showSnackbar(context, completed);
      }
    });

    _desktopShellSub = DesktopEventBus.instance.stream.listen((event) async {
      if (!mounted) return;
      switch (event.type) {
        case DesktopShellEventType.showWindow:
          await windowManager.show();
          await windowManager.focus();
          break;
        case DesktopShellEventType.openCommandPalette:
          _openCommandPalette();
          break;
        case DesktopShellEventType.quickAddTask:
          await windowManager.show();
          await windowManager.focus();
          if (!mounted) return;
          _navigateToAddTask(context);
          break;
      }
    });

    final notificationService = NotificationService();
    notificationService.initialize();
    notificationService.onNotificationResponse = _handleNotificationResponse;
    _dueReminderTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _checkDueReminderFallback(),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkDueReminderFallback(),
    );
  }

  @override
  void dispose() {
    _taskSubscription.close();
    _desktopShellSub?.cancel();
    _dueReminderTimer?.cancel();
    _dueToastTimer?.cancel();
    _dueToastEntry?.remove();
    _dueToastEntry = null;
    NotificationService().onNotificationResponse = null;
    _homeFocusNode.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _openCommandPalette() {
    showDialog(
      context: context,
      builder: (_) => CommandPalette(
        onToggleFocusMode: _toggleFocusMode,
        onToggleShowCompleted: () =>
            ref.read(showCompletedTasksProvider.notifier).toggle(),
        onOpenSettings: () => showDesktopSettingsFlyout(context, _settingsKey),
        onOpenShortcuts: _showShortcutsHelp,
      ),
    ).then((_) {
      if (mounted) _homeFocusNode.requestFocus();
    });
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (!mounted) return;
    String? taskId = response.payload;
    String action = response.actionId ?? '';

    if (action.contains('::')) {
      final parts = action.split('::');
      action = parts.first;
      if (parts.length > 1 && parts[1].isNotEmpty) {
        taskId = parts[1];
      }
    }

    if (taskId == null || taskId.isEmpty) return;

    if (action == 'mark_done') {
      final tasks = ref.read(taskProvider);
      final task = tasks.where((t) => t.id == taskId).firstOrNull;
      if (task != null && !task.isCompleted) {
        ref
            .read(taskProvider.notifier)
            .updateTask(
              task.copyWith(isCompleted: true, updatedAt: DateTime.now()),
            );
      }
      return;
    }

    if (action == 'open_task') {
      final tasks = ref.read(taskProvider);
      final task = tasks.where((t) => t.id == taskId).firstOrNull;
      Navigator.push(context, _fastRoute(DesktopTaskEditScreen(task: task)));
      return;
    }
  }

  void _checkDueReminderFallback() {
    if (!mounted) return;
    final tasks = ref.read(taskProvider);
    final now = DateTime.now();
    final dueNow = tasks.where((t) {
      return !t.isCompleted && t.dueDate != null && !t.dueDate!.isAfter(now);
    });

    for (final task in dueNow) {
      if (_dueReminderShown.contains(task.id)) continue;
      _dueReminderShown.add(task.id);
      final notificationService = NotificationService();
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
        notificationService.showNow(
          id: notificationService.notificationIdForTask(task.id),
          title: 'Task Due: ${task.title}',
          body: task.notes ?? 'Your task is due now.',
          payload: task.id,
        );
      }
      _showDueToast(
        'Reminder: ${task.title} is due',
        onOpen: () {
          Navigator.push(
            context,
            _fastRoute(DesktopTaskEditScreen(task: task)),
          );
        },
      );
      break;
    }
  }

  void _showDueToast(String message, {VoidCallback? onOpen}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final cs = Theme.of(context).colorScheme;

    _dueToastTimer?.cancel();
    _dueToastEntry?.remove();

    _dueToastEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 18,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.alarm_rounded, color: cs.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (onOpen != null)
                    TextButton(
                      onPressed: () {
                        _dueToastTimer?.cancel();
                        _dueToastEntry?.remove();
                        _dueToastEntry = null;
                        onOpen();
                      },
                      child: const Text('Open'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_dueToastEntry!);
    _dueToastTimer = Timer(const Duration(seconds: 2), () {
      _dueToastEntry?.remove();
      _dueToastEntry = null;
    });
  }

  Map<ShortcutActivator, Intent> get _shortcuts => {
    const SingleActivator(LogicalKeyboardKey.keyK, control: true):
        const OpenCommandPaletteIntent(),
    const CharacterActivator('k', control: true):
        const OpenCommandPaletteIntent(),
    const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
        const OpenCommandPaletteIntent(),
    const SingleActivator(LogicalKeyboardKey.keyF, control: true):
        const ToggleFocusModeIntent(),
    const CharacterActivator('f', control: true): const ToggleFocusModeIntent(),
    const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
        const ToggleFocusModeIntent(),
    const SingleActivator(LogicalKeyboardKey.keyN, control: true):
        const AddTaskIntent(),
    const CharacterActivator('n', control: true): const AddTaskIntent(),
    const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
        const AddTaskIntent(),
    const SingleActivator(LogicalKeyboardKey.keyH, control: true):
        const ToggleShowCompletedIntent(),
    const CharacterActivator('h', control: true):
        const ToggleShowCompletedIntent(),
    const SingleActivator(LogicalKeyboardKey.keyH, meta: true):
        const ToggleShowCompletedIntent(),
    const SingleActivator(LogicalKeyboardKey.comma, control: true):
        const OpenSettingsIntent(),
    const CharacterActivator(',', control: true): const OpenSettingsIntent(),
    const SingleActivator(LogicalKeyboardKey.comma, meta: true):
        const OpenSettingsIntent(),
    const SingleActivator(LogicalKeyboardKey.slash, control: true):
        const OpenShortcutHelpIntent(),
    const CharacterActivator('/', control: true):
        const OpenShortcutHelpIntent(),
    const SingleActivator(LogicalKeyboardKey.slash, meta: true):
        const OpenShortcutHelpIntent(),
    const SingleActivator(LogicalKeyboardKey.f1):
        const OpenShortcutHelpIntent(),
    const SingleActivator(LogicalKeyboardKey.digit1):
        const SelectQuadrantIntent(Quadrant.urgentImportant),
    const SingleActivator(LogicalKeyboardKey.digit2):
        const SelectQuadrantIntent(Quadrant.notUrgentImportant),
    const SingleActivator(LogicalKeyboardKey.digit3):
        const SelectQuadrantIntent(Quadrant.urgentNotImportant),
    const SingleActivator(LogicalKeyboardKey.digit4):
        const SelectQuadrantIntent(Quadrant.notUrgentNotImportant),
  };

  KeyEventResult _handleHomeKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final keyboard = HardwareKeyboard.instance;
    final isCtrlOrMeta = keyboard.isControlPressed || keyboard.isMetaPressed;
    if (!isCtrlOrMeta) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyK:
        _openCommandPalette();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyN:
        _navigateToAddTask(context);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyF:
        _toggleFocusMode();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyH:
        ref.read(showCompletedTasksProvider.notifier).toggle();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.comma:
        showDesktopSettingsFlyout(context, _settingsKey);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.slash:
        _showShortcutsHelp();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  Map<Type, Action<Intent>> _actions(BuildContext ctx) => {
    OpenCommandPaletteIntent: CallbackAction<OpenCommandPaletteIntent>(
      onInvoke: (_) => _openCommandPalette(),
    ),
    ToggleFocusModeIntent: CallbackAction<ToggleFocusModeIntent>(
      onInvoke: (_) => _toggleFocusMode(),
    ),
    AddTaskIntent: CallbackAction<AddTaskIntent>(
      onInvoke: (_) => _navigateToAddTask(ctx),
    ),
    ToggleShowCompletedIntent: CallbackAction<ToggleShowCompletedIntent>(
      onInvoke: (_) => ref.read(showCompletedTasksProvider.notifier).toggle(),
    ),
    OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
      onInvoke: (_) => showDesktopSettingsFlyout(context, _settingsKey),
    ),
    OpenShortcutHelpIntent: CallbackAction<OpenShortcutHelpIntent>(
      onInvoke: (_) {
        _showShortcutsHelp();
        return null;
      },
    ),
    SelectQuadrantIntent: CallbackAction<SelectQuadrantIntent>(
      onInvoke: (i) {
        setState(() => _selectedQuadrant = i.quadrant);
        HapticFeedback.selectionClick();
        return null;
      },
    ),
  };

  void _toggleFocusMode() {
    setState(() => _isFocusMode = !_isFocusMode);
    HapticFeedback.mediumImpact();
  }

  void _navigateToAddTask(
    BuildContext ctx, {
    Quadrant? initialQuadrant,
    DateTime? suggestedDueDate,
  }) {
    Navigator.push(
      ctx,
      _fastRoute(
        DesktopTaskEditScreen(
          initialQuadrant: initialQuadrant,
          suggestedDueDate: suggestedDueDate,
        ),
      ),
    );
  }

  Future<void> _showRenameQuadrantDialog(Quadrant quadrant) async {
    final names = ref.read(quadrantNamesProvider);
    await showAppDialog<void>(
      context: context,
      builder: (_) => QuadrantEditDialog(
        quadrant: quadrant,
        currentName: _quadrantDisplayName(names, quadrant),
      ),
    );
  }

  PageRouteBuilder<void> _fastRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (_, __, ___, child) => child,
    );
  }

  Future<void> _showShortcutsHelp() async {
    await showAppDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final isLinuxDesktop =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
        final commandPaletteShortcut = isLinuxDesktop
            ? 'Ctrl + K (fallback: Ctrl + Alt + K)'
            : 'Ctrl + K';
        final shortcuts = <(String, String)>[
          ('Open Command Palette', commandPaletteShortcut),
          ('New Task', 'Ctrl + N'),
          ('Toggle Focus Mode', 'Ctrl + F'),
          ('Toggle Show Completed', 'Ctrl + H'),
          ('Open Settings', 'Ctrl + ,'),
          ('Show Shortcuts', 'Ctrl + / or F1'),
          ('Select Quadrant 1-4', '1, 2, 3, 4'),
          ('Save (Task Editor)', 'Ctrl + Enter'),
          ('Cancel/Back (Task Editor)', 'Esc'),
          ('Toggle Priority Panel (Task Editor)', 'Ctrl + Q'),
          ('Cycle Quick Dates (Task Editor)', 'Ctrl + D'),
          ('Select Quadrant (Task Editor)', 'Ctrl + 1/2/3/4'),
          ('Today / Tomorrow / Next Week', 'Ctrl + T / Y / W'),
          ('Clear Date & Time (Task Editor)', 'Ctrl + X'),
          ('Open Date Picker (Task Editor)', 'Ctrl + E'),
          ('Open Time Picker (Task Editor)', 'Ctrl + R'),
          ('Focus Title (Task Editor)', 'Ctrl + L'),
          ('Focus Notes (Task Editor)', 'Ctrl + N'),
        ];

        return AppDialogContainer(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keyboard Shortcuts',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: shortcuts
                          .map(
                            (s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.$1,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: cs.onSurface.withValues(
                                          alpha: 0.82,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.onSurface.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: cs.onSurface.withValues(
                                          alpha: 0.14,
                                        ),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      s.$2,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface.withValues(
                                          alpha: 0.72,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppDialogButton(
                    label: 'Close',
                    onTap: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (mounted) _homeFocusNode.requestFocus();
  }

  String _formatDueDate(DateTime d) {
    final diff = d.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return '${diff}d';
    return '${d.day}/${d.month}';
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  List<Task> _filtered(List<Task> tasks, TaskViewFilter f, bool showCompleted) {
    final now = DateTime.now();
    switch (f) {
      case TaskViewFilter.daily:
        return tasks
            .where((t) => t.dueDate != null && t.dueDate!.isSameDay(now))
            .toList();
      case TaskViewFilter.weekly:
        return tasks
            .where(
              (t) =>
                  t.dueDate != null &&
                  t.dueDate!.isAfter(now.subtract(const Duration(days: 1))) &&
                  t.dueDate!.isBefore(now.add(const Duration(days: 7))),
            )
            .toList();
      case TaskViewFilter.monthly:
        return tasks
            .where(
              (t) =>
                  t.dueDate != null &&
                  t.dueDate!.year == now.year &&
                  t.dueDate!.month == now.month,
            )
            .toList();
      default:
        return showCompleted
            ? tasks
            : tasks.where((t) => !t.isCompleted).toList();
    }
  }

  double _productivityScore(List<Task> tasks) {
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => t.isCompleted).length;
    final onTime = tasks
        .where(
          (t) =>
              t.isCompleted &&
              t.dueDate != null &&
              t.updatedAt.isBefore(t.dueDate!),
        )
        .length;
    return ((done / tasks.length) * 0.6 +
            (done > 0 ? onTime / done : 0.0) * 0.4) *
        100;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tasks = ref.watch(taskProvider);
    final quadrantNames = ref.watch(quadrantNamesProvider);
    final filter = ref.watch(filterProvider);
    final showCompleted = ref.watch(showCompletedTasksProvider).value ?? false;

    final all = _filtered(tasks, filter, showCompleted);
    final doneCnt = tasks
        .where(
          (t) =>
              t.isCompleted &&
              t.updatedAt.isAfter(
                DateTime.now().subtract(const Duration(days: 1)),
              ),
        )
        .length;
    final overdueCnt = all
        .where(
          (t) =>
              !t.isCompleted &&
              t.dueDate != null &&
              t.dueDate!.isBefore(DateTime.now()),
        )
        .length;
    final score = _productivityScore(tasks);

    return Focus(
      focusNode: _homeFocusNode,
      autofocus: true,
      onKeyEvent: _handleHomeKeyEvent,
      child: FocusableActionDetector(
        shortcuts: _shortcuts,
        actions: _actions(context),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => _homeFocusNode.requestFocus(),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Scaffold(
                backgroundColor: cs.surface,
                body: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      _buildMenuBar(cs),
                      Expanded(
                        child: _isFocusMode
                            ? _buildFocusView(all, cs, quadrantNames)
                            : _buildNormalView(
                                all,
                                cs,
                                quadrantNames,
                                doneCnt,
                                overdueCnt,
                                score,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuBar(ColorScheme cs) {
    final dividerColor = _surfaceInk(cs, dark: 0.07, light: 0.16);
    return DraggableArea(
      height: 52,
      backgroundColor: Colors.transparent,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: dividerColor, width: 0.5)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            final left = <Widget>[
              WindowControls(colorScheme: cs),
              const SizedBox(width: 12),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/512x512_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint(
                        'Failed to load logo asset assets/images/512x512_logo.png: $error',
                      );
                      return Center(
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: cs.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Focus',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 14),
              _SearchPill(onTap: _openCommandPalette),
            ];

            final right = <Widget>[
              if (kEnableNearbySync) const _NearbySyncPill(),
              const SizedBox(width: 8),
              _PillButton(
                label: 'Shortcuts',
                icon: Icons.keyboard_command_key_rounded,
                onTap: () => _showShortcutsHelp(),
              ),
              const SizedBox(width: 8),
              const _FilterChips(),
              const SizedBox(width: 10),
              _PillButton(
                label: 'New task',
                icon: Icons.add_rounded,
                filled: true,
                color: cs.primary,
                onTap: () => _navigateToAddTask(context),
              ),
              const SizedBox(width: 8),
              _SettingsPill(settingsKey: _settingsKey),
            ];

            if (isWide) {
              return Row(children: [...left, const Spacer(), ...right]);
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [...left, const SizedBox(width: 16), ...right],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNormalView(
    List<Task> tasks,
    ColorScheme cs,
    Map<Quadrant, String> quadrantNames,
    int doneCnt,
    int overdueCnt,
    double score,
  ) {
    final compactDensity = ref.watch(uiPreferencesProvider).compactDensity;
    final pending = tasks.where((t) => !t.isCompleted).toList();
    final upcoming = List<Task>.from(pending)
      ..sort((a, b) {
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    final recentCompleted =
        tasks
            .where(
              (t) =>
                  t.isCompleted &&
                  t.updatedAt.isAfter(
                    DateTime.now().subtract(const Duration(hours: 24)),
                  ),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compactDensity ? 8 : 10,
        compactDensity ? 6 : 8,
        compactDensity ? 8 : 10,
        compactDensity ? 8 : 10,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 980;
          final isUltraWide = constraints.maxWidth >= 1500;
          final gutter = compactDensity ? 6.0 : 8.0;

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 180,
                  child: _buildSidebar(tasks, cs, quadrantNames),
                ),
                SizedBox(height: gutter),
                Expanded(child: _buildTaskList(tasks, cs, quadrantNames)),
                SizedBox(height: gutter),
                SizedBox(
                  height: 280,
                  child: _buildInsights(
                    tasks,
                    cs,
                    doneCnt,
                    overdueCnt,
                    score,
                    upcoming,
                    recentCompleted,
                  ),
                ),
              ],
            );
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 210,
                    child: _buildSidebar(tasks, cs, quadrantNames),
                  ),
                  SizedBox(width: gutter),
                  Expanded(child: _buildTaskList(tasks, cs, quadrantNames)),
                  if (isUltraWide) ...[
                    SizedBox(width: gutter),
                    SizedBox(
                      width: 250,
                      child: _buildWideMatrixPanel(
                        tasks: tasks,
                        cs: cs,
                        quadrantNames: quadrantNames,
                      ),
                    ),
                  ],
                  SizedBox(width: gutter),
                  SizedBox(
                    width: 220,
                    child: _buildInsights(
                      tasks,
                      cs,
                      doneCnt,
                      overdueCnt,
                      score,
                      upcoming,
                      recentCompleted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWideMatrixPanel({
    required List<Task> tasks,
    required ColorScheme cs,
    required Map<Quadrant, String> quadrantNames,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: _blurFilter(),
        child: Container(
          decoration: _glassBox(cs, radius: 16),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.grid_view_rounded, size: 13, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Matrix overview',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _surfaceInk(cs, dark: 0.92, light: 0.92),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 1,
                  childAspectRatio: 2.25,
                  mainAxisSpacing: 8,
                  children: Quadrant.values.map((q) {
                    final qTasks = tasks
                        .where((t) => t.quadrant == q && !t.isCompleted)
                        .toList();
                    final overdue = qTasks
                        .where(
                          (t) =>
                              t.dueDate != null &&
                              t.dueDate!.isBefore(DateTime.now()),
                        )
                        .length;
                    final top = qTasks.where((t) => t.dueDate != null).toList()
                      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
                    final active = _selectedQuadrant == q;
                    final color = _quadrantColor(q);

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedQuadrant = q);
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: active
                              ? color.withValues(alpha: 0.12)
                              : _surfaceInk(cs, dark: 0.05, light: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active
                                ? color.withValues(alpha: 0.45)
                                : _surfaceInk(cs, dark: 0.08, light: 0.16),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _quadrantDisplayName(quadrantNames, q),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _surfaceInk(
                                        cs,
                                        dark: 0.92,
                                        light: 0.92,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${qTasks.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              overdue > 0 ? '$overdue overdue' : 'All on track',
                              style: TextStyle(
                                fontSize: 10,
                                color: overdue > 0
                                    ? _q1
                                    : _surfaceInk(cs, dark: 0.45, light: 0.68),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              top.isEmpty ? 'No due task set' : top.first.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: _surfaceInk(cs, dark: 0.55, light: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Divider(
                color: _surfaceInk(cs, dark: 0.08, light: 0.16),
                thickness: 0.5,
                height: 16,
              ),
              Text(
                'Tip: pick a quadrant to narrow attention.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: _surfaceInk(cs, dark: 0.45, light: 0.68),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(
    List<Task> tasks,
    ColorScheme cs,
    Map<Quadrant, String> quadrantNames,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: _blurFilter(),
        child: Container(
          decoration: _glassBox(cs, radius: 16),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Text(
                  'Quadrants',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _surfaceInk(cs, dark: 0.45, light: 0.68),
                    letterSpacing: 0.06,
                  ),
                ),
              ),
              ...Quadrant.values.map((q) {
                final cnt = tasks
                    .where((t) => t.quadrant == q && !t.isCompleted)
                    .length;
                return _QuadrantItem(
                  quadrant: q,
                  name: _quadrantDisplayName(quadrantNames, q),
                  selected: _selectedQuadrant == q,
                  count: cnt,
                  onTap: () {
                    setState(() => _selectedQuadrant = q);
                    HapticFeedback.selectionClick();
                  },
                  onRename: () => _showRenameQuadrantDialog(q),
                  onTaskDropped: (task) {
                    if (task.quadrant == q) return;
                    ref
                        .read(taskProvider.notifier)
                        .moveTaskToQuadrant(task.id, q);
                    HapticFeedback.mediumImpact();
                  },
                );
              }),
              const Spacer(),
              Divider(
                color: _surfaceInk(cs, dark: 0.08, light: 0.16),
                thickness: 0.5,
                height: 16,
              ),
              _PillButton(
                label: _isFocusMode ? 'Exit Focus' : 'Focus Mode',
                icon: Icons.center_focus_strong_rounded,
                filled: _isFocusMode,
                color: cs.primary,
                onTap: _toggleFocusMode,
              ),
              const SizedBox(height: 6),
              _PillButton(
                label: 'New task',
                icon: Icons.add_rounded,
                filled: true,
                color: cs.primary,
                onTap: () => _navigateToAddTask(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(
    List<Task> tasks,
    ColorScheme cs,
    Map<Quadrant, String> quadrantNames,
  ) {
    final scoped = tasks
        .where((t) => t.quadrant == _selectedQuadrant && !t.isCompleted)
        .toList();
    final color = _quadrantColor(_selectedQuadrant);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: _blurFilter(),
        child: Container(
          decoration: _glassBox(cs, radius: 16),
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _quadrantDisplayName(quadrantNames, _selectedQuadrant),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _surfaceInk(cs, dark: 0.92, light: 0.92),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _surfaceInk(cs, dark: 0.06, light: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _surfaceInk(cs, dark: 0.08, light: 0.16),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '${scoped.length} items',
                      style: TextStyle(
                        fontSize: 11,
                        color: _surfaceInk(cs, dark: 0.45, light: 0.68),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: scoped.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Nothing here yet.',
                              style: TextStyle(
                                fontSize: 12,
                                color: _surfaceInk(cs, dark: 0.35, light: 0.58),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _PillButton(
                                  label: 'Create task',
                                  icon: Icons.add_rounded,
                                  onTap: () => _navigateToAddTask(context),
                                ),
                                _PillButton(
                                  label: 'Open search',
                                  icon: Icons.search_rounded,
                                  onTap: _openCommandPalette,
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: scoped.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 5),
                        itemBuilder: (ctx, i) => _TaskRow(
                          task: scoped[i],
                          ref: ref,
                          quadrantNames: quadrantNames,
                          onMoveToQuadrant: (q) {
                            ref
                                .read(taskProvider.notifier)
                                .moveTaskToQuadrant(scoped[i].id, q);
                          },
                          key: ValueKey(scoped[i].id),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsights(
    List<Task> tasks,
    ColorScheme cs,
    int doneCnt,
    int overdueCnt,
    double score,
    List<Task> upcoming,
    List<Task> recentCompleted,
  ) {
    return Column(
      children: [
        Row(
          children: [
            _StatChip(
              label: 'Done',
              value: '$doneCnt',
              valueColor: _q2,
              colorScheme: cs,
            ),
            const SizedBox(width: 6),
            _StatChip(
              label: 'Open',
              value: '${tasks.where((t) => !t.isCompleted).length}',
              valueColor: cs.primary,
              colorScheme: cs,
            ),
            const SizedBox(width: 6),
            _StatChip(
              label: 'Late',
              value: '$overdueCnt',
              valueColor: _q1,
              colorScheme: cs,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: _blurFilter(),
              child: Container(
                decoration: _glassBox(cs, radius: 16),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 13,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Insights',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _surfaceInk(cs, dark: 0.92, light: 0.92),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (overdueCnt > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _q1.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _q1.withValues(alpha: 0.22),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 13,
                              color: _q1,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                '$overdueCnt task${overdueCnt > 1 ? 's' : ''} overdue',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _q1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      'Next up',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _surfaceInk(cs, dark: 0.45, light: 0.68),
                        letterSpacing: 0.05,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _surfaceInk(cs, dark: 0.05, light: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _surfaceInk(cs, dark: 0.08, light: 0.16),
                          width: 0.5,
                        ),
                      ),
                      child: upcoming.isEmpty
                          ? Text(
                              'No upcoming tasks.',
                              style: TextStyle(
                                fontSize: 11,
                                color: _surfaceInk(cs, dark: 0.35, light: 0.58),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  upcoming.first.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _surfaceInk(
                                      cs,
                                      dark: 0.92,
                                      light: 0.92,
                                    ),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (upcoming.first.dueDate != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      _formatDueDate(upcoming.first.dueDate!),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            upcoming.first.dueDate!.isBefore(
                                              DateTime.now(),
                                            )
                                            ? _q1
                                            : _surfaceInk(
                                                cs,
                                                dark: 0.45,
                                                light: 0.68,
                                              ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Recently completed',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _surfaceInk(cs, dark: 0.45, light: 0.68),
                        letterSpacing: 0.05,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _surfaceInk(cs, dark: 0.05, light: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _surfaceInk(cs, dark: 0.08, light: 0.16),
                          width: 0.5,
                        ),
                      ),
                      child: recentCompleted.isEmpty
                          ? Text(
                              'No tasks completed in last 24h.',
                              style: TextStyle(
                                fontSize: 11,
                                color: _surfaceInk(cs, dark: 0.35, light: 0.58),
                              ),
                            )
                          : Column(
                              children: recentCompleted.take(3).map((task) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 12,
                                        color: _q2,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: _surfaceInk(
                                              cs,
                                              dark: 0.90,
                                              light: 0.90,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _timeAgo(task.updatedAt),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _surfaceInk(
                                            cs,
                                            dark: 0.45,
                                            light: 0.68,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Productivity',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _surfaceInk(cs, dark: 0.45, light: 0.68),
                            letterSpacing: 0.05,
                          ),
                        ),
                        Text(
                          '${score.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _q2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: score / 100,
                        minHeight: 4,
                        backgroundColor: _surfaceInk(
                          cs,
                          dark: 0.08,
                          light: 0.16,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(_q2),
                      ),
                    ),
                    const Spacer(),
                    Divider(
                      color: _surfaceInk(cs, dark: 0.08, light: 0.16),
                      thickness: 0.5,
                      height: 16,
                    ),
                    _PillButton(
                      label: _isFocusMode ? 'Exit Focus' : 'Enter Focus Mode',
                      icon: Icons.center_focus_strong_rounded,
                      filled: _isFocusMode,
                      color: cs.primary,
                      onTap: _toggleFocusMode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusView(
    List<Task> tasks,
    ColorScheme cs,
    Map<Quadrant, String> quadrantNames,
  ) {
    final q = _selectedQuadrant;
    final color = _quadrantColor(q);
    final scoped = tasks
        .where((t) => t.quadrant == q && !t.isCompleted)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: _blurFilter(),
              child: Container(
                decoration: _glassBox(cs, radius: 20),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _FloatingBackButton(onTap: _toggleFocusMode),
                        const SizedBox(width: 12),
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _quadrantDisplayName(quadrantNames, q),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _surfaceInk(cs, dark: 0.92, light: 0.92),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${scoped.length} remaining',
                          style: TextStyle(
                            fontSize: 11,
                            color: _surfaceInk(cs, dark: 0.45, light: 0.68),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: scoped.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.celebration_rounded,
                                    size: 48,
                                    color: color.withValues(alpha: 0.55),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'All clear! 🎉',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: _surfaceInk(
                                        cs,
                                        dark: 0.95,
                                        light: 0.95,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '0 remaining • Great job clearing this quadrant.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _surfaceInk(
                                        cs,
                                        dark: 0.55,
                                        light: 0.70,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _navigateToAddTask(context),
                                      borderRadius: BorderRadius.circular(999),
                                      child: Ink(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _surfaceInk(
                                            cs,
                                            dark: 0.08,
                                            light: 0.14,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: _surfaceInk(
                                              cs,
                                              dark: 0.16,
                                              light: 0.26,
                                            ),
                                            width: 0.6,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add_rounded,
                                              size: 16,
                                              color: _surfaceInk(
                                                cs,
                                                dark: 0.92,
                                                light: 0.92,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Add task to ${_quadrantDisplayName(quadrantNames, q)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _surfaceInk(
                                                  cs,
                                                  dark: 0.92,
                                                  light: 0.92,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Ctrl + N to add quickly',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _surfaceInk(
                                        cs,
                                        dark: 0.42,
                                        light: 0.62,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Esc to exit Focus Mode',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _surfaceInk(
                                        cs,
                                        dark: 0.42,
                                        light: 0.62,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: scoped.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 5),
                              itemBuilder: (ctx, i) => _TaskRow(
                                task: scoped[i],
                                ref: ref,
                                quadrantNames: quadrantNames,
                                onMoveToQuadrant: (q) {
                                  ref
                                      .read(taskProvider.notifier)
                                      .moveTaskToQuadrant(scoped[i].id, q);
                                },
                                key: ValueKey(scoped[i].id),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackbar(BuildContext ctx, Task task) {
    final messenger = ScaffoldMessenger.of(ctx);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Completed!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _q2,
        behavior: SnackBarBehavior.floating,
        width: 360,
        margin: const EdgeInsets.fromLTRB(0, 14, 0, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dismissDirection: DismissDirection.up,
        duration: const Duration(seconds: 2),
        persist: false,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            ref
                .read(taskProvider.notifier)
                .updateTask(task.copyWith(isCompleted: false));
          },
        ),
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
