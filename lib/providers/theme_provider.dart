import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus/services/hive_service.dart';

import '../main.dart';

enum AppTheme {
  light,
  dark,
  amoled,
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  final hiveService = ref.read(hiveServiceProvider);
  return ThemeNotifier(hiveService);
});

class ThemeNotifier extends StateNotifier<AppTheme> {
  final HiveService _hiveService;

  ThemeNotifier(this._hiveService) : super(AppTheme.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final savedTheme = await _hiveService.getThemePreference();
      if (savedTheme != null) {
        state = savedTheme;
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    state = theme;
    await _hiveService.setThemePreference(theme);
  }
}