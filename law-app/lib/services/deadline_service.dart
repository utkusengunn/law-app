import 'package:hive/hive.dart';

import '../models/deadline.dart';
import '../utils/id_generator.dart';
import 'box_names.dart';

/// Süre (yasal mühlet) kayıtları için CRUD işlemleri.
class DeadlineService {
  Box<Deadline> get _box => Hive.box<Deadline>(BoxNames.deadlines);

  List<Deadline> getAll() => _box.values.toList();

  List<Deadline> getByCase(String caseId) =>
      _box.values.where((d) => d.caseId == caseId).toList();

  List<Deadline> getPending() =>
      _box.values.where((d) => d.status == DeadlineStatus.pending).toList();

  Deadline? getById(String id) {
    try {
      return _box.values.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Deadline> add(Deadline deadline) async {
    await _box.put(deadline.id, deadline);
    return deadline;
  }

  Future<Deadline> createAndAdd({
    required String title,
    required String caseId,
    required DateTime dueDate,
    String? description,
    List<int>? reminderOffsetsDays,
  }) async {
    final now = DateTime.now();
    final deadline = Deadline(
      id: IdGenerator.newId(),
      title: title,
      caseId: caseId,
      dueDate: dueDate,
      description: description,
      status: DeadlineStatus.pending,
      reminderOffsetsDays: reminderOffsetsDays,
      createdAt: now,
      updatedAt: now,
    );
    return add(deadline);
  }

  Future<void> update(Deadline deadline) async {
    deadline.updatedAt = DateTime.now();
    await deadline.save();
  }

  Future<void> setStatus(Deadline deadline, DeadlineStatus status) async {
    deadline.status = status;
    deadline.updatedAt = DateTime.now();
    await deadline.save();
  }
}
