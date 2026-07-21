// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({SharedPreferences? prefs}) : _prefs = prefs;

  static const _dragSeenKey = 'pk.dragOnboardingSeen';

  final SharedPreferences? _prefs;
  var _loaded = false;
  var _dragOnboardingSeen = false;

  bool get isLoaded => _loaded;
  bool get shouldShowDragOnboarding => !_dragOnboardingSeen;

  void markLoaded() {
    _loaded = true;
  }

  Future<void> load() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _dragOnboardingSeen = prefs.getBool(_dragSeenKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> completeDragOnboarding() async {
    _dragOnboardingSeen = true;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_dragSeenKey, true);
    notifyListeners();
  }

  Future<void> replayDragOnboarding() async {
    _dragOnboardingSeen = false;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_dragSeenKey, false);
    notifyListeners();
  }
}
