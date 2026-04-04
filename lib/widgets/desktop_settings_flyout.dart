import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_icon_badge_provider.dart';
import '../providers/show_completed_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';

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

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          // Matches bottom sheet background token exactly
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: _showAbout
                ? _buildAboutPanel(theme, colorScheme)
                : _buildMainPanel(theme, colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildMainPanel(ThemeData theme, ColorScheme colorScheme) {
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
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _themeButton(
                icon: Icons.info_outline_rounded,
                label: 'About',
                selected: false,
                onTap: () => _navigateTo(true),
                colorScheme: colorScheme,
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _showCompletedRow(showCompleted, theme, colorScheme),
        const SizedBox(height: 10),
        _appIconBadgeRow(appIconBadgeEnabled, theme, colorScheme),
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          // Inner cards match bottom sheet card tiles
          color: selected
              ? colorScheme.primary.withOpacity(0.15)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withOpacity(0.4)
                : colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
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
                color: selected ? colorScheme.primary : Colors.transparent,
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
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
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
                    color: colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Display finished tasks',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: showCompleted,
            onChanged: (v) {
              ref.read(showCompletedTasksProvider.notifier).toggle();
              HapticFeedback.lightImpact();
            },
            activeColor: colorScheme.primary,
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
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasCompleted
                  ? const Color(0xFFFF4757).withOpacity(0.3)
                  : colorScheme.outlineVariant.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4757).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Color(0xFFFF4757),
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
                        color: colorScheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCompleted
                          ? '$completedCount finished tasks'
                          : 'No tasks to clear',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
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
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
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
                    color: colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Show due task count',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: appIconBadgeEnabled,
            onChanged: (value) {
              ref.read(appIconBadgeProvider.notifier).setEnabled(value);
              HapticFeedback.lightImpact();
            },
            activeColor: colorScheme.primary,
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
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'About Focus',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Text(
                _version.isNotEmpty ? 'Version $_version' : 'Version 2.1.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Made with 💙 by Basim Basheer',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '🔒 All data stays on your device',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.2),
              ),
            ),
            child: Center(
              child: Text(
                'Support Focus ☕',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
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
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 5),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            'Clear completed tasks?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This will permanently remove $count completed '
            '${count == 1 ? 'task' : 'tasks'}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF4757),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(taskProvider.notifier).clearCompletedTasks();
      ref.read(showCompletedTasksProvider.notifier).set(false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
