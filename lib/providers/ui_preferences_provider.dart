import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';

class UiPreferencesState {
  final bool reducedMotion;
  final bool compactDensity;

  const UiPreferencesState({
    this.reducedMotion = false,
    this.compactDensity = false,
  });

  UiPreferencesState copyWith({bool? reducedMotion, bool? compactDensity}) {
    return UiPreferencesState(
      reducedMotion: reducedMotion ?? this.reducedMotion,
      compactDensity: compactDensity ?? this.compactDensity,
    );
  }
}

class UiPreferencesNotifier extends StateNotifier<UiPreferencesState> {
  UiPreferencesNotifier(this.ref) : super(const UiPreferencesState()) {
    _load();
  }

  final Ref ref;

  Future<void> _load() async {
    final hive = ref.read(hiveServiceProvider);
    final reduced = await hive.getReducedMotionPreference();
    final compact = await hive.getCompactDensityPreference();
    state = state.copyWith(reducedMotion: reduced, compactDensity: compact);
  }

  Future<void> setReducedMotion(bool value) async {
    state = state.copyWith(reducedMotion: value);
    await ref.read(hiveServiceProvider).setReducedMotionPreference(value);
  }

  Future<void> setCompactDensity(bool value) async {
    state = state.copyWith(compactDensity: value);
    await ref.read(hiveServiceProvider).setCompactDensityPreference(value);
  }
}

final uiPreferencesProvider =
    StateNotifierProvider<UiPreferencesNotifier, UiPreferencesState>((ref) {
      return UiPreferencesNotifier(ref);
    });
