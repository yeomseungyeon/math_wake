import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/alarm_model.dart';
import '../data/repositories/alarm_repository.dart';
import '../services/alarm_scheduler.dart';

class AlarmListNotifier extends Notifier<List<AlarmModel>> {
  final _repo = AlarmRepository();
  final _scheduler = AlarmScheduler();

  @override
  List<AlarmModel> build() => _repo.getAll();

  void _refresh() => state = _repo.getAll();

  Future<void> add(AlarmModel alarm) async {
    await _repo.save(alarm);
    await _scheduler.schedule(alarm);
    _refresh();
  }

  Future<void> update(AlarmModel alarm) async {
    await _repo.save(alarm);
    // 기존 스케줄 취소 후 재등록
    await _scheduler.schedule(alarm);
    _refresh();
  }

  Future<void> delete(String id) async {
    await _scheduler.cancel(id);
    await _repo.delete(id);
    _refresh();
  }

  Future<void> toggle(String id) async {
    await _repo.toggle(id);
    final alarm = _repo.getById(id);
    if (alarm != null) {
      if (alarm.isEnabled) {
        await _scheduler.schedule(alarm);
      } else {
        await _scheduler.cancel(id);
      }
    }
    _refresh();
  }
}

final alarmListProvider =
    NotifierProvider<AlarmListNotifier, List<AlarmModel>>(
  AlarmListNotifier.new,
);
