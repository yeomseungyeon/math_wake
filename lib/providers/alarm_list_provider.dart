import 'package:flutter/foundation.dart';
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
    _refresh(); // Hive 저장 즉시 UI 반영 — 스케줄러 실패와 무관하게 목록에 표시
    try {
      await _scheduler.schedule(alarm);
    } catch (e) {
      debugPrint('[AlarmList] schedule error: $e');
    }
  }

  Future<void> update(AlarmModel alarm) async {
    await _repo.save(alarm);
    _refresh();
    try {
      await _scheduler.schedule(alarm);
    } catch (e) {
      debugPrint('[AlarmList] schedule error: $e');
    }
  }

  Future<void> delete(String id) async {
    await _repo.delete(id); // DB 삭제를 먼저 수행해 재등장 방지
    _refresh();
    try {
      await _scheduler.cancel(id); // 스케줄러 취소는 best-effort
    } catch (e) {
      debugPrint('[AlarmList] cancel error: $e');
    }
  }

  Future<void> toggle(String id) async {
    await _repo.toggle(id);
    final alarm = _repo.getById(id);
    _refresh();
    if (alarm == null) return;
    try {
      if (alarm.isEnabled) {
        await _scheduler.schedule(alarm);
      } else {
        await _scheduler.cancel(id);
      }
    } catch (e) {
      debugPrint('[AlarmList] toggle schedule error: $e');
    }
  }
}

final alarmListProvider =
    NotifierProvider<AlarmListNotifier, List<AlarmModel>>(
  AlarmListNotifier.new,
);
