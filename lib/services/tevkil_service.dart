import 'package:hive/hive.dart';

import '../models/payment.dart';
import '../models/tevkil_isi.dart';
import '../utils/id_generator.dart';
import 'box_names.dart';
import 'payment_service.dart';

/// Tevkil işi kayıtları için CRUD işlemleri. Diğer servislerle aynı desen
/// (bkz. hearing_service.dart, meeting_service.dart).
class TevkilService {
  Box<TevkilIsi> get _box => Hive.box<TevkilIsi>(BoxNames.tevkilIsleri);
  final _paymentService = PaymentService();

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

  /// Durumu değiştirir. [TevkilDurum.cancelled]'a geçilirse - kullanıcı
  /// talebi (2026-09-08, backlog D015.4): "iptal edilen tevkillerde ödeme
  /// alınmaz, direkt ödeme tarafı da iptal olur" - bu tevkile bağlı tüm
  /// ödemeler de otomatik olarak [PaymentStatus.cancelled] durumuna
  /// geçirilir. Diğer yönde (iptalden geri alma) otomatik bir işlem
  /// YAPILMIYOR - kullanıcı ödemeyi tekrar isterse elle Ödemeler ekranından
  /// durumunu değiştirebilir (bilinçli tercih: otomatik "iptali geri al" bir
  /// ödemeyi yanlışlıkla tekrar aktif hale getirebilir).
  Future<void> setDurum(TevkilIsi tevkil, TevkilDurum durum) async {
    tevkil.durum = durum;
    tevkil.updatedAt = DateTime.now();
    await tevkil.save();
    if (durum == TevkilDurum.cancelled) {
      final linkedPayments = _paymentService.getByTevkilIsi(tevkil.id);
      for (final payment in linkedPayments) {
        await _paymentService.setStatus(payment, PaymentStatus.cancelled);
      }
    }
  }
}
