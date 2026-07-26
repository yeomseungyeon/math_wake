import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/alarm_model.dart';

class DifficultySelector extends StatelessWidget {
  const DifficultySelector(
      {super.key, required this.value, required this.onChange});

  final AlarmDifficulty value;
  final ValueChanged<AlarmDifficulty> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AlarmDifficulty.values.map((d) {
        final label = switch (d) {
          AlarmDifficulty.easy => '쉬움',
          AlarmDifficulty.medium => '보통',
          AlarmDifficulty.hard => '어려움',
        };
        final color = switch (d) {
          AlarmDifficulty.easy => Colors.green,
          AlarmDifficulty.medium => Colors.orange,
          AlarmDifficulty.hard => AppColors.accent,
        };
        final selected = value == d;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChange(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.2) : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? color : AppColors.divider,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? color : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    switch (d) {
                      AlarmDifficulty.easy => '1자리 ±',
                      AlarmDifficulty.medium => '2자리 ±×',
                      AlarmDifficulty.hard => '혼합 연산',
                    },
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
