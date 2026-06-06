import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/main.dart';
import 'package:focus/models/task_models.dart';
import 'package:focus/providers/theme_provider.dart';
import 'package:focus/services/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestHiveService extends HiveService {
  @override
  Future<bool> getAppIconBadgeEnabledPreference() async => true;

  @override
  Future<List<Task>> getAllTasks() async => [];

  @override
  Future<int> getLastSunriseTimestamp() async =>
      DateTime.now().millisecondsSinceEpoch;

  @override
  Future<bool> getShowCompletedPreference() async => false;

  @override
  Future<AppTheme?> getThemePreference() async => AppTheme.dark;
}

void main() {
  testWidgets('Focus app boots inside ProviderScope', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});
    final hiveService = _TestHiveService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hiveServiceProvider.overrideWithValue(hiveService),
        ],
        child: const FocusApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.text('Focus'), findsWidgets);
  });
}
