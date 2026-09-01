import 'package:hive/hive.dart';

import '../models/hearing.dart';
import '../utils/id_generator.dart';
import 'box_names.dart';

/// Duruşma kayıtları için CRUD işlemleri.
class HearingService {
  Box<Hearing> get _box => Hive.box<Hearing>(BoxNames.hearings);

  List<Hearing> getAll() => _box.values.toList();

  List<Hearing> getByCase(String caseId) =>
      _box.values.where((h) => h.caseId == caseId).toList();

  Hearing? getById(String id) {
    try {
      return _box.values.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Hearing> add(Hearing hearing) async {
    await _box.put(hearing.id, hearing);
    return hearing;
  }

  Future<Hearing> createAndAdd({
    required String caseId,
    required String court,
    required String caseNumber,
    required DateTime date,
    required String hearingType,
    String? room,
    String? note,
  }) async {
    final hearing = Hearing(
      id: IdGenerator.newId(),
      caseId: caseId,
      court: court,
      caseNumber: caseNumber,
      date: date,
      hearingType: hearingType,
      room: room,
      note: note,
      status: HearingStatus.scheduled,
    );
    return add(hearing);
  }

  Future<void> update(Hearing hearing) async {
    await hearing.save();
  }

  Future<void> setStatus(Hearing hearing, HearingStatus status) async {
    hearing.status = status;
    await hearing.save();
  }
}
