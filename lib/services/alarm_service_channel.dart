import 'dart:io';
import 'package:flutter/services.dart';

/// Android AlarmForegroundService와 연결되는 플랫폼 채널
///
/// iOS에서는 호출해도 아무것도 하지 않음 (no-op):
/// iOS는 포그라운드 서비스 개념이 없고, just_audio가 앱이
/// 포그라운드일 때 자체적으로 오디오 세션을 유지함.
class AlarmServiceChannel {
  AlarmServiceChannel._();

  static const _channel = MethodChannel('com.mathwake.math_wake/alarm_service');

  /// 포그라운드 서비스 시작 — AlarmRingScreen initState에서 호출
  static Future<void> startForegroundService(String alarmLabel) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startService', {'label': alarmLabel});
    } on PlatformException catch (e) {
      // 서비스 기동 실패 시에도 앱이 죽지 않게: 오디오는 이미 재생 중
      debugLog('[AlarmServiceChannel] startService 실패: ${e.message}');
    }
  }

  /// 포그라운드 서비스 중지 — 미션 클리어 시 호출
  static Future<void> stopForegroundService() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (e) {
      debugLog('[AlarmServiceChannel] stopService 실패: ${e.message}');
    }
  }
}

void debugLog(String msg) => print(msg); // ignore: avoid_print
