import 'package:hive/hive.dart';

import '../models/payment.dart';
import '../utils/id_generator.dart';
import 'box_names.dart';

/// Ödeme kayıtları için CRUD ve tahsilat işlemleri.
///
/// Veri bütünlüğü kuralları (md.5) burada zorlanır: tahsil edilen tutar
/// toplamı geçemez, taksit tutarları toplamı toplam ödeme tutarını aşamaz.
class PaymentValidationError implements Exception {
  PaymentValidationError(this.message);
  final String message;
  @override
  String toString() => message;
}

class PaymentService {
  Box<Payment> get _box => Hive.box<Payment>(BoxNames.payments);

  List<Payment> getAll() => _box.values.toList();

  List<Payment> getByClient(String clientId) =>
      _box.values.where((p) => p.clientId == clientId).toList();

  List<Payment> getByCase(String caseId) =>
      _box.values.where((p) => p.caseId == caseId).toList();

  Payment? getById(String id) {
    try {
      return _box.values.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Payment> add(Payment payment) async {
    await _box.put(payment.id, payment);
    return payment;
  }

  Future<Payment> createAndAdd({
    required String clientId,
    String? caseId,
    required String paymentType,
    required double amount,
    String currency = 'TRY',
    DateTime? dueDate,
    String? note,
    double collectedAmount = 0,
  }) async {
    if (collectedAmount > amount) {
      throw PaymentValidationError('Tahsil edilen tutar toplam tutarı geçemez.');
    }
    final now = DateTime.now();
    final payment = Payment(
      id: IdGenerator.newId(),
      clientId: clientId,
      caseId: caseId,
      paymentType: paymentType,
      amount: amount,
      currency: currency,
      dueDate: dueDate,
      status: PaymentStatus.waiting,
      note: note,
      createdAt: now,
      updatedAt: now,
      collectedAmount: collectedAmount,
      paidDate: collectedAmount >= amount ? now : null,
    );
    return add(payment);
  }

  Future<void> update(Payment payment) async {
    payment.updatedAt = DateTime.now();
    await payment.save();
  }

  Future<void> setStatus(Payment payment, PaymentStatus status) async {
    payment.status = status;
    payment.updatedAt = DateTime.now();
    await payment.save();
  }

  /// Plansız (basit) bir ödemeye tahsilat kaydeder; toplamı aşan bir
  /// tahsilat girilirse reddedilir.
  Future<void> recordCollection(
    Payment payment, {
    required double amount,
    DateTime? date,
  }) async {
    if (payment.hasPlan) {
      throw PaymentValidationError(
          'Bu ödemenin bir taksit planı var, tahsilat taksit üzerinden girilmeli.');
    }
    if (amount <= 0) {
      throw PaymentValidationError('Tahsilat tutarı sıfırdan büyük olmalıdır.');
    }
    final newCollected = payment.collectedAmount + amount;
    if (newCollected > payment.amount + 0.001) {
      throw PaymentValidationError('Tahsil edilen tutar toplam tutarı geçemez.');
    }
    payment.collectedAmount = newCollected;
    payment.paidDate = date ?? DateTime.now();
    // status alanına dokunmuyoruz; görüntülenen durum her zaman
    // Payment.effectiveStatus üzerinden tutar/vadeden hesaplanır.
    payment.updatedAt = DateTime.now();
    await payment.save();
  }

  /// Bir ödemeyi taksit planına geçirir. Taksitlerin toplamı ödemenin toplam
  /// tutarını aşarsa reddedilir. Yeni plan, önceki planı tamamen değiştirir.
  Future<void> setInstallments(
    Payment payment,
    List<PaymentInstallment> plan,
  ) async {
    final sum = plan.fold(0.0, (s, i) => s + i.amount);
    if (sum > payment.amount + 0.001) {
      throw PaymentValidationError(
          'Taksitlerin toplamı toplam ödeme tutarını aşamaz.');
    }
    payment.installments = plan;
    payment.collectedAmount = 0; // artık kaynak taksitler
    payment.updatedAt = DateTime.now();
    await payment.save();
  }

  /// Belirli bir takside tahsilat kaydeder; taksit tutarını aşan bir
  /// tahsilat girilirse reddedilir.
  Future<void> recordInstallmentPayment(
    Payment payment,
    String installmentId, {
    required double amount,
    DateTime? date,
  }) async {
    if (amount <= 0) {
      throw PaymentValidationError('Tahsilat tutarı sıfırdan büyük olmalıdır.');
    }
    final index = payment.installments.indexWhere((i) => i.id == installmentId);
    if (index == -1) {
      throw PaymentValidationError('Taksit bulunamadı.');
    }
    final installment = payment.installments[index];
    final newPaid = installment.paidAmount + amount;
    if (newPaid > installment.amount + 0.001) {
      throw PaymentValidationError('Tahsil edilen tutar taksit tutarını geçemez.');
    }
    installment.paidAmount = newPaid;
    installment.paidDate = date ?? DateTime.now();
    payment.installments[index] = installment;
    payment.updatedAt = DateTime.now();
    await payment.save();
  }
}
