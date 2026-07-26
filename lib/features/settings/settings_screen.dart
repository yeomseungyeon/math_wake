import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/alarm_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/alarm_model.dart';
import '../../providers/settings_provider.dart';
import '../alarm_edit/widgets/difficulty_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('설정',
            style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 기본 난이도 ─────────────────────────────────────────────
          _Section(
            title: '기본 난이도',
            child: DifficultySelector(
              value: settings.defaultDifficulty,
              onChange: (d) => notifier
                  .update(settings.copyWith(defaultDifficulty: d)),
            ),
          ),

          // ── 기본 문제 수 ────────────────────────────────────────────
          _Section(
            title: '기본 연속 정답 수',
            child: Row(
              children: [
                const Spacer(),
                ...List.generate(5, (i) {
                  final count = i + 1;
                  final selected = settings.defaultProblemCount == count;
                  return GestureDetector(
                    onTap: () => notifier.update(
                        settings.copyWith(defaultProblemCount: count)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? AppColors.primary
                            : AppColors.surface,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? Colors.black
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
              ],
            ),
          ),

          // ── 기본 알람음 ─────────────────────────────────────────────
          _Section(
            title: '기본 알람음',
            child: Column(
              children: AlarmConstants.defaultSounds.map((s) {
                final selected = settings.defaultSound == s;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: Text(
                    s.replaceAll('.mp3', '').replaceAll('_', ' '),
                    style: TextStyle(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  onTap: () =>
                      notifier.update(settings.copyWith(defaultSound: s)),
                );
              }).toList(),
            ),
          ),

          // ── 기본 볼륨 ───────────────────────────────────────────────
          _Section(
            title: '기본 볼륨',
            child: Row(
              children: [
                const Icon(Icons.volume_down,
                    color: AppColors.textSecondary),
                Expanded(
                  child: Slider(
                    value: settings.defaultVolume,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    activeColor: AppColors.primary,
                    onChanged: (v) => notifier
                        .update(settings.copyWith(defaultVolume: v)),
                  ),
                ),
                const Icon(Icons.volume_up, color: AppColors.textSecondary),
              ],
            ),
          ),

          // ── 페이드인 ────────────────────────────────────────────────
          _Section(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('볼륨 서서히 증가 (기본값)',
                  style: TextStyle(color: AppColors.textPrimary)),
              value: settings.defaultFadeIn,
              activeColor: AppColors.primary,
              onChanged: (v) =>
                  notifier.update(settings.copyWith(defaultFadeIn: v)),
            ),
          ),

          // ── 기본 진동 ───────────────────────────────────────────────
          _Section(
            title: '기본 진동',
            child: Column(
              children: VibrationPattern.values.map((p) {
                final label = switch (p) {
                  VibrationPattern.off => '진동 없음',
                  VibrationPattern.shortPulse => '짧게',
                  VibrationPattern.longPulse => '길게',
                  VibrationPattern.strong => '강하게',
                };
                return RadioListTile<VibrationPattern>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(label,
                      style:
                          const TextStyle(color: AppColors.textPrimary)),
                  value: p,
                  groupValue: settings.defaultVibration,
                  activeColor: AppColors.primary,
                  onChanged: (v) => notifier
                      .update(settings.copyWith(defaultVibration: v)),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'MathWake v1.0.0',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({this.title, required this.child});
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
