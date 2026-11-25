import 'cycle_phase.dart';

/// A repeating pattern of colored phases that starts on [startDate].
class ColorCycle {
  ColorCycle({
    required this.id,
    required this.name,
    required DateTime startDate,
    required List<CyclePhase> phases,
    this.isEnabled = true,
    this.priority = 0,
  })  : startDate = DateTime.utc(startDate.year, startDate.month, startDate.day),
        phases = List.unmodifiable(phases) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    if (phases.isEmpty) {
      throw ArgumentError.value(phases, 'phases', 'at least one phase needed');
    }
  }

  final String id;
  final String name;

  /// Date-only value (UTC midnight).
  final DateTime startDate;
  final List<CyclePhase> phases;
  final bool isEnabled;

  /// Higher number = controls the main background color on overlap.
  final int priority;

  int get totalDays => phases.fold(0, (sum, p) => sum + p.durationDays);
}
