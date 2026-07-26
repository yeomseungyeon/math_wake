import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../core/constants/alarm_constants.dart';
import '../data/models/alarm_model.dart';

/// flutter_local_notifications 기반 알람 스케줄링 서비스
///
/// Android: exact alarm + full-screen intent
/// iOS: 캐스케이드 알림 (30초 간격 × 12회)
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );
    _initialized = true;
  }

  // ─── 권한 요청 ─────────────────────────────────────────────────────────

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission() ?? false;
      await android?.requestExactAlarmsPermission();
      return granted;
    } else if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  // ─── 알람 스케줄 등록 ─────────────────────────────────────────────────

  Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isEnabled) return;
    final trigger = alarm.nextTriggerTime();
    if (trigger == null) return;

    if (Platform.isAndroid) {
      await _scheduleAndroid(alarm, trigger);
    } else if (Platform.isIOS) {
      await _scheduleIosCascade(alarm, trigger);
    }
  }

  /// Android: exact alarm + full-screen intent
  Future<void> _scheduleAndroid(AlarmModel alarm, DateTime trigger) async {
    const androidDetails = AndroidNotificationDetails(
      AlarmConstants.channelId,
      AlarmConstants.channelName,
      channelDescription: AlarmConstants.channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      // 잠금 화면에서 전체 화면으로 열기
      fullScreenIntent: true,
      // 알람 카테고리 (Android 잠금 화면 표시 방식 결정)
      category: AndroidNotificationCategory.alarm,
      // 스와이프로 지우지 못하게
      autoCancel: false,
      ongoing: true,
      // 소리는 포그라운드 서비스에서 재생하므로 알림 자체 사운드는 없앰
      playSound: false,
      enableVibration: false,
    );

    final notifId = _alarmNotifId(alarm.id);
    final tzTime = tz.TZDateTime.from(trigger, tz.local);

    await _plugin.zonedSchedule(
      notifId,
      alarm.label,
      '알람을 끄려면 수학 문제를 풀어주세요',
      tzTime,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: alarm.id, // 탭 시 어떤 알람인지 식별
    );
  }

  /// iOS: 캐스케이드 알림 — 30초 간격으로 12회 예약
  /// 앱이 포그라운드에 오면 just_audio로 전환해 무한 재생
  Future<void> _scheduleIosCascade(AlarmModel alarm, DateTime trigger) async {
    // iOS 알림음은 .caf 형식 필요 — .wav → .caf 변환명 사용
    // (ios/Runner/Sounds/ 아래에 .caf 파일을 별도 추가해야 함)
    final soundFile = alarm.soundAsset.replaceAll('.wav', '.caf');

    for (int i = 0; i < AlarmConstants.iosCascadeCount; i++) {
      final fireAt = trigger.add(
        Duration(seconds: AlarmConstants.iosCascadeIntervalSeconds * i),
      );
      final tzTime = tz.TZDateTime.from(fireAt, tz.local);
      final notifId = _iosCascadeNotifId(alarm.id, i);

      final iosDetails = DarwinNotificationDetails(
        sound: soundFile,
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'ALARM_CATEGORY',
      );

      await _plugin.zonedSchedule(
        notifId,
        alarm.label,
        i == 0 ? '알람 시간입니다! 수학 문제를 풀어주세요' : '아직 알람이 울리고 있습니다 🔔',
        tzTime,
        NotificationDetails(iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: alarm.id,
      );
    }
  }



  // ─── 알람 취소 ────────────────────────────────────────────────────────

  Future<void> cancelAlarm(String alarmId) async {
    if (Platform.isAndroid) {
      await _plugin.cancel(_alarmNotifId(alarmId));
    } else if (Platform.isIOS) {
      // 캐스케이드 알림 전부 취소
      for (int i = 0; i < AlarmConstants.iosCascadeCount; i++) {
        await _plugin.cancel(_iosCascadeNotifId(alarmId, i));
      }
    }
  }

  Future<void> cancelAll() async => _plugin.cancelAll();

  // ─── 알람 ID 계산 헬퍼 ────────────────────────────────────────────────

  /// UUID → 양의 정수 알림 ID (충돌 최소화)
  int _alarmNotifId(String alarmId) =>
      alarmId.hashCode.abs() % AlarmConstants.maxAlarmId;

  int _iosCascadeNotifId(String alarmId, int index) =>
      (_alarmNotifId(alarmId) * 20 + index) % AlarmConstants.maxAlarmId;
}

// ─── 알림 탭 핸들러 (최상위 함수 필수) ──────────────────────────────────

@pragma('vm:entry-point')
void _onBackgroundNotificationTapped(NotificationResponse response) {
  // 백그라운드에서 탭 → 앱이 열리면 payload(alarmId)로 라우팅
}

void _onNotificationTapped(NotificationResponse response) {
  // 포그라운드에서 탭 → navigatorKey 통해 알람 화면으로 이동
  // (app.dart의 navigatorKey 통해 처리)
}
