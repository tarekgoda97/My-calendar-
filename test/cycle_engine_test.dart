import 'package:flutter_test/flutter_test.dart';
import 'package:my_calendar/features/cycles/domain/color_cycle.dart';
import 'package:my_calendar/features/cycles/domain/cycle_engine.dart';
import 'package:my_calendar/features/cycles/domain/cycle_phase.dart';

const blue = 0xFF2196F3;
const orange = 0xFFFF9800;
const green = 0xFF4CAF50;
const red = 0xFFF44336;
const yellow = 0xFFFFEB3B;

ColorCycle workCycle() => ColorCycle(
      id: 'work',
      name: 'Work Schedule',
      startDate: DateTime(2026, 12, 1),
      phases: [
        CyclePhase(colorValue: blue, durationDays: 10),
        CyclePhase(colorValue: orange, durationDays: 5),
      ],
    );

void main() {
  group('daysBetween', () {
    test('handles leap and non-leap February', () {
      expect(CycleEngine.daysBetween(DateTime(2024, 2, 28), DateTime(2024, 3, 1)), 2);
      expect(CycleEngine.daysBetween(DateTime(2025, 2, 28), DateTime(2025, 3, 1)), 1);
    });

    test('handles year boundary', () {
      expect(CycleEngine.daysBetween(DateTime(2026, 12, 30), DateTime(2027, 1, 2)), 3);
    });

    test('ignores time of day and daylight saving', () {
      expect(
        CycleEngine.daysBetween(
            DateTime(2026, 4, 23, 23, 59), DateTime(2026, 4, 25, 0, 1)),
        2,
      );
    });
  });

  group('single cycle', () {
    test('first phase on the start date', () {
      final m = CycleEngine.matchFor(workCycle(), DateTime(2026, 12, 1))!;
      expect(m.phase.colorValue, blue);
      expect(m.dayInPhase, 1);
      expect(m.cycleNumber, 0);
    });

    test('phase boundaries', () {
      final c = workCycle();
      expect(CycleEngine.matchFor(c, DateTime(2026, 12, 10))!.phase.colorValue, blue);
      expect(CycleEngine.matchFor(c, DateTime(2026, 12, 10))!.dayInPhase, 10);
      expect(CycleEngine.matchFor(c, DateTime(2026, 12, 11))!.phase.colorValue, orange);
      expect(CycleEngine.matchFor(c, DateTime(2026, 12, 15))!.dayInPhase, 5);
    });

    test('pattern repeats after 15 days', () {
      final m = CycleEngine.matchFor(workCycle(), DateTime(2026, 12, 16))!;
      expect(m.phase.colorValue, blue);
      expect(m.dayInPhase, 1);
      expect(m.cycleNumber, 1);
    });

    test('returns null before the start date', () {
      expect(CycleEngine.matchFor(workCycle(), DateTime(2026, 11, 30)), isNull);
    });

    test('continues across a full year', () {
      // 365 days later: 365 % 15 = 5 -> blue, day 6.
      final m = CycleEngine.matchFor(workCycle(), DateTime(2027, 12, 1))!;
      expect(m.phase.colorValue, blue);
      expect(m.dayInPhase, 6);
      expect(m.cycleNumber, 24);
    });

    test('works across leap day 2024', () {
      final c = ColorCycle(
        id: 'leap',
        name: 'Leap',
        startDate: DateTime(2024, 2, 20),
        phases: [
          CyclePhase(colorValue: green, durationDays: 7),
          CyclePhase(colorValue: red, durationDays: 3),
        ],
      );
      final feb29 = CycleEngine.matchFor(c, DateTime(2024, 2, 29))!;
      expect(feb29.phase.colorValue, red);
      expect(feb29.dayInPhase, 3);
      final mar1 = CycleEngine.matchFor(c, DateTime(2024, 3, 1))!;
      expect(mar1.phase.colorValue, green);
      expect(mar1.cycleNumber, 1);
    });

    test('disabled cycle never matches', () {
      final c = ColorCycle(
        id: 'off',
        name: 'Off',
        startDate: DateTime(2026, 1, 1),
        isEnabled: false,
        phases: [CyclePhase(colorValue: blue, durationDays: 3)],
      );
      expect(CycleEngine.matchFor(c, DateTime(2026, 1, 2)), isNull);
    });
  });

  group('overlapping cycles', () {
    final a = ColorCycle(
      id: 'a',
      name: 'A',
      priority: 1,
      startDate: DateTime(2026, 11, 1),
      phases: [
        CyclePhase(colorValue: green, durationDays: 7),
        CyclePhase(colorValue: red, durationDays: 3),
      ],
    );
    final b = ColorCycle(
      id: 'b',
      name: 'B',
      priority: 5,
      startDate: DateTime(2026, 11, 20),
      phases: [
        CyclePhase(colorValue: blue, durationDays: 4),
        CyclePhase(colorValue: yellow, durationDays: 2),
      ],
    );

    test('keeps every overlapping cycle, highest priority first', () {
      final matches = CycleEngine.matchesFor([a, b], DateTime(2026, 11, 21));
      expect(matches.length, 2);
      expect(matches.first.cycle.id, 'b');
      expect(matches.last.cycle.id, 'a');
      expect(CycleEngine.primaryFor([a, b], DateTime(2026, 11, 21))!.phase.colorValue, blue);
    });

    test('only the active cycle shows when the other has not started', () {
      final matches = CycleEngine.matchesFor([a, b], DateTime(2026, 11, 10));
      expect(matches.length, 1);
      expect(matches.single.cycle.id, 'a');
    });

    test('equal priority is resolved deterministically by id', () {
      final x = ColorCycle(
          id: 'x', name: 'X', startDate: DateTime(2026, 1, 1),
          phases: [CyclePhase(colorValue: red, durationDays: 2)]);
      final y = ColorCycle(
          id: 'y', name: 'Y', startDate: DateTime(2026, 1, 1),
          phases: [CyclePhase(colorValue: blue, durationDays: 2)]);
      expect(CycleEngine.primaryFor([y, x], DateTime(2026, 1, 1))!.cycle.id, 'x');
    });

    test('no cycles means no primary', () {
      expect(CycleEngine.primaryFor([], DateTime(2026, 1, 1)), isNull);
    });
  });
}
