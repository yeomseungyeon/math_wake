import 'package:flutter_test/flutter_test.dart';
import 'package:math_wake/features/alarm_ring/widgets/math_problem_widget.dart';
import 'package:math_wake/data/models/alarm_model.dart';

void main() {
  group('MathProblem 생성 테스트', () {
    test('쉬움: 결과가 0 이상인 덧셈/뺄셈', () {
      for (int i = 0; i < 50; i++) {
        final p = MathProblem.generate(AlarmDifficulty.easy);
        expect(p.answer, greaterThanOrEqualTo(0));
        expect(p.expression, isNotEmpty);
      }
    });

    test('보통: 결과가 양수', () {
      for (int i = 0; i < 50; i++) {
        final p = MathProblem.generate(AlarmDifficulty.medium);
        expect(p.answer, greaterThan(0));
      }
    });

    test('어려움: 결과가 양수', () {
      for (int i = 0; i < 50; i++) {
        final p = MathProblem.generate(AlarmDifficulty.hard);
        expect(p.answer, greaterThan(0));
      }
    });
  });

  group('AlarmModel 시각 계산 테스트', () {
    test('반복 없는 알람 — 오늘 또는 내일 시각 반환', () {
      final alarm = AlarmModel(
        id: 'test',
        hour: 7,
        minute: 0,
        repeatDays: List.filled(7, false),
      );
      final trigger = alarm.nextTriggerTime();
      expect(trigger, isNotNull);
      expect(trigger!.hour, 7);
      expect(trigger.minute, 0);
    });
  });
}
