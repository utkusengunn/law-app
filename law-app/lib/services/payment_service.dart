import 'package:hive/hive.dart';

import '../models/payment.dart';
import '../utils/id_generator.dart';
import 'box_names.dart';

/// Ödeme kayıtları için CRUD işlemleri.
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
  }) async {
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
    );
    return add(payment);
  }

  Future<void> update(Payment payment) async {
    payment.updatedAt = DateTime.now();
    await payment.save();
  }

  Future<void> markPaid(Payment payment) async {
    payment.status = PaymentStatus.paid;
    payment.paidDate = DateTime.now();
    payment.updatedAt = DateTime.now();
    await payment.save();
  }

  Future<void> setStatus(Payment payment, PaymentStatus status) async {
    payment.status = status;
    payment.updatedAt = DateTime.now();
    await payment.save();
  }
}
