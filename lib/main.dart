import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus/services/hive_service.dart';
import 'package:focus/services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'models/quadrant_enum.dart';
import 'models/task_models.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

// Define the custom background color
const Color appBackgroundColor = Color(0xFF141118);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  // notification initialization
  NotificationService().initialize();

  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(QuadrantAdapter());

  final hiveService = HiveService();
  await hiveService.initialize();

  final savedTheme = await hiveService.getThemePreference();

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

final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('hiveServiceProvider must be overridden');
});

class FocusApp extends ConsumerStatefulWidget {
  const FocusApp({super.key});

  @override
  ConsumerState<FocusApp> createState() => _FocusAppState();
}

class _FocusAppState extends ConsumerState<FocusApp> {
  @override
  void initState() {
    super.initState();
    // Enable edge-to-edge display
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    // Define the AMOLED theme with DM Sans and custom background
    final ThemeData amoledTheme = ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: appBackgroundColor, // Custom background
      canvasColor: appBackgroundColor,
      cardColor: appBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: appBackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: ColorScheme.dark(
        primary: Colors.blueAccent,
        surface: appBackgroundColor,
        background: appBackgroundColor,
        surfaceContainer: Colors.grey[900]!,
        surfaceContainerHigh: Colors.grey[800]!,
        surfaceContainerLow: Colors.grey[850]!,
        surfaceContainerHighest: Colors.grey[700]!,
      ),
      bottomAppBarTheme: const BottomAppBarTheme(color: appBackgroundColor),
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.white, displayColor: Colors.white),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Focus',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: appBackgroundColor, // Custom background
        appBarTheme: const AppBarTheme(backgroundColor: appBackgroundColor),
        bottomAppBarTheme: const BottomAppBarTheme(color: appBackgroundColor),
        textTheme: GoogleFonts.dmSansTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      darkTheme:
          themeMode == AppTheme.amoled
              ? amoledTheme
              : ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor:
                    appBackgroundColor, // Custom background
                appBarTheme: const AppBarTheme(
                  backgroundColor: appBackgroundColor,
                ),
                bottomAppBarTheme : const BottomAppBarTheme(
                  color: appBackgroundColor,
                ),
                textTheme: GoogleFonts.dmSansTextTheme(
                  ThemeData.dark(useMaterial3: true).textTheme,
                ).apply(bodyColor: Colors.white, displayColor: Colors.white),
              ),
      themeMode: themeMode == AppTheme.light ? ThemeMode.light : ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
