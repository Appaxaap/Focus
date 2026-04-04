import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';

class AppIconBadgeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final hiveService = ref.read(hiveServiceProvider);
    return hiveService.getAppIconBadgeEnabledPreference();
  }

  Future<void> setEnabled(bool value) async {
    state = AsyncData(value);
    final hiveService = ref.read(hiveServiceProvider);
    await hiveService.setAppIconBadgeEnabledPreference(value);
  }
}

final appIconBadgeProvider = AsyncNotifierProvider<AppIconBadgeNotifier, bool>(
  AppIconBadgeNotifier.new,
);
