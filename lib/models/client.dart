import 'package:cloud_firestore/cloud_firestore.dart';

/// Müvekkil tipi: bireysel ya da şirket.
enum ClientType { individual, company }

/// Müvekkilin aktif/pasif durumu. Pasif müvekkiller silinmez; sadece
/// listeleme dışında bırakılır (soft delete). Bağlı dosya/görüşme/ödeme/süre
/// kayıtları olduğu gibi korunur.
enum ClientStatus { active, passive }

/// Müvekkil kaydı.
///
/// NOT (D019, 2026-09-13): Bu model eskiden Hive (cihaz-lokal depolama) ile
/// saklanıyordu. Artık Firestore'da `users/{uid}/clients/{id}` altında
/// tutuluyor - böylece aynı avukat hem telefonundan hem web/PC sürümünden
/// aynı veriyi görebiliyor (bkz. D017/D018/D019 kararları). Enum alanları
/// artık Hive'daki gibi sayısal index değil, İSİM (string) olarak
/// saklanıyor - Firestore'da sıra/index kısıtı olmadığı için bu daha güvenli
/// ve okunur; ileride yeni bir enum değeri eklerken sıra önemsiz olur.
class Client {
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

  /// Firestore doküman ID'si - ayrıca bir alan olarak saklanmaz, sadece
  /// bellekte taşınır.
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

  /// Firestore'a yazılacak alan haritası. `id` dahil edilmez - doküman ID'si
  /// zaten `id` olarak kullanılıyor, tekrar bir alan olarak saklamaya gerek
  /// yok.
  Map<String, dynamic> toMap() => {
        'type': type.name,
        'firstName': firstName,
        'lastName': lastName,
        'companyTitle': companyTitle,
        'phone': phone,
        'email': email,
        'address': address,
        'note': note,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Firestore dokümanından `Client` üretir. Bilinmeyen/eksik bir enum
  /// string'i gelirse (örn. ileride bir alan yanlış yazılırsa) sessizce
  /// varsayılana düşer - uygulamanın çökmesindense eksik/varsayılan bir
  /// değer göstermesi tercih edildi (D014'teki "asla ekranı kırma" prensibi).
  factory Client.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Client(
      id: doc.id,
      type: _enumFromName(ClientType.values, d['type'], ClientType.individual),
      firstName: d['firstName'] as String?,
      lastName: d['lastName'] as String?,
      companyTitle: d['companyTitle'] as String?,
      phone: d['phone'] as String? ?? '',
      email: d['email'] as String?,
      address: d['address'] as String?,
      note: d['note'] as String?,
      status: _enumFromName(ClientStatus.values, d['status'], ClientStatus.active),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Bir enum listesinde isme göre arama yapar, bulunamazsa/null ise
/// [fallback] döner.
T _enumFromName<T>(List<T> values, dynamic name, T fallback) {
  if (name is! String) return fallback;
  for (final v in values) {
    if ((v as Enum).name == name) return v;
  }
  return fallback;
}
