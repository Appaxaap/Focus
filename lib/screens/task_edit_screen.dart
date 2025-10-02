import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import '../models/quadrant_enum.dart';
import '../models/task_models.dart';
import '../providers/task_provider.dart';
import '../widgets/quadrant_button.dart';
import '../widgets/text_fields.dart';

class TaskEditScreen extends ConsumerStatefulWidget {
  final Task? task;
  final Quadrant? initialQuadrant;
  final DateTime? suggestedDueDate;
  const TaskEditScreen({
    super.key,
    this.task,
    this.initialQuadrant,
    this.suggestedDueDate,
  });

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen>
    with TickerProviderStateMixin {
  late TextEditingController titleController;
  late TextEditingController notesController;
  late Quadrant? selectedQuadrant;
  late DateTime? selectedDate;
  late TimeOfDay? selectedTime;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers and variables
    titleController = TextEditingController(text: widget.task?.title ?? '');
    notesController = TextEditingController(text: widget.task?.notes ?? '');
    selectedQuadrant = widget.task?.quadrant ?? widget.initialQuadrant;
    selectedDate = widget.task?.dueDate;
    selectedTime = widget.task?.dueDate != null
        ? TimeOfDay.fromDateTime(widget.task!.dueDate!)
        : null;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // 🔥 LOG DEVICE TIMEZONE
    if (kDebugMode) {
      try {
        final String tzName = tz.local.name;
        final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
        final Duration offset = now.timeZoneOffset;
        final String offsetStr =
            '${offset.isNegative ? "-" : "+"}'
            '${offset.inHours.abs()}:${(offset.inMinutes.remainder(60)).toString().padLeft(2, '0')}';

        print('📍 TaskEditScreen initialized');
        print('🌍 Device Timezone: $tzName');
        print('🕒 UTC Offset: $offsetStr');
        print('📅 Selected Date: $selectedDate');
        print('⏰ Selected Time: $selectedTime');
      } catch (e) {
        print('❌ Failed to get timezone: $e');
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Helper methods for theme-specific colors
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

  Map<Quadrant, Map<String, dynamic>> get quadrantInfo => {
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final screenHeight = screenSize.height;
    final isShortScreen = screenHeight < 700;

    // Calculate responsive values
    final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
    final appBarTitleSize = isSmallScreen ? 32.0 : 40.0;
    final backButtonSize = screenSize.width * 0.14; // 14% of width
    final backButtonMargin = screenSize.width * 0.025; // 2.5% of width
    final toolbarHeight = isShortScreen ? 80.0 : 90.0;
    final sectionSpacing = isShortScreen ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leadingWidth: backButtonSize + (backButtonMargin * 2) + 16,
        leading: Container(
          width: backButtonSize,
          height: backButtonSize,
          margin: EdgeInsets.all(backButtonMargin),
          decoration: BoxDecoration(
            color: _getContainerBackgroundColor(context),
            borderRadius: BorderRadius.circular(backButtonSize / 2),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: _getIconColor(context),
              size: isSmallScreen ? 20 : 24,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(
              width: backButtonSize,
              height: backButtonSize,
            ),
            alignment: Alignment.center,
          ),
        ),
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              isEditing ? 'Edit Task' : 'New Task',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: appBarTitleSize,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Text(
              'Add your priority',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w400,
                height: 1.0,
              ),
            ),
          ],
        ),
        toolbarHeight: toolbarHeight,
        actions: [
          if (isEditing)
            Padding(
              padding: EdgeInsets.only(right: horizontalPadding - 4),
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                  size: isSmallScreen ? 20 : 24,
                ),
                onPressed: () => _showDeleteConfirmation(context),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isShortScreen ? 16 : 20,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - (isShortScreen ? 32 : 40),
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTitleTextField(
                      controller: titleController,
                      colorScheme: colorScheme,
                    ),
                    SizedBox(height: isShortScreen ? 8 : 10),
                    CustomNotesTextField(
                      controller: notesController,
                      colorScheme: colorScheme,
                    ),
                    SizedBox(height: sectionSpacing),
                    Text(
                      'Due Date and Time',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: isShortScreen ? 12 : 16),
                    CustomDateTimeField(
                      selectedDate: selectedDate,
                      selectedTime: selectedTime,
                      onTap: _selectDate,
                      colorScheme: colorScheme,
                      onClear: () {
                        setState(() {
                          selectedDate = null;
                          selectedTime = null;
                        });
                      },
                    ),
                    SizedBox(height: sectionSpacing),
                    Text(
                      'Priority Quadrant',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: isShortScreen ? 12 : 16),
                    QuadrantSelector(
                      initialQuadrant: selectedQuadrant,
                      onQuadrantSelected: (quadrant) {
                        setState(() {
                          selectedQuadrant = quadrant;
                        });
                      },
                      animationController: _animationController,
                    ),
                    SizedBox(height: isShortScreen ? 24 : 40),
                    _buildAddTaskButton(isEditing, colorScheme, screenSize),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddTaskButton(
    bool isEditing,
    ColorScheme colorScheme,
    Size screenSize,
  ) {
    final isSmallScreen = screenSize.width < 400;
    final buttonHeight = isSmallScreen ? 56.0 : 64.0;
    final fontSize = isSmallScreen ? 14.0 : 16.0;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: _saveTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 28 : 32),
          ),
          elevation: 0,
        ),
        child: Text(
          isEditing ? 'Update task' : 'Add task',
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedTime ?? TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                surface: Theme.of(context).colorScheme.surface,
                onSurface: Theme.of(context).colorScheme.onSurface,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            child: child!,
          );
        },
      );
      if (pickedTime != null) {
        setState(() {
          selectedTime = pickedTime;
        });
      }
    }
  }

  /// saving the task
  Future<void> _saveTask() async {
    final String title = titleController.text.trim();
    final String? notes = notesController.text.trim().isEmpty
        ? null
        : notesController.text.trim();

    // Validation
    if (title.isEmpty) {
      _showSnackbar(context, 'Please enter a task title', isError: true);
      return;
    }
    if (selectedQuadrant == null) {
      _showSnackbar(
        context,
        'Please select a priority quadrant',
        isError: true,
      );
      return;
    }

    // DateTime handling with timezone awareness
    DateTime? finalDateTime;
    if (selectedDate != null) {
      try {
        finalDateTime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          selectedTime?.hour ?? 9, // Default to 9 AM if no time selected
          selectedTime?.minute ?? 0,
        );

        // Convert to timezone-aware datetime
        final tz.TZDateTime tzDateTime = tz.TZDateTime.from(
          finalDateTime,
          tz.local,
        );

        if (!tzDateTime.isAfter(tz.TZDateTime.now(tz.local))) {
          _showSnackbar(
            context,
            'Please select a future date and time',
            isError: true,
          );
          return;
        }

        if (kDebugMode) {
          print('🕒 Final DateTime validation:');
          print('   📅 Selected Date: $selectedDate');
          print('   ⏰ Selected Time: $selectedTime');
          print('   🎯 Final DateTime: $finalDateTime');
          print('   🌍 TZ DateTime: $tzDateTime');
          print('   📍 Current Time: ${tz.TZDateTime.now(tz.local)}');
          print(
            '   ⏳ Time Until: ${tzDateTime.difference(tz.TZDateTime.now(tz.local))}',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ DateTime conversion error: $e');
        }
        _showSnackbar(context, 'Invalid date/time selection', isError: true);
        return;
      }
    }

    final notificationService = NotificationService();
    final bool isEditing = widget.task != null;
    final String taskId = widget.task?.id ?? const Uuid().v4();
    final int notificationId = taskId.hashCode;

    // Cancel existing notification if editing
    if (isEditing) {
      await notificationService.cancelNotification(notificationId);
      if (kDebugMode) {
        print('🗑️ Cancelled existing notification for task: $taskId');
      }
    }

    bool notificationScheduled = false;
    String? notificationError;

    // Schedule notification if datetime is set
    if (finalDateTime != null) {
      try {
        // 1. Initialize service
        await notificationService.onReady;

        // 2. Check and request permissions
        final hasPermissions = await notificationService
            .requestAllPermissions();

        if (!hasPermissions) {
          notificationError =
              'Notification permissions required for reminders.';
          if (kDebugMode) {
            print('❌ Permissions denied, but continuing to save task');
          }
        } else {
          // 3. Convert to timezone-aware datetime
          final tz.TZDateTime scheduledTime = tz.TZDateTime.from(
            finalDateTime,
            tz.local,
          );

          // 4. Schedule notification
          await notificationService.scheduleNotification(
            id: notificationId,
            title: 'Task Due: $title',
            body: notes ?? "Time for your task: $title",
            scheduledDate: scheduledTime,
            payload: taskId,
          );

          notificationScheduled = true;

          if (kDebugMode) {
            print('✅ Notification scheduled successfully!');
            print('   🎯 Scheduled Time: $scheduledTime');
            print(
              '   ⏳ Time Until: ${scheduledTime.difference(tz.TZDateTime.now(tz.local))}',
            );

            // Debug pending notifications
            await notificationService.debugPendingNotifications();
          }
        }
      } catch (e, stackTrace) {
        notificationError = 'Failed to schedule notification: ${e.toString()}';
        if (kDebugMode) {
          print('❌ Notification scheduling error:');
          print('   🚨 Error: $e');
          print('   📍 Type: ${e.runtimeType}');
          print('   📚 Stack: $stackTrace');
        }
      }
    }

    // Create and save the task
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

    if (kDebugMode) {
      print('💾 Task saved:');
      print('   🆔 ID: ${newTask.id}');
      print('   📧 Title: ${newTask.title}');
      print('   📅 Due: ${newTask.dueDate}');
      print('   🔔 Notification: $notificationScheduled');
    }

    // Show feedback to user
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
          timeMessage = ' (very soon!)';
        }

        _showSnackbar(
          context,
          'Task saved with reminder$timeMessage',
          isError: false,
        );
      } else if (notificationError != null) {
        _showSnackbar(context, notificationError, isError: true);
      } else {
        _showSnackbar(context, 'Task saved!', isError: false);
      }

      // Small delay before navigation
      await Future.delayed(const Duration(milliseconds: 300));
      Navigator.pop(context);
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Delete Task',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(taskProvider.notifier).deleteTask(widget.task!.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(
              'Delete',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 16 : 24,
        ),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: colorScheme.onError,
              size: isSmallScreen ? 20 : 24,
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onError,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        ),
      ),
    );
  }
}
