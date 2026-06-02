import 'package:flutter/material.dart';
import '../providers/task_providers.dart';
import '../providers/task_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../main.dart';
import '../providers/theme_provider.dart';
import '../providers/ui_preferences_provider.dart';
import '../services/nearby_sync_client_service.dart';
import 'nearby_sync_screen.dart';
import '../widgets/app_dialog.dart';
import '../config/feature_flags.dart';
import '../config/release_info.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _nearbyEndpointController =
      TextEditingController();
  final TextEditingController _nearbyPairingCodeController =
      TextEditingController();

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
    _nearbyEndpointController.dispose();
    _nearbyPairingCodeController.dispose();
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
    final uiPrefs = ref.watch(uiPreferencesProvider);

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

              _buildSectionCard(
                context: context,
                icon: Icons.tune_rounded,
                title: 'Accessibility & Density',
                subtitle: 'Motion and compact layout preferences',
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      title: Text(
                        'Reduced motion',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      subtitle: Text(
                        'Use simpler transitions and fewer animations',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      value: uiPrefs.reducedMotion,
                      onChanged: (value) {
                        ref
                            .read(uiPreferencesProvider.notifier)
                            .setReducedMotion(value);
                        HapticFeedback.selectionClick();
                      },
                      activeTrackColor: colorScheme.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    SwitchListTile.adaptive(
                      title: Text(
                        'Compact mode',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      subtitle: Text(
                        'Tighter spacing for dense task lists',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      value: uiPrefs.compactDensity,
                      onChanged: (value) {
                        ref
                            .read(uiPreferencesProvider.notifier)
                            .setCompactDensity(value);
                        HapticFeedback.selectionClick();
                      },
                      activeTrackColor: colorScheme.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
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
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      value: showCompleted,
                      onChanged: (value) {
                        ref.read(showCompletedTasksProvider.notifier).state =
                            value;
                        HapticFeedback.selectionClick();
                      },
                      activeTrackColor: colorScheme.primary,
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
                    const SizedBox(height: 12),
                    if (kEnableNearbySync)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NearbySyncScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.sync_alt_rounded),
                          label: const Text('Nearby Sync (Desktop -> Mobile)'),
                        ),
                      ),
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
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(
                        'Data & Privacy',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () => _showDataPrivacyDialog(context),
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
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
            ref.read(themeProvider.notifier).setTheme(selection.first);
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
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
      if (!context.mounted) return;

      if (!Platform.isAndroid) {
        _showSuccessSnackbar(
          context,
          'Backup export is only supported on Android',
          isError: true,
        );
        return;
      }

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
      if (!context.mounted) return;
      _showSuccessSnackbar(
        context,
        'Backup saved to Downloads/focus_backup_$timestamp.json',
      );
    } catch (e, s) {
      debugPrint('Error exporting backup: $e\n$s');
      _showSuccessSnackbar(context, 'Failed to export backup', isError: true);
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final hiveService = ref.read(hiveServiceProvider);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Backup File',
      );
      if (!context.mounted) return;

      if (result == null || result.files.isEmpty) {
        _showSuccessSnackbar(context, 'No file selected', isError: true);
        return;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      if (!context.mounted) return;
      final decoded = jsonDecode(jsonString);

      final List<dynamic> jsonList;
      if (decoded is Map<String, dynamic> && decoded.containsKey('tasks')) {
        jsonList = decoded['tasks'] as List;
      } else if (decoded is List) {
        jsonList = decoded;
      } else {
        _showSuccessSnackbar(
          context,
          'Invalid backup file format',
          isError: true,
        );
        return;
      }

      await hiveService.importData(
        jsonList.map((e) => e as Map<String, dynamic>).toList(),
      );
      if (!context.mounted) return;

      _showSuccessSnackbar(context, 'Backup restored successfully!');
    } catch (e, s) {
      debugPrint('Error restoring backup: $e\n$s');
      _showSuccessSnackbar(context, 'Failed to restore backup', isError: true);
    }
  }

  // ignore: unused_element
  Future<void> _showNearbySyncDialog(BuildContext parentContext) async {
    _nearbyEndpointController.text = _nearbyEndpointController.text.trim();
    _nearbyPairingCodeController.text = _nearbyPairingCodeController.text
        .trim();

    await showAppDialog(
      context: parentContext,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        bool syncing = false;
        String? lastMessage;
        bool isError = false;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> runSync() async {
              if (syncing) return;
              final endpoint = _nearbyEndpointController.text.trim();
              final pairCode = _nearbyPairingCodeController.text.trim();
              if (endpoint.isEmpty || pairCode.isEmpty) {
                setLocalState(() {
                  isError = true;
                  lastMessage = 'Enter endpoint and pairing code.';
                });
                return;
              }

              setLocalState(() {
                syncing = true;
                isError = false;
                lastMessage = null;
              });

              try {
                final hiveService = ref.read(hiveServiceProvider);
                final result = await NearbySyncClientService.instance
                    .pullFromDesktop(
                      endpoint: endpoint,
                      pairingCode: pairCode,
                      hiveService: hiveService,
                    );

                await ref.read(taskProvider.notifier).refresh();
                if (!context.mounted) return;
                setLocalState(() {
                  isError = false;
                  lastMessage = result.upsertedCount == 0
                      ? 'Already up to date. ${result.receivedCount} tasks checked.'
                      : 'Connected and synced ${result.upsertedCount}/${result.receivedCount} tasks.';
                });
                return;
              } catch (e) {
                if (!context.mounted) return;
                setLocalState(() {
                  isError = true;
                  lastMessage = 'Sync failed: $e';
                });
              } finally {
                if (context.mounted) {
                  setLocalState(() {
                    syncing = false;
                  });
                }
              }
            }

            return AppDialogContainer(
              child: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nearby Sync',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use desktop endpoint and pairing code from Nearby Sync settings on Windows.',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.76),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _nearbyEndpointController,
                      decoration: const InputDecoration(
                        labelText: 'Desktop endpoint',
                        hintText: '192.168.1.4:53124',
                        prefixIcon: Icon(Icons.computer_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nearbyPairingCodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Pairing code',
                        hintText: '123456',
                        prefixIcon: Icon(Icons.password_rounded),
                        counterText: '',
                      ),
                    ),
                    if (lastMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        lastMessage!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isError ? cs.error : cs.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppDialogButton(
                            label: syncing ? 'Syncing...' : 'Sync now',
                            isPrimary: true,
                            onTap: syncing ? () {} : runSync,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppDialogButton(
                            label: 'Close',
                            onTap: () {
                              if (syncing) {
                                setLocalState(() {
                                  isError = true;
                                  lastMessage =
                                      'Please wait for sync to finish before closing.';
                                });
                                return;
                              }
                              _safeCloseDialog(context);
                            },
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
      },
    );
  }

  void _safeCloseDialog(BuildContext dialogContext) {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = Navigator.of(dialogContext);
      if (nav.canPop()) nav.pop();
    });
  }

  Future<void> _confirmClearData(BuildContext context, WidgetRef ref) async {
    showAppDialog(
      context: context,
      builder: (context) => AppDialogContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_outlined,
              color: Theme.of(context).colorScheme.error,
              size: 40,
            ),
            const SizedBox(height: 20),
            Text(
              'Clear All Data?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This will permanently delete ALL your tasks and settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: AppDialogButton(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppDialogButton(
                    label: 'Clear All',
                    isDestructive: true,
                    onTap: () async {
                      Navigator.pop(context);
                      await _clearAllData(ref);
                      if (context.mounted) {
                        _showSuccessSnackbar(
                          context,
                          'All data has been cleared',
                          isError: true,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearAllData(WidgetRef ref) async {
    final hiveService = ref.read(hiveServiceProvider);
    await hiveService.clearAllData();
    ref.invalidate(showCompletedTasksProvider);
  }

  void _showAboutAppDialog(BuildContext context) {
    showAppDialog(
      context: context,
      builder: (context) => AppDialogContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.apps_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              'About Focus',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Focus is a task management app based on the Eisenhower Matrix '
              'to help you prioritize what matters most.\n\n'
              '- Task categorization into quadrants\n'
              '- Backup and restore functionality\n'
              '- Completed tasks toggle\n\n'
              'Changelog: $kChangelogUrl\n'
              'Release hash: $kSignedReleaseHash',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            AppDialogButton(
              label: 'OK',
              isPrimary: true,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDeveloperDialog(BuildContext context) {
    showAppDialog(
      context: context,
      builder: (context) => AppDialogContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              'About Developer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This app was developed by Basim Basheer.\n\n'
              'GitHub: github.com/Appaxaap\n'
              'LinkedIn: linkedin.com/in/Basim Basheer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            AppDialogButton(
              label: 'OK',
              isPrimary: true,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDataPrivacyDialog(BuildContext context) {
    showAppDialog(
      context: context,
      builder: (context) => AppDialogContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data & Privacy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Focus is local-first and privacy-oriented:\n\n'
              '• Tasks and settings are stored on your device.\n'
              '• No analytics/telemetry pipeline is enabled by default.\n'
              '• Backup exports are generated by you and saved locally.\n'
              '• Nearby sync is currently disabled in this release.\n\n'
              'Changelog: $kChangelogUrl\n'
              'Release hash: $kSignedReleaseHash',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            AppDialogButton(
              label: 'OK',
              isPrimary: true,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
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
