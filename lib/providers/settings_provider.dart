import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/alarm_constants.dart';
import '../data/models/alarm_model.dart';

/// 앱 전역 기본값 설정 (Hive에 영구 저장)
class AppSettings {
  final AlarmDifficulty defaultDifficulty;
  final int defaultProblemCount;
  final String defaultSound;
  final double defaultVolume;
  final bool defaultFadeIn;
  final VibrationPattern defaultVibration;

  const AppSettings({
    this.defaultDifficulty = AlarmDifficulty.medium,
    this.defaultProblemCount = 3,
    this.defaultSound = 'alarm_classic.mp3',
    this.defaultVolume = 0.8,
    this.defaultFadeIn = true,
    this.defaultVibration = VibrationPattern.shortPulse,
  });

  AppSettings copyWith({
    AlarmDifficulty? defaultDifficulty,
    int? defaultProblemCount,
    String? defaultSound,
    double? defaultVolume,
    bool? defaultFadeIn,
    VibrationPattern? defaultVibration,
  }) =>
      AppSettings(
        defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
        defaultProblemCount: defaultProblemCount ?? this.defaultProblemCount,
        defaultSound: defaultSound ?? this.defaultSound,
        defaultVolume: defaultVolume ?? this.defaultVolume,
        defaultFadeIn: defaultFadeIn ?? this.defaultFadeIn,
        defaultVibration: defaultVibration ?? this.defaultVibration,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  late Box _box;

  @override
  AppSettings build() {
    _box = Hive.box(AlarmConstants.settingsBoxName);
    return _load();
  }

  AppSettings _load() => AppSettings(
        defaultDifficulty: AlarmDifficulty.values[
            _box.get('difficulty', defaultValue: AlarmDifficulty.medium.index)
                as int],
        defaultProblemCount:
            _box.get('problemCount', defaultValue: 3) as int,
        defaultSound:
            _box.get('sound', defaultValue: 'alarm_classic.mp3') as String,
        defaultVolume: (_box.get('volume', defaultValue: 0.8) as num).toDouble(),
        defaultFadeIn: _box.get('fadeIn', defaultValue: true) as bool,
        defaultVibration: VibrationPattern.values[
            _box.get('vibration',
                    defaultValue: VibrationPattern.shortPulse.index) as int],
      );

  Future<void> update(AppSettings settings) async {
    await _box.putAll({
      'difficulty': settings.defaultDifficulty.index,
      'problemCount': settings.defaultProblemCount,
      'sound': settings.defaultSound,
      'volume': settings.defaultVolume,
      'fadeIn': settings.defaultFadeIn,
      'vibration': settings.defaultVibration.index,
    });
    state = settings;
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
