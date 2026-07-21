import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/providers/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('shows first drag onboarding once and supports replay', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = OnboardingProvider(prefs: prefs);

    expect(provider.shouldShowDragOnboarding, isTrue);

    await provider.completeDragOnboarding();
    expect(provider.shouldShowDragOnboarding, isFalse);

    final restored = OnboardingProvider(prefs: prefs);
    await restored.load();
    expect(restored.shouldShowDragOnboarding, isFalse);

    await restored.replayDragOnboarding();
    expect(restored.shouldShowDragOnboarding, isTrue);
  });
}
