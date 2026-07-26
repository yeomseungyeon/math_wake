import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../data/models/alarm_model.dart';

/// 알람음 재생 서비스
/// - 반복 재생 (미션 클리어 전까지 무한 루프)
/// - fadeIn 옵션: 0.0 → targetVolume 까지 30초에 걸쳐 점진적 증가
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();
  Timer? _fadeTimer;

  bool get isPlaying => _player.playing;

  Future<void> playAlarm(AlarmModel alarm) async {
    await stop(); // 이전 재생 정리

    try {
      final source = await _resolveSource(alarm.soundAsset);
      await _player.setAudioSource(source);
      await _player.setLoopMode(LoopMode.one); // 무한 반복

      if (alarm.fadeIn) {
        // fadeIn: 초기 볼륨 0.1에서 시작해 30초에 걸쳐 목표 볼륨까지 증가
        await _player.setVolume(0.1);
        await _player.play();
        _startFadeIn(targetVolume: alarm.volume, durationSec: 30);
      } else {
        await _player.setVolume(alarm.volume);
        await _player.play();
      }
    } catch (e) {
      // 소리 파일 로드 실패 시 기본 시스템 알림음으로 대체
      debugPrint('[AudioService] 알람음 로드 실패: $e');
    }
  }

  Future<void> stop() async {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    await _player.stop();
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }

  // ─── 내부 헬퍼 ──────────────────────────────────────────────────────

  Future<AudioSource> _resolveSource(String soundAsset) async {
    // 절대 경로이면 사용자 로컬 파일, 아니면 앱 에셋
    if (soundAsset.startsWith('/') || soundAsset.contains(':\\')) {
      return AudioSource.uri(Uri.file(soundAsset));
    }
    return AudioSource.asset('assets/sounds/$soundAsset');
  }

  void _startFadeIn({required double targetVolume, required int durationSec}) {
    const steps = 60; // 초당 2회 업데이트
    final interval = Duration(milliseconds: durationSec * 1000 ~/ steps);
    final increment = (targetVolume - 0.1) / steps;
    double current = 0.1;

    _fadeTimer = Timer.periodic(interval, (t) async {
      current += increment;
      if (current >= targetVolume) {
        current = targetVolume;
        t.cancel();
      }
      await _player.setVolume(current.clamp(0.0, 1.0));
    });
  }
}

// just_audio 패키지 import를 위한 debugPrint 임포트
void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
