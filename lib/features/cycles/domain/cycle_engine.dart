import 'color_cycle.dart';
import 'cycle_phase.dart';

/// Result of applying one cycle to one date.
class CycleMatch {
  const CycleMatch({
    required this.cycle,
    required this.phaseIndex,
    required this.phase,
    required this.dayInPhase,
    required this.cycleNumber,
  });

  final ColorCycle cycle;
  final int phaseIndex;
  final CyclePhase phase;

  /// 1-based day inside the phase.
  final int dayInPhase;

  /// 0 for the first repetition, 1 for the second, ...
  final int cycleNumber;
}

class CycleEngine {
  const CycleEngine._();

  /// Strips the time part. Uses UTC so daylight saving never shifts the day.
  static DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// Whole calendar days from [from] to [to] (negative if [to] is earlier).
  static int daysBetween(DateTime from, DateTime to) =>
      dateOnly(to).difference(dateOnly(from)).inDays;

  /// Returns the phase of [cycle] on [date], or null when the cycle is
  /// disabled or [date] is before the cycle's start date.
  static CycleMatch? matchFor(ColorCycle cycle, DateTime date) {
    if (!cycle.isEnabled) return null;

    final offset = daysBetween(cycle.startDate, date);
    if (offset < 0) return null;

    final total = cycle.totalDays;
    var remaining = offset % total;

    for (var i = 0; i < cycle.phases.length; i++) {
      final phase = cycle.phases[i];
      if (remaining < phase.durationDays) {
        return CycleMatch(
          cycle: cycle,
          phaseIndex: i,
          phase: phase,
          dayInPhase: remaining + 1,
          cycleNumber: offset ~/ total,
        );
      }
      remaining -= phase.durationDays;
    }
    return null; // Unreachable: remaining is always < total.
  }

  /// All matching cycles for [date], highest priority first.
  /// Ties are broken by id so the order is always deterministic.
  static List<CycleMatch> matchesFor(List<ColorCycle> cycles, DateTime date) {
    final matches = <CycleMatch>[];
    for (final cycle in cycles) {
      final m = matchFor(cycle, date);
      if (m != null) matches.add(m);
    }
    matches.sort((a, b) {
      final byPriority = b.cycle.priority.compareTo(a.cycle.priority);
      return byPriority != 0 ? byPriority : a.cycle.id.compareTo(b.cycle.id);
    });
    return matches;
  }

  /// The cycle that controls the main background color, or null.
  static CycleMatch? primaryFor(List<ColorCycle> cycles, DateTime date) {
    final matches = matchesFor(cycles, date);
    return matches.isEmpty ? null : matches.first;
  }
}
