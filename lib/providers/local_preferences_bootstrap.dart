import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_provider.dart';
import 'progress_provider.dart';
import 'settings_provider.dart';

class LocalPreferencesBootstrap {
  LocalPreferencesBootstrap({
    required this.progress,
    required this.settings,
    required this.onboarding,
  });

  final ProgressProvider progress;
  final SettingsProvider settings;
  final OnboardingProvider onboarding;

  static Future<LocalPreferencesBootstrap> load() async {
    final prefs = await SharedPreferences.getInstance();
    final progress = ProgressProvider(prefs: prefs);
    final settings = SettingsProvider(prefs: prefs);
    final onboarding = OnboardingProvider(prefs: prefs);

    await Future.wait([progress.load(), settings.load(), onboarding.load()]);

    return LocalPreferencesBootstrap(
      progress: progress,
      settings: settings,
      onboarding: onboarding,
    );
  }
}
