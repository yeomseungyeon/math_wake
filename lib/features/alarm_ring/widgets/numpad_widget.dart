import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// 숫자 키패드 위젯
/// onSubmit: 입력 완료(=) 버튼 눌렸을 때 호출
/// onChanged: 현재 입력된 문자열 변경될 때 호출
class NumpadWidget extends StatelessWidget {
  const NumpadWidget({
    super.key,
    required this.input,
    required this.onDigit,
    required this.onDelete,
    required this.onSubmit,
  });

  final String input;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 입력 표시창
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                input.isEmpty ? '_' : input,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
        // 숫자 버튼 그리드
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: [
            for (final digit in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
              _NumBtn(label: digit, onTap: () => onDigit(digit)),
            _NumBtn(
              label: '⌫',
              onTap: onDelete,
              color: AppColors.surface,
            ),
            _NumBtn(label: '0', onTap: () => onDigit('0')),
            _NumBtn(
              label: '✓',
              onTap: onSubmit,
              color: AppColors.primary,
              textColor: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ],
    );
  }
}

class _NumBtn extends StatelessWidget {
  const _NumBtn({
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
    this.fontWeight,
  });

  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: fontWeight ?? FontWeight.normal,
              color: textColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
