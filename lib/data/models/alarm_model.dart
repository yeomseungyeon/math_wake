import 'package:hive/hive.dart';

part 'alarm_model.g.dart';

// ─── 열거형 ────────────────────────────────────────────────────────────────

@HiveType(typeId: 1)
enum AlarmDifficulty {
  @HiveField(0)
  easy,   // 한 자리 덧셈/뺄셈
  @HiveField(1)
  medium, // 두 자리 덧셈/뺄셈, 한 자리 곱셈
  @HiveField(2)
  hard,   // 두 자리 곱셈, 나눗셈, 혼합
}

@HiveType(typeId: 2)
enum VibrationPattern {
  @HiveField(0)
  off,
  @HiveField(1)
  shortPulse,
  @HiveField(2)
  longPulse,
  @HiveField(3)
  strong,
}

// ─── 알람 모델 ─────────────────────────────────────────────────────────────

@HiveType(typeId: 0)
class AlarmModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String label;

  /// 알람 시각 (시)
  @HiveField(2)
  int hour;

  /// 알람 시각 (분)
  @HiveField(3)
  int minute;

  /// 반복 요일: index 0=월, 1=화, ..., 6=일
  @HiveField(4)
  List<bool> repeatDays;

  @HiveField(5)
  bool isEnabled;

  @HiveField(6)
  AlarmDifficulty difficulty;

  /// 연속으로 맞혀야 하는 문제 수 (1~5)
  @HiveField(7)
  int problemCount;

  /// 알람음 파일명 (assets/sounds/ 내 파일 또는 절대 경로)
  @HiveField(8)
  String soundAsset;

  /// 볼륨 (0.0 ~ 1.0)
  @HiveField(9)
  double volume;

  /// 볼륨 점점 증가 옵션
  @HiveField(10)
  bool fadeIn;

  @HiveField(11)
  VibrationPattern vibrationPattern;

  AlarmModel({
    required this.id,
    this.label = '알람',
    required this.hour,
    required this.minute,
    List<bool>? repeatDays,
    this.isEnabled = true,
    this.difficulty = AlarmDifficulty.medium,
    this.problemCount = 3,
    this.soundAsset = 'alarm_classic.mp3',
    this.volume = 0.8,
    this.fadeIn = true,
    this.vibrationPattern = VibrationPattern.shortPulse,
  }) : repeatDays = repeatDays ?? List.filled(7, false);

  /// 다음 알람 발동 시각을 계산 (repeatDays 기반)
  DateTime? nextTriggerTime() {
    final now = DateTime.now();
    final todayAlarm = DateTime(now.year, now.month, now.day, hour, minute);

    // 반복 요일이 하나도 없으면 → 오늘/내일 단발성
    final hasRepeat = repeatDays.any((d) => d);
    if (!hasRepeat) {
      return todayAlarm.isAfter(now) ? todayAlarm : todayAlarm.add(const Duration(days: 1));
    }

    // 오늘부터 7일 안에서 가장 가까운 활성 요일 탐색
    for (int i = 0; i < 7; i++) {
      final candidate = todayAlarm.add(Duration(days: i));
      // DateTime.weekday: 1=월, 7=일 → index 변환: (weekday-1)
      final dayIndex = (candidate.weekday - 1) % 7;
      if (repeatDays[dayIndex]) {
        if (i == 0 && candidate.isAfter(now)) return candidate;
        if (i > 0) return candidate;
      }
    }
    return null;
  }

  String get repeatLabel {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    if (repeatDays.every((d) => d)) return '매일';
    if (repeatDays.sublist(0, 5).every((d) => d) && !repeatDays[5] && !repeatDays[6]) {
      return '평일';
    }
    if (!repeatDays.sublist(0, 5).any((d) => d) && repeatDays[5] && repeatDays[6]) {
      return '주말';
    }
    final selected = <String>[];
    for (int i = 0; i < 7; i++) {
      if (repeatDays[i]) selected.add(days[i]);
    }
    return selected.isEmpty ? '한 번' : selected.join(', ');
  }

  String get timeString =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
