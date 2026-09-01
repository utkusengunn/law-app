import 'package:hive/hive.dart';

/// Ödeme durumu.
enum PaymentStatus { waiting, partial, paid, overdue, cancelled }

/// Bir müvekkile (opsiyonel olarak bir dosyaya bağlı) ödeme/tahsilat kaydı.
class Payment extends HiveObject {
  Payment({
    required this.id,
    required this.clientId,
    this.caseId,
    required this.paymentType,
    required this.amount,
    this.currency = 'TRY',
    this.dueDate,
    this.paidDate,
    this.status = PaymentStatus.waiting,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  String id;
  String clientId;
  String? caseId;
  String paymentType;
  double amount;
  String currency;
  DateTime? dueDate;
  DateTime? paidDate;
  PaymentStatus status;
  String? note;
  DateTime createdAt;
  DateTime updatedAt;

  Payment copyWith({
    String? paymentType,
    double? amount,
    String? currency,
    DateTime? dueDate,
    DateTime? paidDate,
    bool clearPaidDate = false,
    PaymentStatus? status,
    String? note,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id,
      clientId: clientId,
      caseId: caseId,
      paymentType: paymentType ?? this.paymentType,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      dueDate: dueDate ?? this.dueDate,
      paidDate: clearPaidDate ? null : (paidDate ?? this.paidDate),
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 6;

  @override
  Payment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      id: fields[0] as String,
      clientId: fields[1] as String,
      caseId: fields[2] as String?,
      paymentType: fields[3] as String,
      amount: fields[4] as double,
      currency: fields[5] as String,
      dueDate: fields[6] as DateTime?,
      paidDate: fields[7] as DateTime?,
      status: PaymentStatus.values[fields[8] as int],
      note: fields[9] as String?,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientId)
      ..writeByte(2)
      ..write(obj.caseId)
      ..writeByte(3)
      ..write(obj.paymentType)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.dueDate)
      ..writeByte(7)
      ..write(obj.paidDate)
      ..writeByte(8)
      ..write(obj.status.index)
      ..writeByte(9)
      ..write(obj.note)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
