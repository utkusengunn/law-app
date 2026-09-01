import 'package:hive/hive.dart';

import '../models/legal_task.dart';
import '../utils/id_generator.dart';
import 'box_names.dart';

/// İş (yapılacak) kayıtları için CRUD işlemleri.
class TaskService {
  Box<LegalTask> get _box => Hive.box<LegalTask>(BoxNames.tasks);

  List<LegalTask> getAll() => _box.values.toList();

  List<LegalTask> getByCase(String caseId) =>
      _box.values.where((t) => t.caseId == caseId).toList();

  List<LegalTask> getByClient(String clientId) =>
      _box.values.where((t) => t.clientId == clientId).toList();

  List<LegalTask> getByStatus(TaskStatus status) =>
      _box.values.where((t) => t.status == status).toList();

  LegalTask? getById(String id) {
    try {
      return _box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<LegalTask> add(LegalTask task) async {
    await _box.put(task.id, task);
    return task;
  }

  Future<LegalTask> createAndAdd({
    required String title,
    String? description,
    String? caseId,
    String? clientId,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.normal,
  }) async {
    final task = LegalTask(
      id: IdGenerator.newId(),
      title: title,
      description: description,
      caseId: caseId,
      clientId: clientId,
      dueDate: dueDate,
      priority: priority,
      status: TaskStatus.waiting,
      createdAt: DateTime.now(),
    );
    return add(task);
  }

  Future<void> update(LegalTask task) async {
    await task.save();
  }

  Future<void> setStatus(LegalTask task, TaskStatus status) async {
    task.status = status;
    task.completedAt = status == TaskStatus.done ? DateTime.now() : null;
    await task.save();
  }
}
