import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus/services/hive_service.dart';
import 'package:focus/services/app_badge_service.dart';
import 'package:focus/services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import 'package:desktop_window/desktop_window.dart';
import 'package:window_manager/window_manager.dart';

import 'models/quadrant_enum.dart';
import 'models/task_models.dart';
import 'providers/app_icon_badge_provider.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/desktop_home_screen.dart';
import 'screens/sunrise_screen.dart';

const Color appBackgroundColor = Color(0xFF141118);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize timezones for notifications.
  tz.initializeTimeZones();

  // Initialize services.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    NotificationService().initialize();
  }

  // Initialize Hive for local storage.
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(QuadrantAdapter());

  final hiveService = HiveService();
  await hiveService.initialize();

  // Get the saved theme preference from Hive.
  final savedTheme = await hiveService.getThemePreference();

  const minSize = Size(1068, 873);

  if (!kIsWeb && Platform.isWindows) {
    await DesktopWindow.setWindowSize(minSize);
    await DesktopWindow.setMinWindowSize(minSize);
  }

  runApp(
    ProviderScope(
      overrides: [
        hiveServiceProvider.overrideWithProvider(
          Provider((ref) => hiveService),
        ),
        themeProvider.overrideWithProvider(
          StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
            return ThemeNotifier(hiveService)
              ..setTheme(savedTheme ?? AppTheme.light);
          }),
        ),
      ],
      child: const FocusApp(),
    ),
  );
}

// Provider for the HiveService.
final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('hiveServiceProvider must be overridden');
});

final appBadgeServiceProvider = Provider<AppBadgeService>((ref) {
  return AppBadgeService();
});

// A router screen to decide whether to show the Sunrise screen or the Home screen.
class SplashRouterScreen extends ConsumerWidget {
  const SplashRouterScreen({super.key});

  Future<Widget> _decideInitialScreen(WidgetRef ref) async {
    final hiveService = ref.read(hiveServiceProvider);
    final lastShownTimestamp = await hiveService.getLastSunriseTimestamp();
    final lastShownDate = DateTime.fromMillisecondsSinceEpoch(
      lastShownTimestamp,
    );
    final now = DateTime.now();

    final isNewDay = now.difference(lastShownDate).inDays > 0;
    final isMorning = now.hour < 12;

    if (isNewDay && isMorning) {
      await hiveService.saveSunriseTimestamp();
      return const SunriseScreen();
    } else {
      return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Widget>(
      future: _decideInitialScreen(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return snapshot.data!;
        }
        return const Scaffold(
          backgroundColor: appBackgroundColor,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      },
    );
  }
}

// The root widget of the application.
class FocusApp extends ConsumerStatefulWidget {
  const FocusApp({super.key});

  @override
  ConsumerState<FocusApp> createState() => _FocusAppState();
}

class _FocusAppState extends ConsumerState<FocusApp> {
  late final ProviderSubscription<List<Task>> _tasksSubscription;
  late final ProviderSubscription<AsyncValue<bool>> _badgePrefSubscription;

  List<Task> _latestTasks = const [];
  bool _badgeEnabled = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _tasksSubscription = ref.listenManual<List<Task>>(taskProvider, (
      previous,
      next,
    ) {
      _latestTasks = next;
      _syncAppBadge();
    }, fireImmediately: true);

    _badgePrefSubscription = ref.listenManual<AsyncValue<bool>>(
      appIconBadgeProvider,
      (previous, next) {
        _badgeEnabled = next.value ?? true;
        _syncAppBadge();
      },
      fireImmediately: true,
    );
  }

  Future<void> _syncAppBadge() async {
    await ref
        .read(appBadgeServiceProvider)
        .syncBadge(tasks: _latestTasks, enabled: _badgeEnabled);
  }

  @override
  void dispose() {
    _tasksSubscription.close();
    _badgePrefSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    final ThemeData amoledTheme = ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: Colors.black,
      canvasColor: Colors.black,
      cardColor: const Color(0xFF0A0A0A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFD1BCFF),
        onPrimary: Colors.black,
        secondary: Color(0xFFD1BCFF),
        surface: Colors.black,
        surfaceContainer: Color(0xFF0D0D0D),
        surfaceContainerHigh: Color(0xFF141414),
        surfaceContainerLow: Color(0xFF0A0A0A),
        surfaceContainerHighest: Color(0xFF1A1A1A),
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFF8E8E93),
        outline: Color(0xFF2C2C2E),
        outlineVariant: Color(0xFF1C1C1E),
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
    );

    bool isDesktop = kIsWeb
        ? false
        : [
            TargetPlatform.windows,
            TargetPlatform.macOS,
            TargetPlatform.linux,
          ].contains(defaultTargetPlatform);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Focus',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: appBackgroundColor,
        appBarTheme: const AppBarTheme(backgroundColor: appBackgroundColor),
        textTheme: GoogleFonts.dmSansTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      darkTheme: themeMode == AppTheme.amoled
          ? amoledTheme
          : ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: appBackgroundColor,
              appBarTheme: const AppBarTheme(
                backgroundColor: appBackgroundColor,
              ),

              textTheme: GoogleFonts.dmSansTextTheme(
                ThemeData.dark(useMaterial3: true).textTheme,
              ).apply(bodyColor: Colors.white, displayColor: Colors.white),
            ),
      themeMode: themeMode == AppTheme.light ? ThemeMode.light : ThemeMode.dark,
      home: isDesktop ? const DesktopHomeScreen() : const SplashRouterScreen(),
    );
  }
}
