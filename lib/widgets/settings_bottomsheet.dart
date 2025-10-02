import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/show_completed_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';

class SettingsBottomSheet extends ConsumerStatefulWidget {
  const SettingsBottomSheet({super.key});

  @override
  ConsumerState<SettingsBottomSheet> createState() =>
      _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends ConsumerState<SettingsBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Spring-based width animation controllers for each button
  late AnimationController _darkWidthController;
  late AnimationController _lightWidthController;
  late AnimationController _infoWidthController;

  // Width animations with spring physics
  late Animation<double> _darkWidthAnimation;
  late Animation<double> _lightWidthAnimation;
  late Animation<double> _infoWidthAnimation;

  // Scale animations for pressed state
  late AnimationController _darkPressController;
  late AnimationController _lightPressController;
  late AnimationController _infoPressController;

  late Animation<double> _darkPressScale;
  late Animation<double> _lightPressScale;
  late Animation<double> _infoPressScale;

  static const double _baseFlexValue = 1.0;
  static const double _expandedFlexValue = 1.12;
  static const double _compressedFlexValue = 0.92;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _slideController,
            curve: const Cubic(0.05, 0.7, 0.1, 1.0),
            reverseCurve: const Cubic(0.3, 0.0, 0.8, 0.15),
          ),
        );

    _darkWidthController = AnimationController(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _lightWidthController = AnimationController(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _infoWidthController = AnimationController(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _darkPressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    _lightPressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    _infoPressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );

    _darkWidthAnimation =
        Tween<double>(begin: _baseFlexValue, end: _baseFlexValue).animate(
          CurvedAnimation(
            parent: _darkWidthController,
            curve: const Cubic(0.2, 0.0, 0.0, 1.0),
            reverseCurve: Curves.elasticOut,
          ),
        );

    _lightWidthAnimation =
        Tween<double>(begin: _baseFlexValue, end: _baseFlexValue).animate(
          CurvedAnimation(
            parent: _lightWidthController,
            curve: const Cubic(0.2, 0.0, 0.0, 1.0),
            reverseCurve: Curves.elasticOut,
          ),
        );

    _infoWidthAnimation =
        Tween<double>(begin: _baseFlexValue, end: _baseFlexValue).animate(
          CurvedAnimation(
            parent: _infoWidthController,
            curve: const Cubic(0.2, 0.0, 0.0, 1.0),
            reverseCurve: Curves.elasticOut,
          ),
        );

    _darkPressScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _darkPressController, curve: Curves.easeOut),
    );

    _lightPressScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _lightPressController, curve: Curves.easeOut),
    );

    _infoPressScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _infoPressController, curve: Curves.easeOut),
    );

    _slideController.forward();
  }

  void _triggerWidthReaction(String pressedButton) {
    _resetAllWidthAnimations();
    Future.delayed(const Duration(milliseconds: 10), () {
      switch (pressedButton) {
        case 'dark':
          _animateButtonWidth(
            _darkWidthController,
            _darkWidthAnimation,
            _expandedFlexValue,
          );
          _animateButtonWidth(
            _lightWidthController,
            _lightWidthAnimation,
            _compressedFlexValue,
          );
          _animateButtonWidth(
            _infoWidthController,
            _infoWidthAnimation,
            _baseFlexValue,
          );
          break;
        case 'light':
          _animateButtonWidth(
            _darkWidthController,
            _darkWidthAnimation,
            _compressedFlexValue,
          );
          _animateButtonWidth(
            _lightWidthController,
            _lightWidthAnimation,
            _expandedFlexValue,
          );
          _animateButtonWidth(
            _infoWidthController,
            _infoWidthAnimation,
            _compressedFlexValue,
          );
          break;
        case 'info':
          _animateButtonWidth(
            _darkWidthController,
            _darkWidthAnimation,
            _baseFlexValue,
          );
          _animateButtonWidth(
            _lightWidthController,
            _lightWidthAnimation,
            _compressedFlexValue,
          );
          _animateButtonWidth(
            _infoWidthController,
            _infoWidthAnimation,
            _expandedFlexValue,
          );
          break;
      }
      Future.delayed(const Duration(milliseconds: 320), () {
        _resetToNormalWidths();
      });
    });
  }

  void _animateButtonWidth(
    AnimationController controller,
    Animation<double> animation,
    double targetValue,
  ) {
    final newTween = Tween<double>(begin: animation.value, end: targetValue);
    final newAnimation = newTween.animate(
      CurvedAnimation(
        parent: controller,
        curve: const Cubic(0.2, 0.0, 0.0, 1.0),
        reverseCurve: Curves.elasticOut,
      ),
    );

    if (controller == _darkWidthController) {
      _darkWidthAnimation = newAnimation;
    } else if (controller == _lightWidthController) {
      _lightWidthAnimation = newAnimation;
    } else if (controller == _infoWidthController) {
      _infoWidthAnimation = newAnimation;
    }

    controller.reset();
    controller.forward();
  }

  void _resetAllWidthAnimations() {
    _darkWidthController.reset();
    _lightWidthController.reset();
    _infoWidthController.reset();
  }

  void _resetToNormalWidths() {
    _animateSnapBack(_darkWidthController);
    _animateSnapBack(_lightWidthController);
    _animateSnapBack(_infoWidthController);
  }

  void _animateSnapBack(AnimationController controller) {
    controller.animateBack(
      0.0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  Future<String> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return 'Version ${info.version}+${info.buildNumber}';
    } catch (e) {
      return 'Version Unknown';
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _darkWidthController.dispose();
    _lightWidthController.dispose();
    _infoWidthController.dispose();
    _darkPressController.dispose();
    _lightPressController.dispose();
    _infoPressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    final showCompletedAsync = ref.watch(showCompletedTasksProvider);
    final showCompleted = showCompletedAsync.value ?? false;
    final allTasks = ref.watch(taskProvider);
    final completedCount = allTasks.where((task) => task.isCompleted).length;
    final totalTaskCount = allTasks.length;
    final colorScheme = _getColorScheme(appTheme);

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(colorScheme),
            const SizedBox(height: 20),
            _buildGreetingHeader(colorScheme, completedCount),
            if (totalTaskCount == 0) ...[
              const SizedBox(height: 16),
              _buildEmptyStatePrompt(colorScheme),
            ],
            const SizedBox(height: 16),
            _buildThemeSelectionRow(appTheme, colorScheme),
            const SizedBox(height: 16),
            _buildCompletedTasksSection(showCompleted, colorScheme),
            const SizedBox(height: 16),
            _buildClearCompletedButton(colorScheme, completedCount),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStatePrompt(_ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.card, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_outlined,
              color: colorScheme.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your matrix is empty.',
                  style: TextStyle(
                    color: colorScheme.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'That’s perfectly okay. What’s one important thing you’d like to focus on today?',
                  style: TextStyle(
                    color: colorScheme.secondaryText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader(_ColorScheme colorScheme, int completedCount) {
    final hour = DateTime.now().hour;
    String emoji = hour < 12
        ? '☀️'
        : hour < 17
        ? '🌤️'
        : '🌙';

    String message = _getMotivationalMessage(completedCount, hour);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: colorScheme.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(int completedToday, int hour) {
    if (hour < 12) {
      return completedToday == 0
          ? 'A fresh start awaits 🌅'
          : 'Great start to your day!';
    } else if (hour < 17) {
      return completedToday > 3 ? 'You’re on fire! 🔥' : 'Afternoon push!';
    } else if (hour < 22) {
      return completedToday == 0
          ? 'It’s okay. Tomorrow is new.'
          : 'Strong finish!';
    } else {
      return 'Rest well. Your tasks will wait. 🌙';
    }
  }

  Widget _buildThemeSelectionRow(
    AppTheme currentTheme,
    _ColorScheme colorScheme,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _darkWidthAnimation,
        _lightWidthAnimation,
        _infoWidthAnimation,
        _darkPressScale,
        _lightPressScale,
        _infoPressScale,
      ]),
      builder: (context, child) {
        return Row(
          children: [
            Expanded(
              flex: (_darkWidthAnimation.value * 100).round(),
              child: _buildSpringThemeButton(
                icon: Icons.nights_stay,
                theme: AppTheme.dark,
                currentTheme: currentTheme,
                colorScheme: colorScheme,
                buttonKey: 'dark',
                scaleAnimation: _darkPressScale,
                pressController: _darkPressController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: (_lightWidthAnimation.value * 100).round(),
              child: _buildSpringThemeButton(
                icon: Icons.wb_sunny,
                theme: AppTheme.light,
                currentTheme: currentTheme,
                colorScheme: colorScheme,
                buttonKey: 'light',
                scaleAnimation: _lightPressScale,
                pressController: _lightPressController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: (_infoWidthAnimation.value * 100).round(),
              child: _buildSpringInfoButton(
                colorScheme: colorScheme,
                scaleAnimation: _infoPressScale,
                pressController: _infoPressController,
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ Keep your original spring button implementations
  Widget _buildSpringThemeButton({
    required IconData icon,
    required AppTheme theme,
    required AppTheme currentTheme,
    required _ColorScheme colorScheme,
    required String buttonKey,
    required Animation<double> scaleAnimation,
    required AnimationController pressController,
  }) {
    final isSelected = currentTheme == theme;
    return Transform.scale(
      scale: scaleAnimation.value,
      child: GestureDetector(
        onTapDown: (_) {
          pressController.forward();
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          pressController.reverse();
        },
        onTapCancel: () {
          pressController.reverse();
        },
        onTap: () {
          if (currentTheme != theme) {
            ref.read(themeProvider.notifier).setTheme(theme);
            HapticFeedback.mediumImpact();
          }
          _triggerWidthReaction(buttonKey);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: const Cubic(0.4, 0.0, 0.2, 1.0),
          height: 96,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.selectedTheme : colorScheme.card,
            borderRadius: BorderRadius.circular(isSelected ? 26 : 48),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 28,
            color: isSelected
                ? colorScheme.selectedThemeIcon
                : colorScheme.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildSpringInfoButton({
    required _ColorScheme colorScheme,
    required Animation<double> scaleAnimation,
    required AnimationController pressController,
  }) {
    return Transform.scale(
      scale: scaleAnimation.value,
      child: GestureDetector(
        onTapDown: (_) {
          pressController.forward();
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          pressController.reverse();
        },
        onTapCancel: () {
          pressController.reverse();
        },
        onTap: () {
          _triggerWidthReaction('info');
          HapticFeedback.mediumImpact();
          _showModernAboutDialog(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: const Cubic(0.4, 0.0, 0.2, 1.0),
          height: 96,
          decoration: BoxDecoration(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            Icons.info_outline,
            size: 28,
            color: colorScheme.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildClearCompletedButton(
    _ColorScheme colorScheme,
    int completedCount,
  ) {
    final hasCompleted = completedCount > 0;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: hasCompleted ? 1.0 : 0.5,
      child: GestureDetector(
        onTapDown: hasCompleted ? (_) => HapticFeedback.lightImpact() : null,
        onTap: hasCompleted
            ? () => _handleClearCompleted(completedCount)
            : null,
        child: Container(
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          decoration: BoxDecoration(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(48),
            border: hasCompleted
                ? Border.all(color: Colors.red.withOpacity(0.15), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: hasCompleted
                    ? Colors.red.withOpacity(0.08)
                    : Colors.black.withOpacity(0.04),
                blurRadius: hasCompleted ? 6 : 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasCompleted
                      ? Colors.red.withOpacity(0.1)
                      : colorScheme.secondaryCard,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  hasCompleted
                      ? Icons.delete_sweep_rounded
                      : Icons.delete_outline,
                  color: hasCompleted
                      ? Colors.red.shade600
                      : colorScheme.secondaryText,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          hasCompleted
                              ? 'Clear Completed Tasks'
                              : 'No Tasks to Clear',
                          style: TextStyle(
                            color: colorScheme.primaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (hasCompleted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$completedCount',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasCompleted
                          ? 'Remove $completedCount finished ${completedCount == 1 ? 'task' : 'tasks'}'
                          : 'Complete some tasks first',
                      style: TextStyle(
                        color: colorScheme.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasCompleted)
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.secondaryText,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleClearCompleted(int count) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 400),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          curve: const Cubic(0.05, 0.7, 0.1, 1.0),
          builder: (context, double value, child) {
            final colorScheme = _getColorScheme(ref.read(themeProvider));
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: colorScheme.card,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.red.shade600,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Clear Completed Tasks?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You\'re about to permanently delete $count completed ${count == 1 ? 'task' : 'tasks'}. This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.secondaryText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDialogButton(
                            label: 'Cancel',
                            isPrimary: false,
                            onTap: () => Navigator.pop(context, false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDialogButton(
                            label: 'Clear All',
                            isPrimary: true,
                            onTap: () => Navigator.pop(context, true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    if (confirmed == true) {
      await ref.read(taskProvider.notifier).clearCompletedTasks();

      ref.read(showCompletedTasksProvider.notifier).set(false);
      HapticFeedback.heavyImpact();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '✨ Clean slate. ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: 'Take a breath. You’ve got this.'),
                      ],
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildDialogButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final colorScheme = _getColorScheme(ref.read(themeProvider));
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isPrimary ? Colors.red.shade600 : colorScheme.secondaryCard,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.white : colorScheme.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedTasksSection(
    bool showCompleted,
    _ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: const Cubic(0.4, 0.0, 0.2, 1.0),
            height: 96,
            padding: const EdgeInsets.fromLTRB(30, 20, 20, 20),
            decoration: BoxDecoration(
              color: colorScheme.card,
              borderRadius: BorderRadius.circular(48),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Show Completed Tasks',
                  style: TextStyle(
                    color: colorScheme.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Display finished tasks',
                  style: TextStyle(
                    color: colorScheme.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: const Cubic(0.4, 0.0, 0.2, 1.0),
          width: 116,
          height: 96,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Transform.scale(
              scale: 1.2,
              child: Switch.adaptive(
                value: showCompleted,
                onChanged: (value) {
                  ref.read(showCompletedTasksProvider.notifier).toggle();
                  HapticFeedback.lightImpact();
                },
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveThumbColor: colorScheme.switchInactiveThumb,
                inactiveTrackColor: colorScheme.switchInactiveTrack,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showModernAboutDialog(BuildContext context) {
    final appTheme = ref.read(themeProvider);
    final colorScheme = _getColorScheme(appTheme);
    final infoBgColor = appTheme == AppTheme.light
        ? const Color(0xFFF2F2F7)
        : const Color(0xFF3A3A3C); // Fixed for dark mode visibility

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 400),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          curve: const Cubic(0.05, 0.7, 0.1, 1.0),
          builder: (context, double scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.card,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: infoBgColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'About Focus',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FutureBuilder<String>(
                      future: _getAppVersion(),
                      builder: (context, snapshot) {
                        String displayVersion =
                            snapshot.data ?? 'Version Unknown';
                        if (displayVersion.contains('+')) {
                          displayVersion = displayVersion.split('+').first;
                        }
                        return Text(
                          displayVersion,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primaryText,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Container(
                          height: 30,
                          width: 240,
                          decoration: BoxDecoration(
                            color: infoBgColor,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Center(
                            child: Text(
                              'Made with 💙 by Basim Basheer',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.secondaryText,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: infoBgColor.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '🔒 All your data stays on your device — no cloud, no tracking.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primaryText.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.code_rounded,
                          onTap: () => _launchUrl(
                            context,
                            'https://github.com/Appaxaap/Focus',
                          ),
                          colorScheme: colorScheme,
                        ),
                        _buildActionButton(
                          icon: Icons.bug_report_rounded,
                          onTap: () => _launchUrl(
                            context,
                            'https://github.com/Appaxaap/Focus/issues',
                          ),
                          colorScheme: colorScheme,
                        ),
                        _buildActionButton(
                          icon: Icons.telegram_rounded,
                          onTap: () => _launchUrl(
                            context,
                            'https://t.me/+IdAIopSTiXowYWFl',
                          ),
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _launchUrl(context, 'https://buymeacoffee.com/bxmbshr');
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: colorScheme.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: colorScheme.accent.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Support Focus ☕',
                            style: TextStyle(
                              color: colorScheme.accent,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required _ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: colorScheme.secondaryCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.secondaryText.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(icon, color: colorScheme.primaryText, size: 28),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (Platform.isAndroid) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        } catch (e) {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            return;
          }
        }
      }
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      throw 'Could not launch URL';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open link'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _launchUrl(context, url),
          ),
        ),
      );
    }
  }

  Widget _buildDragHandle(_ColorScheme colorScheme) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.dragHandle,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  _ColorScheme _getColorScheme(AppTheme theme) {
    if (theme == AppTheme.light) {
      return _ColorScheme(
        background: const Color(0xFFF2F2F7),
        card: Colors.white,
        secondaryCard: const Color(0xFFF2F2F7),
        primaryText: const Color(0xFF1C1C1E),
        secondaryText: const Color(0xFF8E8E93),
        dragHandle: Colors.black.withOpacity(0.3),
        selectedTheme: const Color(0xFFB8C5D1),
        selectedThemeIcon: const Color(0xFF2C2C2E),
        dialogBackground: Colors.white,
        accent: const Color(0xFF007AFF),
        switchActive: const Color(0xFF34C759),
        switchInactiveThumb: const Color(0xFFFFFFFF),
        switchInactiveTrack: const Color(0xFFE5E5EA),
      );
    } else {
      return _ColorScheme(
        background: const Color(0xFF1C1C1E),
        card: const Color(0xFF2C2C2E),
        secondaryCard: const Color(0xFF3A3A3C), // ← Updated for visibility
        primaryText: Colors.white,
        secondaryText: const Color(0xFF8E8E93),
        dragHandle: Colors.white.withOpacity(0.3),
        selectedTheme: const Color(0xFFB8C5D1),
        selectedThemeIcon: const Color(0xFF1C1C1E),
        dialogBackground: const Color(0xFF2C2C2E),
        accent: const Color(0xFF0A84FF),
        switchActive: const Color(0xFF30D158),
        switchInactiveThumb: const Color(0xFF767680).withOpacity(0.16),
        switchInactiveTrack: const Color(0xFF39393D),
      );
    }
  }
}

class _ColorScheme {
  final Color background;
  final Color card;
  final Color secondaryCard;
  final Color primaryText;
  final Color secondaryText;
  final Color dragHandle;
  final Color selectedTheme;
  final Color selectedThemeIcon;
  final Color dialogBackground;
  final Color accent;
  final Color switchActive;
  final Color switchInactiveThumb;
  final Color switchInactiveTrack;

  const _ColorScheme({
    required this.background,
    required this.card,
    required this.secondaryCard,
    required this.primaryText,
    required this.secondaryText,
    required this.dragHandle,
    required this.selectedTheme,
    required this.selectedThemeIcon,
    required this.dialogBackground,
    required this.accent,
    required this.switchActive,
    required this.switchInactiveThumb,
    required this.switchInactiveTrack,
  });
}

void showSettingsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    builder: (context) => const SettingsBottomSheet(),
  );
}
