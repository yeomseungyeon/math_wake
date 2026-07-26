import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/alarm_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/alarm_model.dart';
import '../../providers/alarm_list_provider.dart';
import '../../providers/settings_provider.dart';
import 'widgets/weekday_selector.dart';
import 'widgets/difficulty_selector.dart';
import 'widgets/sound_picker_sheet.dart';

class AlarmEditScreen extends ConsumerStatefulWidget {
  const AlarmEditScreen({super.key, this.alarm});
  final AlarmModel? alarm; // null이면 신규 추가

  @override
  ConsumerState<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends ConsumerState<AlarmEditScreen> {
  late TimeOfDay _time;
  late String _label;
  late TextEditingController _labelController;
  late List<bool> _repeatDays;
  late AlarmDifficulty _difficulty;
  late int _problemCount;
  late String _soundAsset;
  late double _volume;
  late bool _fadeIn;
  late VibrationPattern _vibration;

  bool get _isEditing => widget.alarm != null;

  @override
  void initState() {
    super.initState();
    final a = widget.alarm;
    final defaults = ref.read(settingsProvider);
    _time = a != null
        ? TimeOfDay(hour: a.hour, minute: a.minute)
        : TimeOfDay.now();
    _label = a?.label ?? '알람';
    _labelController = TextEditingController(text: _label);
    _repeatDays = List.from(a?.repeatDays ?? List.filled(7, false));
    _difficulty = a?.difficulty ?? defaults.defaultDifficulty;
    _problemCount = a?.problemCount ?? defaults.defaultProblemCount;
    _soundAsset = a?.soundAsset ?? defaults.defaultSound;
    _volume = a?.volume ?? defaults.defaultVolume;
    _fadeIn = a?.fadeIn ?? defaults.defaultFadeIn;
    _vibration = a?.vibrationPattern ?? defaults.defaultVibration;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final alarm = AlarmModel(
      id: widget.alarm?.id ?? const Uuid().v4(),
      label: _labelController.text.trim().isEmpty ? '알람' : _labelController.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
      repeatDays: _repeatDays,
      isEnabled: widget.alarm?.isEnabled ?? true,
      difficulty: _difficulty,
      problemCount: _problemCount,
      soundAsset: _soundAsset,
      volume: _volume,
      fadeIn: _fadeIn,
      vibrationPattern: _vibration,
    );

    if (_isEditing) {
      await ref.read(alarmListProvider.notifier).update(alarm);
    } else {
      await ref.read(alarmListProvider.notifier).add(alarm);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? '알람 편집' : '새 알람',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('저장',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 시간 선택 ──────────────────────────────────────────────
          _SectionCard(
            child: GestureDetector(
              onTap: _pickTime,
              child: Center(
                child: Text(
                  '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textPrimary,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),

          // ── 라벨 ───────────────────────────────────────────────────
          _SectionCard(
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: '알람 이름',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                prefixIcon:
                    Icon(Icons.label_outline, color: AppColors.textSecondary),
              ),
              controller: _labelController,
            ),
          ),

          // ── 반복 요일 ──────────────────────────────────────────────
          _SectionCard(
            title: '반복',
            child: WeekdaySelector(
              repeatDays: _repeatDays,
              onChange: (days) => setState(() => _repeatDays = days),
            ),
          ),

          // ── 난이도 & 문제 수 ───────────────────────────────────────
          _SectionCard(
            title: '기상 미션',
            child: Column(
              children: [
                DifficultySelector(
                  value: _difficulty,
                  onChange: (d) => setState(() => _difficulty = d),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('연속 정답 수',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const Spacer(),
                    _CountStepper(
                      value: _problemCount,
                      min: 1,
                      max: 5,
                      onChange: (v) => setState(() => _problemCount = v),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 알람음 ────────────────────────────────────────────────
          _SectionCard(
            title: '알람음',
            child: Column(
              children: [
                // 기본 제공 음원 목록
                ...AlarmConstants.defaultSounds.map((s) => RadioListTile<String>(
                      title: Text(
                        s.replaceAll('.mp3', '').replaceAll('_', ' '),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      value: s,
                      groupValue: _soundAsset,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _soundAsset = v!),
                      contentPadding: EdgeInsets.zero,
                    )),
                // 커스텀 음원 선택
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_open,
                      color: AppColors.textSecondary),
                  title: const Text('기기에서 선택',
                      style: TextStyle(color: AppColors.textSecondary)),
                  onTap: () async {
                    final path = await SoundPickerSheet.pick(context);
                    if (path != null) setState(() => _soundAsset = path);
                  },
                ),
                // 볼륨
                Row(
                  children: [
                    const Icon(Icons.volume_down,
                        size: 18, color: AppColors.textSecondary),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _volume = v),
                      ),
                    ),
                    const Icon(Icons.volume_up,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
                // 페이드인
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('볼륨 서서히 증가 (30초)',
                      style: TextStyle(color: AppColors.textPrimary)),
                  value: _fadeIn,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _fadeIn = v),
                ),
              ],
            ),
          ),

          // ── 진동 ──────────────────────────────────────────────────
          _SectionCard(
            title: '진동',
            child: Column(
              children: VibrationPattern.values.map((p) {
                final label = switch (p) {
                  VibrationPattern.off => '진동 없음',
                  VibrationPattern.shortPulse => '짧게',
                  VibrationPattern.longPulse => '길게',
                  VibrationPattern.strong => '강하게',
                };
                return RadioListTile<VibrationPattern>(
                  title: Text(label,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  value: p,
                  groupValue: _vibration,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _vibration = v!),
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 공용 섹션 카드 ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({this.title, required this.child});
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}

// ─── 카운트 스테퍼 (1~5) ───────────────────────────────────────────────────

class _CountStepper extends StatelessWidget {
  const _CountStepper(
      {required this.value,
      required this.min,
      required this.max,
      required this.onChange});
  final int value, min, max;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline,
              color: AppColors.textSecondary),
          onPressed:
              value > min ? () => onChange(value - 1) : null,
        ),
        Text('$value문제',
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline,
              color: AppColors.primary),
          onPressed:
              value < max ? () => onChange(value + 1) : null,
        ),
      ],
    );
  }
}
