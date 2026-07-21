// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressProvider extends ChangeNotifier {
  ProgressProvider({SharedPreferences? prefs}) : _prefs = prefs;

  static const _completedKey = 'pk.completedPuzzleIds';

  final SharedPreferences? _prefs;
  final Set<String> _completedPuzzleIds = {};
  var _loaded = false;

  bool get isLoaded => _loaded;

  int get completedCount => _completedPuzzleIds.length;

  Set<String> get completedPuzzleIds => Set.unmodifiable(_completedPuzzleIds);

  void markLoaded() {
    _loaded = true;
  }

  Future<void> load() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _completedPuzzleIds
      ..clear()
      ..addAll(prefs.getStringList(_completedKey) ?? const []);
    _loaded = true;
    notifyListeners();
  }

  bool isCompleted(String puzzleId) => _completedPuzzleIds.contains(puzzleId);

  Future<bool> markCompleted(String puzzleId) async {
    if (!_completedPuzzleIds.add(puzzleId)) {
      return false;
    }

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setStringList(_completedKey, _completedPuzzleIds.toList());
    notifyListeners();
    return true;
  }
}
