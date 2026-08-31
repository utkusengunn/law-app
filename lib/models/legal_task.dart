import 'package:hive/hive.dart';

/// İş önceliği.
enum TaskPriority { low, normal, high, critical }

/// İş durumu.
enum TaskStatus { waiting, inProgress, done }

/// Yapılacak iş kaydı. Dart'ın Future/Task adlandırmalarıyla karışmaması
/// için sınıf adı "LegalTask" olarak seçildi.
class LegalTask extends HiveObject {
  LegalTask({
    required this.id,
    required this.title,
    this.description,
    this.caseId,
    this.clientId,
    this.dueDate,
    this.priority = TaskPriority.normal,
    this.status = TaskStatus.waiting,
    required this.createdAt,
    this.completedAt,
  });

  String id;
  String title;
  String? description;
  String? caseId;
  String? clientId;
  DateTime? dueDate;
  TaskPriority priority;
  TaskStatus status;
  DateTime createdAt;
  DateTime? completedAt;

  LegalTask copyWith({
    String? title,
    String? description,
    String? caseId,
    String? clientId,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return LegalTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      caseId: caseId ?? this.caseId,
      clientId: clientId ?? this.clientId,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }
}

class LegalTaskAdapter extends TypeAdapter<LegalTask> {
  @override
  final int typeId = 5;

  @override
  LegalTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LegalTask(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      caseId: fields[3] as String?,
      clientId: fields[4] as String?,
      dueDate: fields[5] as DateTime?,
      priority: TaskPriority.values[fields[6] as int],
      status: TaskStatus.values[fields[7] as int],
      createdAt: fields[8] as DateTime,
      completedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LegalTask obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.caseId)
      ..writeByte(4)
      ..write(obj.clientId)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.priority.index)
      ..writeByte(7)
      ..write(obj.status.index)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegalTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
