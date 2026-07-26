package com.mathwake.math_wake

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * 알람 울림 포그라운드 서비스
 *
 * 역할:
 *   1. AlarmRingScreen이 열리면 Flutter 측 AlarmServiceChannel이 이 서비스를 기동
 *   2. "mediaPlayback" 타입 포그라운드 알림을 띄워 OS가 프로세스를 종료하지 못하게 막음
 *   3. 실제 오디오 재생은 Flutter just_audio가 담당 (이 서비스는 프로세스 보호만)
 *   4. 미션 클리어 → AlarmServiceChannel.stopForegroundService() → ACTION_STOP → stopSelf()
 *
 * 왜 포그라운드 서비스가 필요한가:
 *   - 사용자가 홈 버튼을 누르면 앱이 백그라운드로 가고,
 *     Android는 메모리 압박 시 백그라운드 앱의 프로세스를 종료할 수 있음
 *   - 포그라운드 서비스가 실행 중이면 OS는 해당 프로세스를 강제 종료할 수 없음
 *   - 결과적으로 just_audio도 계속 재생되고 미션 화면도 유지됨
 */
class AlarmForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "math_wake_fg_channel"
        const val NOTIF_ID = 888
        const val ACTION_STOP = "com.mathwake.math_wake.STOP_ALARM"
        const val EXTRA_LABEL = "alarm_label"
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // ACTION_STOP을 받으면 즉시 서비스 종료
        if (intent?.action == ACTION_STOP) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        val label = intent?.getStringExtra(EXTRA_LABEL) ?: "알람"

        createNotificationChannel()
        // startForeground를 반드시 5초 이내에 호출해야 ANR 방지
        startForeground(NOTIF_ID, buildNotification(label))

        // START_STICKY: 서비스가 강제 종료되어도 OS가 재시작 시도
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        // 혹시 남아 있을 수 있는 알림 제거
        stopForeground(STOP_FOREGROUND_REMOVE)
    }

    // ─── 알림 채널 (Android 8.0+ 필수) ─────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "MathWake 알람 서비스",
                // LOW: 소리/진동 없음 (실제 알람음은 just_audio가 담당)
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "알람 해제 전까지 앱을 활성 상태로 유지합니다"
                setSound(null, null)
                enableVibration(false)
            }
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    // ─── 포그라운드 알림 (사용자가 볼 수 있는 "알람 울리는 중" 배너) ────────

    private fun buildNotification(label: String): Notification {
        // 탭하면 알람 미션 화면(MainActivity)으로 복귀
        val openIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("$label 알람")
            .setContentText("수학 문제를 풀어야 알람이 꺼집니다 — 탭해서 돌아가기")
            .setContentIntent(openIntent)
            .setOngoing(true)          // 스와이프로 제거 불가
            .setAutoCancel(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            // 알람 화면으로 돌아가는 액션 버튼
            .addAction(
                android.R.drawable.ic_media_play,
                "알람 화면 열기",
                openIntent
            )
            .build()
    }
}
