import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/permission_helper.dart';
import '../../providers/alarm_list_provider.dart';
import '../alarm_edit/alarm_edit_screen.dart';
import 'widgets/alarm_card.dart';

class AlarmListScreen extends ConsumerStatefulWidget {
  const AlarmListScreen({super.key});

  @override
  ConsumerState<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends ConsumerState<AlarmListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PermissionHelper.requestAll(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final alarms = ref.watch(alarmListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'MathWake',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: alarms.isEmpty
          ? const _EmptyView()
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: alarms.length,
              itemBuilder: (_, i) => Dismissible(
                key: ValueKey(alarms[i].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: AppColors.accent.withOpacity(0.8),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.white, size: 28),
                ),
                confirmDismiss: (_) => showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('알람 삭제',
                        style: TextStyle(color: AppColors.textPrimary)),
                    content: Text(
                      '"${alarms[i].label}" 알람을 삭제할까요?',
                      style:
                          const TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('삭제',
                            style: TextStyle(color: AppColors.accent)),
                      ),
                    ],
                  ),
                ),
                onDismissed: (_) => ref
                    .read(alarmListProvider.notifier)
                    .delete(alarms[i].id),
                child: AlarmCard(
                  alarm: alarms[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AlarmEditScreen(alarm: alarms[i]),
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AlarmEditScreen()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('알람 추가',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alarm_off, size: 72, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            '등록된 알람이 없습니다',
            style: TextStyle(
                fontSize: 18, color: AppColors.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            '+ 버튼을 눌러 첫 번째 알람을 만들어보세요',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
