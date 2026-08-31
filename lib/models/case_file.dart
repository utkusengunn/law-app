import 'package:hive/hive.dart';

/// Dosyanın (davanın) durumu.
enum CaseStatus { active, pending, closed }

/// Dava/dosya kaydı. Dart'ın "Case" anahtar kelimesiyle karışmaması için
/// sınıf adı "CaseFile" olarak seçildi.
class CaseFile extends HiveObject {
  CaseFile({
    required this.id,
    required this.name,
    required this.caseType,
    required this.court,
    required this.caseNumber,
    required this.clientId,
    this.opposingParty,
    required this.openDate,
    this.closeDate,
    this.status = CaseStatus.active,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  String id;
  String name;
  String caseType;
  String court;
  String caseNumber;
  String clientId;
  String? opposingParty;
  DateTime openDate;
  DateTime? closeDate;
  CaseStatus status;
  String? note;
  DateTime createdAt;
  DateTime updatedAt;

  CaseFile copyWith({
    String? name,
    String? caseType,
    String? court,
    String? caseNumber,
    String? clientId,
    String? opposingParty,
    DateTime? openDate,
    DateTime? closeDate,
    bool clearCloseDate = false,
    CaseStatus? status,
    String? note,
    DateTime? updatedAt,
  }) {
    return CaseFile(
      id: id,
      name: name ?? this.name,
      caseType: caseType ?? this.caseType,
      court: court ?? this.court,
      caseNumber: caseNumber ?? this.caseNumber,
      clientId: clientId ?? this.clientId,
      opposingParty: opposingParty ?? this.opposingParty,
      openDate: openDate ?? this.openDate,
      closeDate: clearCloseDate ? null : (closeDate ?? this.closeDate),
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CaseFileAdapter extends TypeAdapter<CaseFile> {
  @override
  final int typeId = 1;

  @override
  CaseFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CaseFile(
      id: fields[0] as String,
      name: fields[1] as String,
      caseType: fields[2] as String,
      court: fields[3] as String,
      caseNumber: fields[4] as String,
      clientId: fields[5] as String,
      opposingParty: fields[6] as String?,
      openDate: fields[7] as DateTime,
      closeDate: fields[8] as DateTime?,
      status: CaseStatus.values[fields[9] as int],
      note: fields[10] as String?,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CaseFile obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.caseType)
      ..writeByte(3)
      ..write(obj.court)
      ..writeByte(4)
      ..write(obj.caseNumber)
      ..writeByte(5)
      ..write(obj.clientId)
      ..writeByte(6)
      ..write(obj.opposingParty)
      ..writeByte(7)
      ..write(obj.openDate)
      ..writeByte(8)
      ..write(obj.closeDate)
      ..writeByte(9)
      ..write(obj.status.index)
      ..writeByte(10)
      ..write(obj.note)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
