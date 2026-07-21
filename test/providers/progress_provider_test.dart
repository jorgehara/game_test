import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_kids/providers/progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('marks completed puzzles once and persists locally', () async {
    final prefs = await SharedPreferences.getInstance();
    final provider = ProgressProvider(prefs: prefs);

    expect(provider.isCompleted('lion'), isFalse);

    expect(await provider.markCompleted('lion'), isTrue);
    expect(await provider.markCompleted('lion'), isFalse);

    expect(provider.isCompleted('lion'), isTrue);
    expect(provider.completedCount, 1);

    final restored = ProgressProvider(prefs: prefs);
    await restored.load();

    expect(restored.isCompleted('lion'), isTrue);
    expect(restored.completedCount, 1);
  });
}
