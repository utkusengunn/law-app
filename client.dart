import 'package:hive/hive.dart';

/// Müvekkil tipi: bireysel ya da şirket.
enum ClientType { individual, company }

/// Müvekkilin aktif/pasif durumu. Pasif müvekkiller silinmez; sadece
/// listeleme dışında bırakılır (soft delete). Bağlı dosya/görüşme/ödeme/süre
/// kayıtları olduğu gibi korunur.
enum ClientStatus { active, passive }

class Client extends HiveObject {
  Client({
    required this.id,
    required this.type,
    this.firstName,
    this.lastName,
    this.companyTitle,
    required this.phone,
    this.email,
    this.address,
    this.note,
    this.status = ClientStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  String id;
  ClientType type;
  String? firstName;
  String? lastName;
  String? companyTitle;
  String phone;
  String? email;
  String? address;
  String? note;
  ClientStatus status;
  DateTime createdAt;
  DateTime updatedAt;

  /// Ekranlarda gösterilecek görünen ad.
  String get displayName {
    if (type == ClientType.company) {
      return (companyTitle == null || companyTitle!.trim().isEmpty)
          ? '(İsimsiz Şirket)'
          : companyTitle!;
    }
    final full = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return full.isEmpty ? '(İsimsiz Müvekkil)' : full;
  }

  Client copyWith({
    ClientType? type,
    String? firstName,
    String? lastName,
    String? companyTitle,
    String? phone,
    String? email,
    String? address,
    String? note,
    ClientStatus? status,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id,
      type: type ?? this.type,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      companyTitle: companyTitle ?? this.companyTitle,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// El ile yazılmış (build_runner olmadan) Hive TypeAdapter.
class ClientAdapter extends TypeAdapter<Client> {
  @override
  final int typeId = 0;

  @override
  Client read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Client(
      id: fields[0] as String,
      type: ClientType.values[fields[1] as int],
      firstName: fields[2] as String?,
      lastName: fields[3] as String?,
      companyTitle: fields[4] as String?,
      phone: fields[5] as String,
      email: fields[6] as String?,
      address: fields[7] as String?,
      note: fields[8] as String?,
      status: ClientStatus.values[fields[9] as int],
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Client obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type.index)
      ..writeByte(2)
      ..write(obj.firstName)
      ..writeByte(3)
      ..write(obj.lastName)
      ..writeByte(4)
      ..write(obj.companyTitle)
      ..writeByte(5)
      ..write(obj.phone)
      ..writeByte(6)
      ..write(obj.email)
      ..writeByte(7)
      ..write(obj.address)
      ..writeByte(8)
      ..write(obj.note)
      ..writeByte(9)
      ..write(obj.status.index)
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
      other is ClientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
