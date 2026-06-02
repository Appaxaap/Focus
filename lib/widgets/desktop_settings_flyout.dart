import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import '../providers/app_icon_badge_provider.dart';
import '../providers/show_completed_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import 'app_dialog.dart';

const Color _macDanger = Color(0xFFFF4D57);

bool _isDarkScheme(ColorScheme cs) => cs.brightness == Brightness.dark;

Color _ink(ColorScheme cs, {double dark = 0.55, double light = 0.72}) {
  return cs.onSurface.withValues(alpha: _isDarkScheme(cs) ? dark : light);
}

Color _panel(ColorScheme cs, {double dark = 0.72, double light = 0.90}) {
  return cs.surface.withValues(alpha: _isDarkScheme(cs) ? dark : light);
}

void showDesktopSettingsFlyout(BuildContext context, GlobalKey anchorKey) {
  final RenderBox renderBox =
      anchorKey.currentContext!.findRenderObject() as RenderBox;
  final Offset offset = renderBox.localToGlobal(Offset.zero);
  final Size size = renderBox.size;

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    builder: (context) => Stack(
      children: [
        Positioned(
          top: offset.dy + size.height + 8,
          right: MediaQuery.of(context).size.width - offset.dx - size.width,
          child: const _DesktopSettingsFlyout(),
        ),
      ],
    ),
  );
}

class _DesktopSettingsFlyout extends ConsumerStatefulWidget {
  const _DesktopSettingsFlyout();

  @override
  ConsumerState<_DesktopSettingsFlyout> createState() =>
      _DesktopSettingsFlyoutState();
}

class _DesktopSettingsFlyoutState extends ConsumerState<_DesktopSettingsFlyout>
    with SingleTickerProviderStateMixin {
  bool _showAbout = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = info.version);
    } catch (_) {
      if (mounted) setState(() => _version = '2.1.0');
    }
  }

  void _navigateTo(bool about) {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() => _showAbout = about);
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: _panel(colorScheme),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _ink(colorScheme, dark: 0.10, light: 0.18),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _showAbout
                    ? _buildAboutPanel(theme, colorScheme)
                    : _buildMainPanel(theme, colorScheme, accent),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _macToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accent,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 58,
        height: 30,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: value
              ? accent.withValues(alpha: 0.24)
              : _ink(Theme.of(context).colorScheme, dark: 0.08, light: 0.14),
          border: Border.all(
            color: value
                ? accent.withValues(alpha: 0.38)
                : _ink(Theme.of(context).colorScheme, dark: 0.14, light: 0.24),
            width: 0.5,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          curve: Curves.easeOutCubic,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _glassTile(
    ColorScheme colorScheme, {
    bool selected = false,
    Color? accent,
  }) {
    final highlight = accent ?? colorScheme.primary;
    return BoxDecoration(
      color: selected
          ? _ink(colorScheme, dark: 0.08, light: 0.12)
          : _ink(colorScheme, dark: 0.05, light: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: selected
            ? highlight.withValues(alpha: 0.40)
            : _ink(colorScheme, dark: 0.10, light: 0.18),
        width: 0.5,
      ),
    );
  }

  Widget _buildMainPanel(ThemeData theme, ColorScheme colorScheme, Color accent) {
    final appTheme = ref.watch(themeProvider);
    final showCompletedAsync = ref.watch(showCompletedTasksProvider);
    final showCompleted = showCompletedAsync.value ?? false;
    final appIconBadgeEnabledAsync = ref.watch(appIconBadgeProvider);
    final appIconBadgeEnabled = appIconBadgeEnabledAsync.value ?? true;
    final allTasks = ref.watch(taskProvider);
    final completedCount = allTasks.where((t) => t.isCompleted).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _themeButton(
                icon: Icons.nights_stay_rounded,
                label: 'Dark',
                selected: appTheme == AppTheme.dark,
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(AppTheme.dark);
                  HapticFeedback.selectionClick();
                },
                colorScheme: colorScheme,
                theme: theme,
                accent: accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _themeButton(
                icon: Icons.wb_sunny_rounded,
                label: 'Light',
                selected: appTheme == AppTheme.light,
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(AppTheme.light);
                  HapticFeedback.selectionClick();
                },
                colorScheme: colorScheme,
                theme: theme,
                accent: accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _themeButton(
                icon: Icons.brightness_3_rounded,
                label: 'AMOLED',
                selected: appTheme == AppTheme.amoled,
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(AppTheme.amoled);
                  HapticFeedback.selectionClick();
                },
                colorScheme: colorScheme,
                theme: theme,
                accent: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: _themeButton(
            icon: Icons.info_outline_rounded,
            label: 'About',
            selected: false,
            onTap: () => _navigateTo(true),
            colorScheme: colorScheme,
            theme: theme,
            accent: accent,
          ),
        ),
        const SizedBox(height: 10),
        _showCompletedRow(showCompleted, theme, colorScheme, accent),
        const SizedBox(height: 10),
        _appIconBadgeRow(appIconBadgeEnabled, theme, colorScheme, accent),
        const SizedBox(height: 10),
        _clearCompletedRow(completedCount, theme, colorScheme),
      ],
    );
  }

  Widget _themeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required ThemeData theme,
    required Color accent,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: _glassTile(
          colorScheme,
          selected: selected,
          accent: accent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? accent
                  : _ink(colorScheme, dark: 0.55, light: 0.75),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected
                    ? accent
                    : _ink(colorScheme, dark: 0.55, light: 0.75),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: selected ? accent : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _showCompletedRow(
    bool showCompleted,
    ThemeData theme,
    ColorScheme colorScheme,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _glassTile(colorScheme),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Show Completed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _ink(colorScheme, dark: 0.92, light: 0.92),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Display finished tasks',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _ink(colorScheme, dark: 0.45, light: 0.62),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _macToggle(
            value: showCompleted,
            accent: accent,
            onChanged: (_) {
              ref.read(showCompletedTasksProvider.notifier).toggle();
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _clearCompletedRow(
    int completedCount,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final hasCompleted = completedCount > 0;
    return GestureDetector(
      onTap: hasCompleted ? () => _handleClear(completedCount) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: hasCompleted ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: _glassTile(
            colorScheme,
            selected: hasCompleted,
            accent: _macDanger,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _macDanger.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  color: _macDanger,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clear Completed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _ink(colorScheme, dark: 0.92, light: 0.92),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCompleted
                          ? '$completedCount finished tasks'
                          : 'No tasks to clear',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _ink(colorScheme, dark: 0.45, light: 0.62),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _ink(colorScheme, dark: 0.40, light: 0.62),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appIconBadgeRow(
    bool appIconBadgeEnabled,
    ThemeData theme,
    ColorScheme colorScheme,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _glassTile(colorScheme),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Icon Badge',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _ink(colorScheme, dark: 0.92, light: 0.92),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Show due task count',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _ink(colorScheme, dark: 0.45, light: 0.62),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _macToggle(
            value: appIconBadgeEnabled,
            accent: accent,
            onChanged: (value) {
              ref.read(appIconBadgeProvider.notifier).setEnabled(value);
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutPanel(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => _navigateTo(false),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _ink(colorScheme, dark: 0.06, light: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _ink(colorScheme, dark: 0.10, light: 0.18),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: _ink(colorScheme, dark: 0.75, light: 0.85),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'About Focus',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: _ink(colorScheme, dark: 0.92, light: 0.92),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _glassTile(colorScheme),
          child: Column(
            children: [
              Text(
                _version.isNotEmpty ? 'Version $_version' : 'Version 2.1.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _ink(colorScheme, dark: 0.45, light: 0.62),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Built as a quiet space for clear, intentional work.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _ink(colorScheme, dark: 0.92, light: 0.92),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'All data stays on your device',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _ink(colorScheme, dark: 0.45, light: 0.62),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _aboutLinkButton(
                icon: Icons.code_rounded,
                label: 'Source',
                url: 'https://github.com/Appaxaap/Focus',
                colorScheme: colorScheme,
                theme: theme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _aboutLinkButton(
                icon: Icons.bug_report_rounded,
                label: 'Issues',
                url: 'https://github.com/Appaxaap/Focus/issues',
                colorScheme: colorScheme,
                theme: theme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _aboutLinkButton(
                icon: Icons.telegram_rounded,
                label: 'Community',
                url: 'https://t.me/+IdAIopSTiXowYWFl',
                colorScheme: colorScheme,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _launchUrl('https://buymeacoffee.com/bxmbshr'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: _glassTile(colorScheme),
            child: Center(
              child: Text(
                'Support Focus',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _ink(colorScheme, dark: 0.92, light: 0.92),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _aboutLinkButton({
    required IconData icon,
    required String label,
    required String url,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: _glassTile(colorScheme),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: _ink(colorScheme, dark: 0.6, light: 0.75)),
            const SizedBox(height: 5),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _ink(colorScheme, dark: 0.55, light: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleClear(int count) async {
    Navigator.pop(context);
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialogContainer(
        child: Builder(
          builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final theme = Theme.of(context);
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
            'Clear completed tasks?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
              const SizedBox(height: 10),
              Text(
                'This will permanently remove $count completed '
                '${count == 1 ? 'task' : 'tasks'}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: AppDialogButton(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDialogButton(
                      label: 'Clear',
                      isDestructive: true,
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
          },
        ),
      ),
    );

    if (confirmed == true) {
      await ref.read(taskProvider.notifier).clearCompletedTasks();
      ref.read(showCompletedTasksProvider.notifier).set(false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

}
