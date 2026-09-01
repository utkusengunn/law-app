import 'package:hive/hive.dart';

/// Süre (yasal süre/mühlet) durumu.
enum DeadlineStatus { pending, completed, cancelled }

/// Bir dosyaya bağlı yasal süre kaydı. [reminderOffsetsDays], son tarihten
/// kaç gün önce hatırlatma yapılacağını belirtir (0 = son tarihin kendisi).
class Deadline extends HiveObject {
  Deadline({
    required this.id,
    required this.title,
    required this.caseId,
    required this.dueDate,
    this.description,
    this.status = DeadlineStatus.pending,
    List<int>? reminderOffsetsDays,
    required this.createdAt,
    required this.updatedAt,
  }) : reminderOffsetsDays = reminderOffsetsDays ?? const [15, 7, 3, 1, 0];

  String id;
  String title;
  String caseId;
  DateTime dueDate;
  String? description;
  DeadlineStatus status;
  List<int> reminderOffsetsDays;
  DateTime createdAt;
  DateTime updatedAt;

  Deadline copyWith({
    String? title,
    DateTime? dueDate,
    String? description,
    DeadlineStatus? status,
    List<int>? reminderOffsetsDays,
    DateTime? updatedAt,
  }) {
    return Deadline(
      id: id,
      title: title ?? this.title,
      caseId: caseId,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      status: status ?? this.status,
      reminderOffsetsDays: reminderOffsetsDays ?? this.reminderOffsetsDays,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DeadlineAdapter extends TypeAdapter<Deadline> {
  @override
  final int typeId = 2;

  @override
  Deadline read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Deadline(
      id: fields[0] as String,
      title: fields[1] as String,
      caseId: fields[2] as String,
      dueDate: fields[3] as DateTime,
      description: fields[4] as String?,
      status: DeadlineStatus.values[fields[5] as int],
      reminderOffsetsDays: (fields[6] as List).cast<int>(),
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Deadline obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.caseId)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.status.index)
      ..writeByte(6)
      ..write(obj.reminderOffsetsDays)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeadlineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
