package com.mathwake.math_wake

import android.app.KeyguardManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // Dart 코드와 통신하는 채널 — AlarmServiceChannel.dart와 이름 일치해야 함
    private val SERVICE_CHANNEL = "com.mathwake.math_wake/alarm_service"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 잠금 화면 위에서 Activity 표시 + 화면 켜기
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val km = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
            km.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Flutter → Android 포그라운드 서비스 제어 채널
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val label = call.argument<String>("label") ?: "알람"
                        startAlarmService(label)
                        result.success(null)
                    }
                    "stopService" -> {
                        stopAlarmService()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ─── 내부 헬퍼 ──────────────────────────────────────────────────────────

    private fun startAlarmService(label: String) {
        val intent = Intent(this, AlarmForegroundService::class.java).apply {
            putExtra(AlarmForegroundService.EXTRA_LABEL, label)
        }
        // Android 8.0+ 에서는 startForegroundService 사용 필수
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopAlarmService() {
        val intent = Intent(this, AlarmForegroundService::class.java).apply {
            action = AlarmForegroundService.ACTION_STOP
        }
        startService(intent) // stopSelf()를 서비스 내부에서 호출하게 위임
    }
}
