import 'package:hive/hive.dart';

/// Duruşma durumu.
enum HearingStatus { scheduled, completed, cancelled, postponed }

/// Bir dosyaya bağlı duruşma kaydı.
class Hearing extends HiveObject {
  Hearing({
    required this.id,
    required this.caseId,
    required this.court,
    required this.caseNumber,
    required this.date,
    required this.hearingType,
    this.room,
    this.note,
    this.status = HearingStatus.scheduled,
  });

  String id;
  String caseId;
  String court;
  String caseNumber;
  DateTime date;
  String hearingType;
  String? room;
  String? note;
  HearingStatus status;

  Hearing copyWith({
    String? court,
    String? caseNumber,
    DateTime? date,
    String? hearingType,
    String? room,
    String? note,
    HearingStatus? status,
  }) {
    return Hearing(
      id: id,
      caseId: caseId,
      court: court ?? this.court,
      caseNumber: caseNumber ?? this.caseNumber,
      date: date ?? this.date,
      hearingType: hearingType ?? this.hearingType,
      room: room ?? this.room,
      note: note ?? this.note,
      status: status ?? this.status,
    );
  }
}

class HearingAdapter extends TypeAdapter<Hearing> {
  @override
  final int typeId = 3;

  @override
  Hearing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Hearing(
      id: fields[0] as String,
      caseId: fields[1] as String,
      court: fields[2] as String,
      caseNumber: fields[3] as String,
      date: fields[4] as DateTime,
      hearingType: fields[5] as String,
      room: fields[6] as String?,
      note: fields[7] as String?,
      status: HearingStatus.values[fields[8] as int],
    );
  }

  @override
  void write(BinaryWriter writer, Hearing obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.caseId)
      ..writeByte(2)
      ..write(obj.court)
      ..writeByte(3)
      ..write(obj.caseNumber)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.hearingType)
      ..writeByte(6)
      ..write(obj.room)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.status.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HearingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
