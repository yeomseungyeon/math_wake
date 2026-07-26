import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/constants/alarm_constants.dart';
import 'data/models/alarm_model.dart';
import 'services/alarm_scheduler.dart';
import 'app.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive 초기화 ──────────────────────────────────────────────────────────
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(AlarmModelAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AlarmDifficultyAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(VibrationPatternAdapter());

  // 박스가 이미 열려있는 경우(백그라운드 isolate 재사용 등) 예외 방지
  if (!Hive.isBoxOpen(AlarmConstants.alarmBoxName)) {
    await Hive.openBox<AlarmModel>(AlarmConstants.alarmBoxName);
  }
  if (!Hive.isBoxOpen(AlarmConstants.settingsBoxName)) {
    await Hive.openBox(AlarmConstants.settingsBoxName);
  }

  // ── 알람 스케줄러 초기화 ────────────────────────────────────────────────
  await AlarmScheduler().initialize();

  // ── 알림 탭 핸들러 등록 ─────────────────────────────────────────────────
  final notifPlugin = FlutterLocalNotificationsPlugin();
  try {
    await notifPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) navigateToAlarmRing(response.payload!);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  } catch (e) {
    debugPrint('[main] notification initialize failed: $e');
  }

  // ── cold-start: fullScreenIntent/알림으로 앱이 실행된 경우 처리 ──────────
  try {
    final launchDetails = await notifPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null) navigateToAlarmRing(payload);
    }
  } catch (e) {
    debugPrint('[main] getNotificationAppLaunchDetails failed: $e');
  }

  // ── 재부팅/앱 재시작 후 알람 복원 ─────────────────────────────────────
  // rescheduleAll 내부에서도 개별 예외를 잡지만 혹시 모를 최상위 오류 방어
  try {
    await AlarmScheduler().rescheduleAll();
  } catch (e) {
    debugPrint('[main] rescheduleAll failed: $e');
  }

  runApp(const MathWakeApp());
}
