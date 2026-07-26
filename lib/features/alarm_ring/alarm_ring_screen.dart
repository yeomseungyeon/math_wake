import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/alarm_model.dart';
import '../../data/repositories/alarm_repository.dart';
import '../../services/audio_player_service.dart';
import '../../services/vibration_service.dart';
import '../../services/alarm_scheduler.dart';
import '../../services/alarm_service_channel.dart';
import 'widgets/math_problem_widget.dart';
import 'widgets/numpad_widget.dart';

/// 알람 울림 화면 — 미션을 클리어해야만 이 화면에서 나갈 수 있음
///
/// 진입 방법:
///   - Android: full-screen intent가 이 화면의 라우트를 직접 열음
///   - iOS: 알림 탭 → main.dart의 onDidReceiveNotificationResponse → push
class AlarmRingScreen extends StatefulWidget {
  const AlarmRingScreen({super.key, required this.alarmId});
  final String alarmId;

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with WidgetsBindingObserver {
  final _audio = AudioPlayerService();
  final _vib = VibrationService();

  late AlarmModel _alarm;
  late MathProblem _currentProblem;

  String _input = '';
  int _solvedCount = 0; // 연속 정답 카운트
  bool _showError = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 잠금 화면 위에 표시 + 화면 켜짐 유지
    _setSystemFlags();
    WakelockPlus.enable();

    final alarm = AlarmRepository().getById(widget.alarmId);
    if (alarm == null) {
      // 알람 데이터 없을 경우 (예: 삭제된 알람) 바로 종료
      WidgetsBinding.instance.addPostFrameCallback((_) => _dismiss());
      return;
    }
    _alarm = alarm;
    _currentProblem = MathProblem.generate(_alarm.difficulty);

    // 오디오 + 진동 시작
    _audio.playAlarm(_alarm);
    _vib.startPattern(_alarm.vibrationPattern);

    // Android 포그라운드 서비스 기동:
    // 홈 버튼을 눌러 앱이 백그라운드로 가도 프로세스가 유지되어
    // just_audio 재생이 끊기지 않음
    AlarmServiceChannel.startForegroundService(_alarm.label);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  // ─── 잠금 화면 위 플래그 (Android) ───────────────────────────────────────

  void _setSystemFlags() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // ─── 미션 로직 ───────────────────────────────────────────────────────────

  void _onDigit(String d) {
    if (_input.length >= 6) return; // 최대 자릿수 제한
    setState(() {
      _input += d;
      _showError = false;
    });
  }

  void _onDelete() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _onSubmit() {
    if (_input.isEmpty) return;
    final userAnswer = int.tryParse(_input);

    if (userAnswer == _currentProblem.answer) {
      // 정답!
      _solvedCount++;
      if (_solvedCount >= _alarm.problemCount) {
        // 모든 연속 문제 클리어 → 알람 종료
        setState(() => _showSuccess = true);
        Future.delayed(const Duration(milliseconds: 800), _dismiss);
      } else {
        // 다음 문제 출제
        setState(() {
          _input = '';
          _currentProblem = MathProblem.generate(_alarm.difficulty);
          _showError = false;
        });
      }
    } else {
      // 오답 → 새 문제로 교체 (연속 카운트 리셋)
      setState(() {
        _input = '';
        _showError = true;
        _solvedCount = 0;
        _currentProblem = MathProblem.generate(_alarm.difficulty);
      });
      // 0.8초 후 오류 메시지 제거
      Future.delayed(
          const Duration(milliseconds: 800),
          () => mounted ? setState(() => _showError = false) : null);
    }
  }

  /// 미션 클리어 후 정리
  Future<void> _dismiss() async {
    // 포그라운드 서비스 먼저 종료 (Android 전용, iOS는 no-op)
    await AlarmServiceChannel.stopForegroundService();

    await _audio.stop();
    await _vib.stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // 다음 반복 알람 재스케줄 (반복 요일이 있는 경우)
    if (_alarm.repeatDays.any((d) => d)) {
      await AlarmScheduler().schedule(_alarm);
    }

    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // 알람 데이터 로드 실패 시 빈 화면
    if (!_isAlarmLoaded) return const SizedBox.shrink();

    final remaining = _alarm.problemCount - _solvedCount;

    return PopScope(
      // 뒤로 가기 버튼으로 나갈 수 없게 차단
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ── 상단: 알람 정보 ──────────────────────────────────
                Text(
                  _alarm.timeString,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textPrimary,
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  _alarm.label,
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),

                // ── 진행 상태 ────────────────────────────────────────
                if (_alarm.problemCount > 1)
                  Text(
                    '$remaining문제 남음',
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 14),
                  ),

                const Spacer(),

                // ── 수학 문제 ────────────────────────────────────────
                AnimatedOpacity(
                  opacity: _showSuccess ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _showError
                            ? AppColors.accent
                            : AppColors.divider,
                        width: _showError ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '다음 수식의 답은?',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentProblem.expression,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_showError) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '❌ 틀렸습니다! 다시 도전하세요',
                            style: TextStyle(
                                color: AppColors.accent, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── 미션 클리어 메시지 ───────────────────────────────
                if (_showSuccess)
                  const Text(
                    '✅ 알람 해제!',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),

                const Spacer(),

                // ── 키패드 ───────────────────────────────────────────
                NumpadWidget(
                  input: _input,
                  onDigit: _onDigit,
                  onDelete: _onDelete,
                  onSubmit: _onSubmit,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _isAlarmLoaded {
    try {
      // ignore: unnecessary_null_comparison
      return _alarm != null;
    } catch (_) {
      return false;
    }
  }
}
