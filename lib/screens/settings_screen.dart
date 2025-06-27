import 'package:flutter/material.dart';
import '../providers/task_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../main.dart';
import '../models/task_models.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadPreferences();

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

  // load provider
  Future<void> _loadPreferences() async {
    final hiveService = ref.read(hiveServiceProvider);
    final showCompleted = await hiveService.getShowCompletedPreference();
    ref.read(showCompletedTasksProvider.notifier).state = showCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appTheme = ref.watch(themeProvider);
    final showCompleted = ref.watch(showCompletedTasksProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton.filledTonal(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundColor: colorScheme.onSurface,
          ),
        ),
        title: Text(
          'Settings',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Appearance Section
              _buildSectionCard(
                context: context,
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: 'Customize your visual experience',
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildThemeSelector(context, ref, appTheme),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tasks Section
              _buildSectionCard(
                context: context,
                icon: Icons.task_alt_outlined,
                title: 'Tasks',
                subtitle: 'Manage your task preferences',
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      title: Text(
                        'Show completed tasks',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      subtitle: Text(
                        'Display finished tasks in your list',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      value: showCompleted,
                      onChanged: (value) {
                        ref.read(showCompletedTasksProvider.notifier).state =
                            value;
                        HapticFeedback.selectionClick();
                      },
                      activeColor: colorScheme.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Data Management Section
              _buildSectionCard(
                context: context,
                icon: Icons.storage_outlined,
                title: 'Data Management',
                subtitle: 'Backup and restore your data',
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildActionButtons(context, ref),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info Section
              _buildSectionCard(
                context: context,
                icon: Icons.info_outline,
                title: 'Info',
                subtitle: 'About app and developer',
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.apps_outlined),
                      title: Text(
                        'About App',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () {
                        _showAboutAppDialog(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(
                        'About Developer',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () {
                        _showAboutDeveloperDialog(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card.filled(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
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
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    AppTheme currentTheme,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        SegmentedButton<AppTheme>(
          segments: [
            ButtonSegment<AppTheme>(
              value: AppTheme.light,
              label: const Text('Light'),
              icon: const Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment<AppTheme>(
              value: AppTheme.dark,
              label: const Text('Dark'),
              icon: const Icon(Icons.dark_mode_outlined),
            ),
          ],
          selected: {currentTheme},
          onSelectionChanged: (Set<AppTheme> selection) {
            ref.read(themeProvider.notifier).state = selection.first;
            HapticFeedback.selectionClick();
          },
          style: SegmentedButton.styleFrom(
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            selectedForegroundColor: colorScheme.onPrimary,
            selectedBackgroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.outline),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose your preferred theme mode',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: FilledButton.tonal(
            onPressed: () => _exportBackup(context),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.backup_outlined),
                SizedBox(height: 4),
                Text('Backup'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonal(
            onPressed: () => _importBackup(context),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.tertiaryContainer,
              foregroundColor: colorScheme.onTertiaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restore_outlined),
                SizedBox(height: 4),
                Text('Restore'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonal(
            onPressed: () => _confirmClearData(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline),
                SizedBox(height: 4),
                Text('Clear'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final hiveService = ref.read(hiveServiceProvider);
      final backupData = await hiveService.exportData();

      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        _showSuccessSnackbar(
          context,
          'Could not access Download folder',
          isError: true,
        );
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${directory.path}/focus_backup_$timestamp.json');

      await backupFile.writeAsString(backupData);
      _showSuccessSnackbar(context, 'Backup saved to $backupFile.path');
    } catch (e, s) {
      debugPrint('Error exporting backup: $e\n$s');
      _showSuccessSnackbar(context, 'Failed to export backup', isError: true);
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final hiveService = ref.read(hiveServiceProvider);
      await hiveService.initialize(); // Use ensureInitialized instead

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Backup File',
      );

      if (result == null || result.files.isEmpty) {
        _showSuccessSnackbar(context, 'No file selected', isError: true);
        return;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final jsonList = jsonDecode(jsonString) as List;

      await hiveService.importData(jsonList.map((e) => e as Map<String, dynamic>).toList());

      _showSuccessSnackbar(context, 'Backup restored successfully!');
    } catch (e, s) {
      debugPrint('Error restoring backup: $e\n$s');
      _showSuccessSnackbar(context, 'Failed to restore backup', isError: true);
    }
  }

  Future<void> _confirmClearData(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            icon: Icon(Icons.warning_outlined, color: colorScheme.error),
            title: Text(
              'Clear All Data ?',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
            content: Text(
              'This will permanently delete ALL your tasks and settings.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _clearAllData(ref);
                  _showSuccessSnackbar(
                    context,
                    'All data has been cleared',
                    isError: true,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }

  Future<void> _clearAllData(WidgetRef ref) async {
    final hiveService = ref.read(hiveServiceProvider);
    await hiveService.clearAllData();
    ref.invalidate(showCompletedTasksProvider);
  }

  void _showAboutAppDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showGeneralDialog(
      context: context,
      pageBuilder:
          (context, animation, secondaryAnimation) => AlertDialog(
            backgroundColor: colorScheme.surfaceContainerHigh,
            title: Row(
              children: [
                Icon(Icons.apps_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'About Focus',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            content: Text(
              'Focus is a task management app based on the Eisenhower Matrix '
              'to help you prioritize what matters most.\n\n'
              'Features:\n'
              '- Task categorization into quadrants\n'
              '- Backup and restore functionality\n'
              '- Completed tasks toggle',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showAboutDeveloperDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showGeneralDialog(
      context: context,
      pageBuilder:
          (context, animation, secondaryAnimation) => AlertDialog(
            backgroundColor: colorScheme.surfaceContainerHigh,
            title: Row(
              children: [
                Icon(Icons.person_outline, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'About Developer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            content: Text(
              'This app was developed by Basim Basheer as part of a Flutter project.\n\n'
              'GitHub: github.com/Appaxaap\n'
              'LinkedIn: linkedin.com/in/Basim Basheer',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showSuccessSnackbar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? colorScheme.onError : colorScheme.onPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? colorScheme.onError : colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
