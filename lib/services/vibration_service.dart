import 'package:vibration/vibration.dart';
import '../core/constants/alarm_constants.dart';
import '../data/models/alarm_model.dart';

class VibrationService {
  static final VibrationService _instance = VibrationService._();
  factory VibrationService() => _instance;
  VibrationService._();

  bool _active = false;

  Future<void> startPattern(VibrationPattern pattern) async {
    if (pattern == VibrationPattern.off) return;
    if (!(await Vibration.hasVibrator())) return;

    _active = true;
    final vibPattern = _resolvePattern(pattern);
    // repeat: 0 → 첫 번째 인덱스부터 무한 반복
    Vibration.vibrate(pattern: vibPattern, repeat: 0);
  }

  Future<void> stop() async {
    if (!_active) return;
    _active = false;
    await Vibration.cancel();
  }

  List<int> _resolvePattern(VibrationPattern p) {
    switch (p) {
      case VibrationPattern.shortPulse:
        return AlarmConstants.vibPatternShort;
      case VibrationPattern.longPulse:
        return AlarmConstants.vibPatternLong;
      case VibrationPattern.strong:
        return AlarmConstants.vibPatternStrong;
      case VibrationPattern.off:
        return [];
    }
  }
}
