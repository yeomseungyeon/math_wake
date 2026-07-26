import 'dart:math';
import '../../../data/models/alarm_model.dart';

/// 수학 문제 생성기
class MathProblem {
  final String expression;
  final int answer;

  const MathProblem({required this.expression, required this.answer});

  static MathProblem generate(AlarmDifficulty difficulty) {
    final rand = Random();

    switch (difficulty) {
      case AlarmDifficulty.easy:
        return _easyProblem(rand);
      case AlarmDifficulty.medium:
        return _mediumProblem(rand);
      case AlarmDifficulty.hard:
        return _hardProblem(rand);
    }
  }

  // 쉬움: 한 자리 수 덧셈/뺄셈 (결과 ≥ 0)
  static MathProblem _easyProblem(Random r) {
    final a = r.nextInt(9) + 1; // 1~9
    final b = r.nextInt(9) + 1;
    if (r.nextBool()) {
      return MathProblem(expression: '$a + $b', answer: a + b);
    } else {
      final big = max(a, b);
      final small = min(a, b);
      return MathProblem(expression: '$big - $small', answer: big - small);
    }
  }

  // 보통: 두 자리 덧셈/뺄셈, 한 자리 곱셈
  static MathProblem _mediumProblem(Random r) {
    final type = r.nextInt(3);
    if (type == 0) {
      final a = r.nextInt(90) + 10; // 10~99
      final b = r.nextInt(90) + 10;
      return MathProblem(expression: '$a + $b', answer: a + b);
    } else if (type == 1) {
      final a = r.nextInt(90) + 10;
      final b = r.nextInt(a - 1) + 1; // b < a
      return MathProblem(expression: '$a - $b', answer: a - b);
    } else {
      final a = r.nextInt(9) + 2; // 2~10
      final b = r.nextInt(9) + 2;
      return MathProblem(expression: '$a × $b', answer: a * b);
    }
  }

  // 어려움: 두 자리 곱셈, 나눗셈, 혼합 연산
  static MathProblem _hardProblem(Random r) {
    final type = r.nextInt(3);
    if (type == 0) {
      // 두 자리 곱셈
      final a = r.nextInt(19) + 11; // 11~29
      final b = r.nextInt(9) + 2;  // 2~10
      return MathProblem(expression: '$a × $b', answer: a * b);
    } else if (type == 1) {
      // 나눗셈 (나머지 없이 떨어지게)
      final b = r.nextInt(8) + 2;   // 제수 2~9
      final q = r.nextInt(10) + 2;  // 몫 2~11
      final a = b * q;
      return MathProblem(expression: '$a ÷ $b', answer: q);
    } else {
      // 혼합: (a + b) × c
      final a = r.nextInt(9) + 1;
      final b = r.nextInt(9) + 1;
      final c = r.nextInt(5) + 2;
      return MathProblem(
          expression: '($a + $b) × $c', answer: (a + b) * c);
    }
  }
}
