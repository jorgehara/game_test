import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores sound music and vibration preferences locally', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = SettingsProvider(prefs: prefs);

    expect(provider.soundEnabled, isTrue);
    expect(provider.musicEnabled, isTrue);
    expect(provider.vibrationEnabled, isTrue);

    await provider.setSoundEnabled(false);
    await provider.setMusicEnabled(false);
    await provider.setVibrationEnabled(false);

    final restored = SettingsProvider(prefs: prefs);
    await restored.load();

    expect(restored.soundEnabled, isFalse);
    expect(restored.musicEnabled, isFalse);
    expect(restored.vibrationEnabled, isFalse);
  });
}
