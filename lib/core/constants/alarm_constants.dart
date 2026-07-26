// 앱 전역 상수
class AlarmConstants {
  AlarmConstants._();

  // Hive box 이름
  static const String alarmBoxName = 'alarms';
  static const String settingsBoxName = 'settings';

  // 알람 채널 (Android)
  static const String channelId = 'math_wake_alarm_channel';
  static const String channelName = 'MathWake 알람';
  static const String channelDescription = '기상 미션 알람 채널';

  // Foreground Service 알림 ID (Android)
  static const int foregroundNotificationId = 888;

  // 알람 ID 범위: 1 ~ 9999 (flutter_local_notifications용)
  static const int maxAlarmId = 9999;

  // iOS 캐스케이드 알림 — 알람당 예약할 반복 알림 개수와 간격(초)
  static const int iosCascadeCount = 12;
  static const int iosCascadeIntervalSeconds = 30;

  // 기본 알람음 에셋 목록 (assets/sounds/ 아래 파일명)
  static const List<String> defaultSounds = [
    'alarm_classic.mp3',
    'alarm_digital.mp3',
    'alarm_gentle.mp3',
  ];

  // 진동 패턴 (ms 단위: [대기, 진동, 대기, 진동, ...])
  static const List<int> vibPatternShort = [0, 200, 200, 200];
  static const List<int> vibPatternLong  = [0, 800, 400, 800];
  static const List<int> vibPatternStrong = [0, 500, 100, 500, 100, 500];
}
