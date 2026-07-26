import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm_model.dart';
import '../../core/constants/alarm_constants.dart';

class AlarmRepository {
  static final AlarmRepository _instance = AlarmRepository._();
  factory AlarmRepository() => _instance;
  AlarmRepository._();

  Box<AlarmModel> get _box => Hive.box<AlarmModel>(AlarmConstants.alarmBoxName);

  List<AlarmModel> getAll() =>
      _box.values.toList()..sort((a, b) {
        // 시:분 오름차순 정렬
        final aMin = a.hour * 60 + a.minute;
        final bMin = b.hour * 60 + b.minute;
        return aMin.compareTo(bMin);
      });

  AlarmModel? getById(String id) =>
      _box.values.cast<AlarmModel?>().firstWhere(
        (a) => a?.id == id,
        orElse: () => null,
      );

  Future<void> save(AlarmModel alarm) async {
    await _box.put(alarm.id, alarm);
  }

  Future<AlarmModel> create({
    required int hour,
    required int minute,
  }) async {
    final alarm = AlarmModel(
      id: const Uuid().v4(),
      hour: hour,
      minute: minute,
    );
    await save(alarm);
    return alarm;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> toggle(String id) async {
    final alarm = getById(id);
    if (alarm == null) return;
    alarm.isEnabled = !alarm.isEnabled;
    await alarm.save();
  }
}
