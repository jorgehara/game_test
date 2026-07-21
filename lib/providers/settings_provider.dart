// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SharedPreferences? prefs}) : _prefs = prefs;

  static const _soundKey = 'pk.soundEnabled';
  static const _musicKey = 'pk.musicEnabled';
  static const _vibrationKey = 'pk.vibrationEnabled';

  final SharedPreferences? _prefs;
  var _loaded = false;
  var _soundEnabled = true;
  var _musicEnabled = true;
  var _vibrationEnabled = true;

  bool get isLoaded => _loaded;
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  void markLoaded() {
    _loaded = true;
  }

  Future<void> load() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool(_soundKey) ?? true;
    _musicEnabled = prefs.getBool(_musicKey) ?? true;
    _vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _persistBool(_soundKey, value);
    notifyListeners();
  }

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    await _persistBool(_musicKey, value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    await _persistBool(_vibrationKey, value);
    notifyListeners();
  }

  Future<void> _persistBool(String key, bool value) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
