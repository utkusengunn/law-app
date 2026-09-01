import 'package:hive/hive.dart';

/// Ödeme durumu.
enum PaymentStatus { waiting, partial, paid, overdue, cancelled }

/// Bir taksit/ödeme planı satırı. Durumu ayrıca saklanmaz; tutar/ödenen
/// tutar/vade tarihinden HER ZAMAN hesaplanır (tutarsızlık riski olmasın diye).
class PaymentInstallment {
  PaymentInstallment({
    required this.id,
    required this.amount,
    required this.dueDate,
    this.paidAmount = 0,
    this.paidDate,
  });

  String id;
  double amount;
  DateTime dueDate;
  double paidAmount;
  DateTime? paidDate;

  double get remainingAmount => (amount - paidAmount).clamp(0, amount);

  bool get isOverdue =>
      paidAmount < amount && dueDate.isBefore(DateTime.now());

  /// Bu taksitin durumu; hiçbir zaman ayrıca saklanmaz, her okumada hesaplanır.
  PaymentStatus get status {
    if (paidAmount >= amount) return PaymentStatus.paid;
    if (isOverdue) return PaymentStatus.overdue;
    if (paidAmount > 0) return PaymentStatus.partial;
    return PaymentStatus.waiting;
  }

  PaymentInstallment copyWith({
    double? amount,
    DateTime? dueDate,
    double? paidAmount,
    DateTime? paidDate,
  }) {
    return PaymentInstallment(
      id: id,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidAmount: paidAmount ?? this.paidAmount,
      paidDate: paidDate ?? this.paidDate,
    );
  }
}

class PaymentInstallmentAdapter extends TypeAdapter<PaymentInstallment> {
  @override
  final int typeId = 7;

  @override
  PaymentInstallment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentInstallment(
      id: fields[0] as String,
      amount: fields[1] as double,
      dueDate: fields[2] as DateTime,
      paidAmount: (fields[3] as double?) ?? 0,
      paidDate: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentInstallment obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.dueDate)
      ..writeByte(3)
      ..write(obj.paidAmount)
      ..writeByte(4)
      ..write(obj.paidDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentInstallmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Bir müvekkile (opsiyonel olarak bir dosyaya bağlı) ödeme/tahsilat kaydı.
///
/// İki çalışma şekli vardır:
/// - Plansız (installments boş): [collectedAmount] üzerinden basit kısmi/tam
///   tahsilat takibi yapılır (eski v0.3 kayıtları bu şekilde okunur, hiçbir
///   veri kaybı olmaz).
/// - Planlı (installments dolu): toplam tutar taksitlere bölünmüştür, tahsilat
///   her taksit üzerinden ayrı ayrı takip edilir; [collectedAmount] bu modda
///   kullanılmaz.
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
    this.collectedAmount = 0,
    List<PaymentInstallment>? installments,
  }) : installments = installments ?? [];

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
  double collectedAmount;
  List<PaymentInstallment> installments;

  bool get hasPlan => installments.isNotEmpty;

  double get totalCollected => hasPlan
      ? installments.fold(0.0, (sum, i) => sum + i.paidAmount)
      : collectedAmount.clamp(0, amount);

  double get remainingAmount => (amount - totalCollected).clamp(0, amount);

  bool get isFullyPaid => totalCollected >= amount;

  /// Bu ödemenin en yakın/etkin vade tarihi: planlıysa ilk ödenmemiş
  /// taksidin vadesi, değilse ödemenin kendi vade tarihi.
  DateTime? get effectiveDueDate {
    if (hasPlan) {
      final unpaid = installments.where((i) => i.paidAmount < i.amount).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      if (unpaid.isNotEmpty) return unpaid.first.dueDate;
      return null;
    }
    return dueDate;
  }

  /// Gösterilecek gerçek durum. [status] alanı yalnızca "İptal" gibi manuel
  /// bir işaretleme için saklanır; aksi halde durum her zaman tutar ve vade
  /// tarihinden hesaplanır ki tutarsız/bayat bir durum hiç oluşmasın.
  PaymentStatus get effectiveStatus {
    if (status == PaymentStatus.cancelled) return PaymentStatus.cancelled;
    if (isFullyPaid) return PaymentStatus.paid;
    final due = effectiveDueDate;
    final isOverdue = due != null && due.isBefore(DateTime.now());
    if (isOverdue) return PaymentStatus.overdue;
    if (totalCollected > 0) return PaymentStatus.partial;
    return PaymentStatus.waiting;
  }

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
    double? collectedAmount,
    List<PaymentInstallment>? installments,
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
      collectedAmount: collectedAmount ?? this.collectedAmount,
      installments: installments ?? this.installments,
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
      // Eski (v0.3) kayıtlarda 12 ve 13 numaralı alanlar yok; bu durumda
      // Hive fields[12]/fields[13] null döner ve aşağıdaki varsayılanlar
      // devreye girer - mevcut veride hiçbir kayıp olmaz.
      collectedAmount: (fields[12] as double?) ?? 0,
      installments: (fields[13] as List?)?.cast<PaymentInstallment>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(14)
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
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.collectedAmount)
      ..writeByte(13)
      ..write(obj.installments);
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
