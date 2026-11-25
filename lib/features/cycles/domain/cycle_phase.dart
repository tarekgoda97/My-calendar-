/// A single colored phase inside a repeating color cycle.
class CyclePhase {
  CyclePhase({
    this.name = '',
    required this.colorValue,
    required this.durationDays,
  }) {
    if (durationDays < 1) {
      throw ArgumentError.value(
          durationDays, 'durationDays', 'must be at least 1');
    }
  }

  final String name;

  /// ARGB color value, e.g. 0xFF2196F3. Kept as int so the domain
  /// layer does not depend on Flutter.
  final int colorValue;

  final int durationDays;
}
