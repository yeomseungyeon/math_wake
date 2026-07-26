import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../data/models/alarm_model.dart';
import '../data/repositories/alarm_repository.dart';
import 'notification_service.dart';

class AlarmScheduler {
  static final AlarmScheduler _instance = AlarmScheduler._();
  factory AlarmScheduler() => _instance;
  AlarmScheduler._();

  final NotificationService _notifService = NotificationService();

  Future<void> initialize() async {
    if (Platform.isAndroid) {
      try {
        await AndroidAlarmManager.initialize();
      } catch (e) {
        debugPrint('[Scheduler] AndroidAlarmManager.initialize failed: $e');
      }
    }
    await _notifService.initialize();
  }

  /// 알람 등록 — 외부 시스템 오류가 나도 호출자에게 예외를 전파하지 않음
  Future<void> schedule(AlarmModel alarm) async {
    await _cancelInternal(alarm.id); // 중복 방지
    if (!alarm.isEnabled) return;

    final trigger = alarm.nextTriggerTime();
    if (trigger == null) return;

    if (Platform.isAndroid) {
      try {
        await _notifService.scheduleAlarm(alarm);
      } catch (e) {
        debugPrint('[Scheduler] notification schedule failed: $e');
      }
      try {
        final callbackId = alarm.id.hashCode.abs() % 100000;
        await AndroidAlarmManager.oneShotAt(
          trigger,
          callbackId,
          _androidAlarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          alarmClock: true,
        );
      } catch (e) {
        debugPrint('[Scheduler] AndroidAlarmManager.oneShotAt failed: $e');
      }
    } else {
      try {
        await _notifService.scheduleAlarm(alarm);
      } catch (e) {
        debugPrint('[Scheduler] notification schedule failed: $e');
      }
    }
  }

  /// 알람 취소 — 실패해도 예외를 전파하지 않음
  Future<void> cancel(String alarmId) async {
    await _cancelInternal(alarmId);
  }

  Future<void> _cancelInternal(String alarmId) async {
    try {
      await _notifService.cancelAlarm(alarmId);
    } catch (e) {
      debugPrint('[Scheduler] cancelAlarm notification failed: $e');
    }
    if (Platform.isAndroid) {
      try {
        final callbackId = alarmId.hashCode.abs() % 100000;
        await AndroidAlarmManager.cancel(callbackId);
      } catch (e) {
        debugPrint('[Scheduler] AndroidAlarmManager.cancel failed: $e');
      }
    }
  }

  /// 앱 재시작/재부팅 후 알람 복원 — 개별 실패가 전체를 막지 않음
  Future<void> rescheduleAll() async {
    final alarms = AlarmRepository().getAll();
    for (final alarm in alarms) {
      if (!alarm.isEnabled) continue;
      try {
        await schedule(alarm);
      } catch (e) {
        debugPrint('[Scheduler] reschedule failed for ${alarm.id}: $e');
      }
    }
  }
}

@pragma('vm:entry-point')
void _androidAlarmCallback() async {
  try {
    await AndroidAlarmManager.initialize();
  } catch (_) {}
}
