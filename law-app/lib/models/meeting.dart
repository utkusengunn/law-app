import 'package:hive/hive.dart';

/// Görüşme türü.
enum MeetingType { phone, inPerson, online, other }

/// Görüşme durumu.
enum MeetingStatus { scheduled, completed, cancelled }

/// Bir müvekkille (opsiyonel olarak bir dosyaya bağlı) görüşme kaydı.
class Meeting extends HiveObject {
  Meeting({
    required this.id,
    required this.clientId,
    this.caseId,
    required this.meetingType,
    required this.date,
    this.note,
    this.status = MeetingStatus.scheduled,
  });

  String id;
  String clientId;
  String? caseId;
  MeetingType meetingType;
  DateTime date;
  String? note;
  MeetingStatus status;

  Meeting copyWith({
    String? clientId,
    String? caseId,
    bool clearCaseId = false,
    MeetingType? meetingType,
    DateTime? date,
    String? note,
    MeetingStatus? status,
  }) {
    return Meeting(
      id: id,
      clientId: clientId ?? this.clientId,
      caseId: clearCaseId ? null : (caseId ?? this.caseId),
      meetingType: meetingType ?? this.meetingType,
      date: date ?? this.date,
      note: note ?? this.note,
      status: status ?? this.status,
    );
  }
}

class MeetingAdapter extends TypeAdapter<Meeting> {
  @override
  final int typeId = 4;

  @override
  Meeting read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Meeting(
      id: fields[0] as String,
      clientId: fields[1] as String,
      caseId: fields[2] as String?,
      meetingType: MeetingType.values[fields[3] as int],
      date: fields[4] as DateTime,
      note: fields[5] as String?,
      status: MeetingStatus.values[fields[6] as int],
    );
  }

  @override
  void write(BinaryWriter writer, Meeting obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientId)
      ..writeByte(2)
      ..write(obj.caseId)
      ..writeByte(3)
      ..write(obj.meetingType.index)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.status.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeetingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
