import 'package:hive/hive.dart';

import '../models/case_file.dart';
import '../utils/id_generator.dart';
import 'box_names.dart';

/// Dosya (dava) kayıtları için CRUD ve arama işlemleri.
class CaseService {
  Box<CaseFile> get _box => Hive.box<CaseFile>(BoxNames.cases);

  List<CaseFile> getAll() => _box.values.toList();

  List<CaseFile> getByClient(String clientId) =>
      _box.values.where((c) => c.clientId == clientId).toList();

  List<CaseFile> getOpen() =>
      _box.values.where((c) => c.status != CaseStatus.closed).toList();

  CaseFile? getById(String id) {
    try {
      return _box.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CaseFile> search(String query, {bool includeClosed = true}) {
    final source =
        includeClosed ? getAll() : getAll().where((c) => c.status != CaseStatus.closed).toList();
    if (query.trim().isEmpty) return source;
    final q = query.trim().toLowerCase();
    return source.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.caseNumber.toLowerCase().contains(q) ||
          c.court.toLowerCase().contains(q);
    }).toList();
  }

  Future<CaseFile> add(CaseFile caseFile) async {
    await _box.put(caseFile.id, caseFile);
    return caseFile;
  }

  Future<CaseFile> createAndAdd({
    required String name,
    required String caseType,
    required String court,
    required String caseNumber,
    required String clientId,
    String? opposingParty,
    required DateTime openDate,
    String? note,
  }) async {
    final now = DateTime.now();
    final caseFile = CaseFile(
      id: IdGenerator.newId(),
      name: name,
      caseType: caseType,
      court: court,
      caseNumber: caseNumber,
      clientId: clientId,
      opposingParty: opposingParty,
      openDate: openDate,
      status: CaseStatus.active,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    return add(caseFile);
  }

  Future<void> update(CaseFile caseFile) async {
    caseFile.updatedAt = DateTime.now();
    await caseFile.save();
  }

  /// Dosyayı kapatır (soft delete/status change). Bağlı kayıtlar korunur.
  Future<void> setStatus(CaseFile caseFile, CaseStatus status) async {
    caseFile.status = status;
    if (status == CaseStatus.closed) {
      caseFile.closeDate = DateTime.now();
    }
    caseFile.updatedAt = DateTime.now();
    await caseFile.save();
  }
}
