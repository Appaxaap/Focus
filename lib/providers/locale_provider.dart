import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../services/hive_service.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  final HiveService _hiveService;

  LocaleNotifier(this._hiveService, Locale initialLocale)
      : super(initialLocale);

  Future<void> setLocale(Locale newLocale) async {
    state = newLocale;
    // Save code like "en_US"
    final code = '${newLocale.languageCode}_${newLocale.countryCode}';
    await _hiveService.setLocalePreference(code);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  // You can load saved locale here if needed
  return LocaleNotifier(hiveService, const Locale('en', 'US'));
});