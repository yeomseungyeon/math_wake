import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../data/models/alarm_model.dart';
import '../data/repositories/alarm_repository.dart';
import 'notification_service.dart';

/// 알람 스케줄 등록/취소의 단일 진입점
///
/// Android: flutter_local_notifications(exact + full-screen) +
///          android_alarm_manager_plus(앱 완전 종료 시 백업)
/// iOS: NotificationService의 캐스케이드 알림
class AlarmScheduler {
  static final AlarmScheduler _instance = AlarmScheduler._();
  factory AlarmScheduler() => _instance;
  AlarmScheduler._();

  final NotificationService _notifService = NotificationService();

  Future<void> initialize() async {
    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }
    await _notifService.initialize();
  }

  /// 알람 등록 (신규 저장 또는 수정 후 호출)
  Future<void> schedule(AlarmModel alarm) async {
    // 먼저 기존 예약 취소 후 재등록 (중복 방지)
    await cancel(alarm.id);
    if (!alarm.isEnabled) return;

    final trigger = alarm.nextTriggerTime();
    if (trigger == null) return;

    if (Platform.isAndroid) {
      // 기본 경로: flutter_local_notifications exact alarm
      await _notifService.scheduleAlarm(alarm);

      // 백업 경로: android_alarm_manager_plus
      // 앱이 완전히 종료된 상태에서도 _androidAlarmCallback이 호출됨
      final callbackId = alarm.id.hashCode.abs() % 100000;
      await AndroidAlarmManager.oneShotAt(
        trigger,
        callbackId,
        _androidAlarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        alarmClock: true, // 알람 시계로 등록 (배터리 최적화 무시)
      );
    } else {
      await _notifService.scheduleAlarm(alarm);
    }
  }

  /// 알람 취소
  Future<void> cancel(String alarmId) async {
    await _notifService.cancelAlarm(alarmId);
    if (Platform.isAndroid) {
      final callbackId = alarmId.hashCode.abs() % 100000;
      await AndroidAlarmManager.cancel(callbackId);
    }
  }

  /// 모든 알람 재스케줄 (앱 재시작, 기기 재부팅 후 복원용)
  Future<void> rescheduleAll() async {
    final alarms = AlarmRepository().getAll();
    for (final alarm in alarms) {
      if (alarm.isEnabled) await schedule(alarm);
    }
  }
}

/// Android 알람 콜백 — 앱이 종료되어 있어도 실행됨
/// @pragma('vm:entry-point') 필수: 트리쉐이킹 방지
@pragma('vm:entry-point')
void _androidAlarmCallback() async {
  // 이 시점에서 알람 ID를 알 방법이 없으므로
  // android_alarm_manager_plus를 보조 트리거로만 사용하고
  // 실제 full-screen intent는 flutter_local_notifications가 담당
  // 여기서는 포그라운드 서비스 기동만 트리거 (네이티브 코드와 연동)
  await AndroidAlarmManager.initialize();
}
