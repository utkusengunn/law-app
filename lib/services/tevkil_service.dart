import 'package:hive/hive.dart';

import '../models/tevkil_isi.dart';
import '../utils/id_generator.dart';
import 'box_names.dart';

/// Tevkil işi kayıtları için CRUD işlemleri. Diğer servislerle aynı desen
/// (bkz. hearing_service.dart, meeting_service.dart).
class TevkilService {
  Box<TevkilIsi> get _box => Hive.box<TevkilIsi>(BoxNames.tevkilIsleri);

  List<TevkilIsi> getAll() => _box.values.toList();

  TevkilIsi? getById(String id) {
    try {
      return _box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<TevkilIsi> add(TevkilIsi tevkil) async {
    await _box.put(tevkil.id, tevkil);
    return tevkil;
  }

  Future<TevkilIsi> createAndAdd({
    required TevkilAltTuru altTur,
    required DateTime tarih,
    bool tumGun = false,
    required String baslik,
    required String tevkilEdenAd,
    String? tevkilEdenIletisim,
    String? caseId,
    String? clientId,
    String? note,
  }) async {
    final now = DateTime.now();
    final tevkil = TevkilIsi(
      id: IdGenerator.newId(),
      altTur: altTur,
      tarih: tarih,
      tumGun: tumGun,
      baslik: baslik,
      tevkilEdenAd: tevkilEdenAd,
      tevkilEdenIletisim: tevkilEdenIletisim,
      caseId: caseId,
      clientId: clientId,
      note: note,
      durum: TevkilDurum.pending,
      createdAt: now,
      updatedAt: now,
    );
    return add(tevkil);
  }

  Future<void> update(TevkilIsi tevkil) async {
    tevkil.updatedAt = DateTime.now();
    await tevkil.save();
  }

  Future<void> setDurum(TevkilIsi tevkil, TevkilDurum durum) async {
    tevkil.durum = durum;
    tevkil.updatedAt = DateTime.now();
    await tevkil.save();
  }
}
