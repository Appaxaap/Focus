import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus/screens/settings_screen.dart';
import 'package:focus/services/hive_service.dart';
import 'package:hive_flutter/adapters.dart';
import 'models/quadrant_enum.dart';
import 'models/task_models.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(QuadrantAdapter());

  // Open Hive box
  final taskBox = await Hive.openBox<Task>('tasks');

  // Create HiveService instance
  final hiveService = HiveService();
  await hiveService.initialize();

  // Load saved theme
  final savedTheme = await hiveService.getThemePreference();

  runApp(
    ProviderScope(
      overrides: [
        hiveServiceProvider.overrideWithProvider(
          Provider((ref) => hiveService),
        ),
        themeProvider.overrideWithProvider(
          StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
            return ThemeNotifier(hiveService)..setTheme(savedTheme ?? AppTheme.light);
          }),
        ),
      ],
      child: const FocusApp(),
    ),
  );
}

final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('hiveServiceProvider must be overridden');
});

class FocusApp extends ConsumerWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    // Define the AMOLED theme
    final ThemeData amoledTheme = ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: Colors.black,
      canvasColor: Colors.black,
      cardColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
      ),
      colorScheme: ColorScheme.dark(
        primary: Colors.blueAccent,
        surface: Colors.black,
        background: Colors.black,
        surfaceContainer: Colors.grey[900]!,
        surfaceContainerHigh: Colors.grey[800]!,
        surfaceContainerLow: Colors.grey[850]!,
        surfaceContainerHighest: Colors.grey[700]!,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: Colors.black,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Focus',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: themeMode == AppTheme.amoled
          ? amoledTheme
          : ThemeData.dark(useMaterial3: true),
      themeMode: themeMode == AppTheme.light
          ? ThemeMode.light
          : ThemeMode.dark,
      home: const HomeScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}