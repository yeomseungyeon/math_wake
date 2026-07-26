import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// 앱 초기 실행 시 필요한 권한을 순서대로 요청
  static Future<void> requestAll(BuildContext context) async {
    if (Platform.isAndroid) {
      await _requestAndroidPermissions(context);
    } else if (Platform.isIOS) {
      // iOS는 NotificationService.requestPermissions()에서 처리
    }
  }

  static Future<void> _requestAndroidPermissions(BuildContext context) async {
    // 1. 알림 권한 (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // 2. 정확한 알람 권한 (Android 12+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      await showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('정확한 알람 권한 필요'),
          content: const Text(
            '설정한 시각 정확히에 알람이 울리려면\n"정확한 알람" 권한이 필요합니다.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Permission.scheduleExactAlarm.request();
              },
              child: const Text('허용하기'),
            ),
          ],
        ),
      );
    }

    // 3. 배터리 최적화 예외 (Android)
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('배터리 최적화 예외'),
          content: const Text(
            '앱이 종료된 상태에서도 알람이 울리려면\n'
            '배터리 최적화 예외가 필요합니다.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('나중에')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Permission.ignoreBatteryOptimizations.request();
              },
              child: const Text('설정하기'),
            ),
          ],
        ),
      );
    }
  }
}
