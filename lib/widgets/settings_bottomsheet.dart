import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/task_providers.dart';
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

  // Base flex values for width calculation (optimized for fast and smooth)
  static const double _baseFlexValue = 1.0;
  static const double _expandedFlexValue = 1.12; // Subtle but noticeable
  static const double _compressedFlexValue = 0.92; // Gentle compression

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Main slide animation with Emphasized decelerate (entrance)
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500), // Emphasized timing
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _slideController,
            curve: const Cubic(0.05, 0.7, 0.1, 1.0), // Emphasized decelerate
            reverseCurve: const Cubic(
              0.3,
              0.0,
              0.8,
              0.15,
            ), // Emphasized accelerate
          ),
        );

    // Width animation controllers with spring physics timing
    _darkWidthController = AnimationController(
      duration: const Duration(milliseconds: 320), // quick expand
      reverseDuration: const Duration(milliseconds: 600), // longer spring back
      vsync: this,
    );

    _lightWidthController = AnimationController(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(
        milliseconds: 800,
      ), // Slower spring return
      vsync: this,
    );

    _infoWidthController = AnimationController(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(
        milliseconds: 800,
      ), // Slower spring return
      vsync: this,
    );

    // Press controllers for immediate feedback
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

    // Width animations with Material 3 spring physics
    _darkWidthAnimation =
        Tween<double>(begin: _baseFlexValue, end: _baseFlexValue).animate(
          CurvedAnimation(
            parent: _darkWidthController,
            curve: const Cubic(
              0.2,
              0.0,
              0.0,
              1.0,
            ), // Fast smooth curve for press
            reverseCurve: Curves.elasticOut, // Spring bounce for return
          ),
        );

    _lightWidthAnimation =
        Tween<double>(begin: _baseFlexValue, end: _baseFlexValue).animate(
          CurvedAnimation(
            parent: _lightWidthController,
            curve: const Cubic(
              0.2,
              0.0,
              0.0,
              1.0,
            ), // Fast smooth curve for press
            reverseCurve: Curves.elasticOut, // Spring bounce for return
          ),
        );

    _infoWidthAnimation =
        Tween<double>(begin: _baseFlexValue, end: _baseFlexValue).animate(
          CurvedAnimation(
            parent: _infoWidthController,
            curve: const Cubic(
              0.2,
              0.0,
              0.0,
              1.0,
            ), // Fast smooth curve for press
            reverseCurve: Curves.elasticOut, // Spring bounce for return
          ),
        );

    // Press scale animations
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

  // Fast and smooth width reaction system
  void _triggerWidthReaction(String pressedButton) {
    _resetAllWidthAnimations();

    Future.delayed(const Duration(milliseconds: 10), () {
      switch (pressedButton) {
        case 'dark': // Left pressed
          _animateButtonWidth(_darkWidthController, _darkWidthAnimation, _expandedFlexValue); // expand dark
          _animateButtonWidth(_lightWidthController, _lightWidthAnimation, _compressedFlexValue); // compress light (neighbor)
          _animateButtonWidth(_infoWidthController, _infoWidthAnimation, _baseFlexValue); // info normal (no reaction)
          break;

        case 'light': // Center pressed
          _animateButtonWidth(_darkWidthController, _darkWidthAnimation, _compressedFlexValue); // compress dark
          _animateButtonWidth(_lightWidthController, _lightWidthAnimation, _expandedFlexValue); // expand light
          _animateButtonWidth(_infoWidthController, _infoWidthAnimation, _compressedFlexValue); // compress info
          break;

        case 'info': // Right pressed
          _animateButtonWidth(_darkWidthController, _darkWidthAnimation, _baseFlexValue); // dark normal (no reaction)
          _animateButtonWidth(_lightWidthController, _lightWidthAnimation, _compressedFlexValue); // compress light (neighbor)
          _animateButtonWidth(_infoWidthController, _infoWidthAnimation, _expandedFlexValue); // expand info
          break;
      }

      Future.delayed(const Duration(milliseconds: 320), () {
        _resetToNormalWidths(); // snap back sticky magnetic
      });
    });
  }

  void _animateButtonWidth(
    AnimationController controller,
    Animation<double> animation,
    double targetValue,
  ) {
    // Update the animation's end value with Material 3 spring physics
    final newTween = Tween<double>(begin: animation.value, end: targetValue);
    final newAnimation = newTween.animate(
      CurvedAnimation(
        parent: controller,
        curve: const Cubic(0.2, 0.0, 0.0, 1.0), // Fast smooth for expansion
        reverseCurve: Curves.elasticOut, // Spring bounce for return
      ),
    );

    // Replace the old animation
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
      duration: const Duration(milliseconds: 280), // quick snap
      curve: Curves.easeInOutCubicEmphasized, // sticky magnetic curve
    );
  }

  // Remove the separate sticky method since we're using reverseCurve now

  // Custom close method with emphasized accelerate

  // for fetching the app version
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
    final showCompleted = ref.watch(showCompletedTasksNotifierProvider);
    final colorScheme = _getColorScheme(appTheme);

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(colorScheme),
            const SizedBox(height: 24),
            _buildHeaderCard(colorScheme),
            const SizedBox(height: 20),
            _buildThemeSelectionRow(appTheme, colorScheme),
            const SizedBox(height: 20),
            _buildCompletedTasksSection(showCompleted, colorScheme),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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

  Widget _buildHeaderCard(_ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              color: colorScheme.primaryText,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Customize your Focus experience',
            style: TextStyle(color: colorScheme.secondaryText, fontSize: 14),
          ),
        ],
      ),
    );
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
            // Dark theme button with dynamic width
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
            // Light theme button with dynamic width
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
            // Info button with dynamic width
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
          duration: const Duration(milliseconds: 240), // Fast and smooth
          curve: const Cubic(0.4, 0.0, 0.2, 1.0), // Material 3 standard easing
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
          duration: const Duration(milliseconds: 240), // Consistent timing
          curve: const Cubic(0.4, 0.0, 0.2, 1.0), // Material 3 standard easing
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
                  ref.read(showCompletedTasksNotifierProvider.notifier).setValue(value);
                  HapticFeedback.lightImpact();
                },
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveThumbColor: colorScheme.switchInactiveThumb,
                inactiveTrackColor: colorScheme.switchInactiveTrack,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Dialogue box
  void _showModernAboutDialog(BuildContext context) {
    final appTheme = ref.read(themeProvider);
    final colorScheme = _getColorScheme(appTheme);

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
                        color: colorScheme.secondaryCard,
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

                        // Remove the '+build-number' part if exists
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
                    Container(
                      height: 30,
                      width: 240,
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryCard,
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
        child: Icon(
          icon,
          color: colorScheme.primaryText, // Use primary text color for icons
          size: 28,
        ),
      ),
    );
  }

  // launch url of github profile, github issues, and telegram community
  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);

      if (Platform.isAndroid) {
        // Special handling for Android
        try {
          // First try with external application
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        } catch (e) {
          // Fallback to default handling
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            return;
          }
        }
      }

      // Standard handling for iOS and fallback
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

  // Centralized color scheme management
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
        secondaryCard: const Color(0xFF2C2C2E),
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

// Color scheme data class for better organization
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

// Function to show the bottom sheet with proper emphasized curves
void showSettingsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    transitionAnimationController: null, // Let our custom animation handle it
    builder: (context) => const SettingsBottomSheet(),
  );
}
