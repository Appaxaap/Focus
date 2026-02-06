import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus/main.dart'; // To access hiveServiceProvider
import 'home_screen.dart';
import 'sunrise_screen.dart';

// This provider will handle the asynchronous logic of deciding which screen to show.
final splashRouterDecisionProvider = FutureProvider<Widget>((ref) async {
  final hiveService = ref.read(hiveServiceProvider);

  final lastShownTimestamp = await hiveService.getLastSunriseTimestamp();
  final lastShownDate = DateTime.fromMillisecondsSinceEpoch(lastShownTimestamp);
  final now = DateTime.now();

  // Conditions to show the Sunrise Screen:
  // 1. It's a new day (the last time it was shown was before today).
  // 2. It's morning (before 12 PM).
  final isNewDay = now.difference(lastShownDate).inDays > 0;
  final isMorning = now.hour < 12;

  if (isNewDay && isMorning) {
    // If we're showing it, update the timestamp for next time.
    await hiveService.saveSunriseTimestamp();
    return const SunriseScreen();
  } else {
    // Otherwise, go straight to the home screen.
    return const HomeScreen(); // Or your DesktopHomeScreen logic
  }
});

class SplashRouterScreen extends ConsumerWidget {
  const SplashRouterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDecision = ref.watch(splashRouterDecisionProvider);

    // Use asyncDecision.when to handle loading, error, and data states
    return asyncDecision.when(
      data: (screen) => screen, // When the future completes, show the decided screen
      loading: () => const Scaffold(
        // A simple loading screen. You can make this fancier.
        backgroundColor: Color(0xFF141118), // Your app's background color
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Scaffold(
        // An error screen in case something goes wrong
        body: Center(
          child: Text('Error deciding route: $err'),
        ),
      ),
    );
  }
}
