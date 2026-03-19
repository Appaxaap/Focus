import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quadrant_enum.dart';
import 'dart:convert';

final quadrantNamesProvider =
    StateNotifierProvider<QuadrantNamesNotifier, Map<Quadrant, String>>((ref) {
      return QuadrantNamesNotifier();
    });

class QuadrantNamesNotifier extends StateNotifier<Map<Quadrant, String>> {
  QuadrantNamesNotifier() : super({}) {
    loadNames();
  }

  static const _prefsKey = 'quadrant_names';

  Future<void> loadNames() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      try {
        final Map<String, dynamic> decoded = Map.from(jsonDecode(saved));
        state = {
          for (var entry in decoded.entries)
            Quadrant.values.firstWhere((q) => q.toString() == entry.key):
                entry.value as String,
        };
      } catch (_) {
        _setDefaults();
      }
    } else {
      _setDefaults();
    }
  }

  void _setDefaults() {
    state = {
      Quadrant.urgentImportant: 'Do',
      Quadrant.notUrgentImportant: 'Plan',
      Quadrant.urgentNotImportant: 'Delegate',
      Quadrant.notUrgentNotImportant: 'Delete',
    };
  }

  Future<void> updateName(Quadrant quadrant, String newName) async {
    state = {...state, quadrant: newName};
    final prefs = await SharedPreferences.getInstance();
    final toSave = {
      for (var entry in state.entries) entry.key.toString(): entry.value,
    };
    await prefs.setString(_prefsKey, jsonEncode(toSave));
  }
}
