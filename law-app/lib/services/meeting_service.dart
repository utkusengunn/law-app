import 'package:hive/hive.dart';

import '../models/meeting.dart';
import '../utils/id_generator.dart';
import 'box_names.dart';

/// Görüşme kayıtları için CRUD işlemleri.
class MeetingService {
  Box<Meeting> get _box => Hive.box<Meeting>(BoxNames.meetings);

  List<Meeting> getAll() => _box.values.toList();

  List<Meeting> getByClient(String clientId) =>
      _box.values.where((m) => m.clientId == clientId).toList();

  List<Meeting> getByCase(String caseId) =>
      _box.values.where((m) => m.caseId == caseId).toList();

  Meeting? getById(String id) {
    try {
      return _box.values.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Meeting> add(Meeting meeting) async {
    await _box.put(meeting.id, meeting);
    return meeting;
  }

  Future<Meeting> createAndAdd({
    required String clientId,
    String? caseId,
    required MeetingType meetingType,
    required DateTime date,
    String? note,
  }) async {
    final meeting = Meeting(
      id: IdGenerator.newId(),
      clientId: clientId,
      caseId: caseId,
      meetingType: meetingType,
      date: date,
      note: note,
      status: MeetingStatus.scheduled,
    );
    return add(meeting);
  }

  Future<void> update(Meeting meeting) async {
    await meeting.save();
  }

  Future<void> setStatus(Meeting meeting, MeetingStatus status) async {
    meeting.status = status;
    await meeting.save();
  }
}
