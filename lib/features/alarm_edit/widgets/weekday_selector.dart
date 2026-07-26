import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector(
      {super.key, required this.repeatDays, required this.onChange});

  final List<bool> repeatDays;
  final ValueChanged<List<bool>> onChange;

  @override
  Widget build(BuildContext context) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      children: [
        // 프리셋 버튼
        Row(
          children: [
            _PresetBtn(
                label: '매일',
                onTap: () => onChange(List.filled(7, true))),
            const SizedBox(width: 8),
            _PresetBtn(
                label: '평일',
                onTap: () => onChange(
                    [true, true, true, true, true, false, false])),
            const SizedBox(width: 8),
            _PresetBtn(
                label: '주말',
                onTap: () => onChange(
                    [false, false, false, false, false, true, true])),
            const SizedBox(width: 8),
            _PresetBtn(
                label: '해제',
                onTap: () => onChange(List.filled(7, false))),
          ],
        ),
        const SizedBox(height: 12),
        // 요일 개별 선택
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final active = repeatDays[i];
            return GestureDetector(
              onTap: () {
                final updated = List<bool>.from(repeatDays);
                updated[i] = !updated[i];
                onChange(updated);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? AppColors.primary
                      : AppColors.surface,
                  border: Border.all(
                    color: active
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
                child: Center(
                  child: Text(
                    days[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: active
                          ? Colors.black
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PresetBtn extends StatelessWidget {
  const _PresetBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ),
    );
  }
}
