import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/alarm_model.dart';
import '../../../providers/alarm_list_provider.dart';

class AlarmCard extends ConsumerWidget {
  const AlarmCard({super.key, required this.alarm, required this.onTap});

  final AlarmModel alarm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: alarm.isEnabled
              ? AppColors.cardBackground
              : AppColors.cardBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alarm.isEnabled
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            // 시간 표시
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm.timeString,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: alarm.isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alarm.label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _WeekdayBadges(repeatDays: alarm.repeatDays),
                      const SizedBox(width: 8),
                      _DifficultyChip(difficulty: alarm.difficulty),
                    ],
                  ),
                ],
              ),
            ),
            // 토글 스위치
            Switch(
              value: alarm.isEnabled,
              onChanged: (_) =>
                  ref.read(alarmListProvider.notifier).toggle(alarm.id),
              activeColor: AppColors.primary,
              inactiveThumbColor: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayBadges extends StatelessWidget {
  const _WeekdayBadges({required this.repeatDays});
  final List<bool> repeatDays;

  @override
  Widget build(BuildContext context) {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    return Row(
      children: List.generate(7, (i) {
        final active = repeatDays[i];
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Text(
            days[i],
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  active ? FontWeight.bold : FontWeight.normal,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        );
      }),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.difficulty});
  final AlarmDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final label = switch (difficulty) {
      AlarmDifficulty.easy => '쉬움',
      AlarmDifficulty.medium => '보통',
      AlarmDifficulty.hard => '어려움',
    };
    final color = switch (difficulty) {
      AlarmDifficulty.easy => Colors.green,
      AlarmDifficulty.medium => Colors.orange,
      AlarmDifficulty.hard => AppColors.accent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
