import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/constants/alarm_constants.dart';
import 'data/models/alarm_model.dart';
import 'services/alarm_scheduler.dart';
import 'app.dart';

/// 앱 완전 종료 상태에서 알림 탭 시 이 함수가 먼저 호출됨
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // 앱이 다시 열리면 onDidReceiveNotificationResponse가 이어서 처리
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive 초기화 ──────────────────────────────────────────────────────────
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(AlarmModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(AlarmDifficultyAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(VibrationPatternAdapter());
  }
  await Hive.openBox<AlarmModel>(AlarmConstants.alarmBoxName);
  await Hive.openBox(AlarmConstants.settingsBoxName);

  // ── 알람 스케줄러 초기화 ────────────────────────────────────────────────
  await AlarmScheduler().initialize();

  // ── 알림 탭 핸들러 등록 ─────────────────────────────────────────────────
  final notifPlugin = FlutterLocalNotificationsPlugin();
  await notifPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (response) {
      if (response.payload != null) {
        navigateToAlarmRing(response.payload!);
      }
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // ── cold-start: 알림/fullScreenIntent로 앱이 실행된 경우 처리 ───────────
  // navigator 준비 전이므로 navigateToAlarmRing이 _pendingAlarmId에 보관하고
  // MathWakeApp.initState의 addPostFrameCallback에서 실제 이동 처리
  final launchDetails = await notifPlugin.getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp == true) {
    final payload = launchDetails?.notificationResponse?.payload;
    if (payload != null) navigateToAlarmRing(payload);
  }

  // ── 재부팅 또는 앱 재시작 후 알람 복원 ─────────────────────────────────
  await AlarmScheduler().rescheduleAll();

  runApp(const MathWakeApp());
}
