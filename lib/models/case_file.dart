import 'package:cloud_firestore/cloud_firestore.dart';

/// Dosyanın (davanın) durumu.
enum CaseStatus { active, pending, closed }

/// Dava/dosya kaydı. Dart'ın "Case" anahtar kelimesiyle karışmaması için
/// sınıf adı "CaseFile" olarak seçildi.
///
/// NOT (D019, 2026-09-13): Client modeliyle aynı gerekçeyle Hive'dan
/// Firestore'a taşındı - `users/{uid}/cases/{id}`. Enum artık isim (string)
/// olarak saklanıyor, Hive'daki index kısıtı yok.
class CaseFile {
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

  /// Firestore doküman ID'si - ayrıca bir alan olarak saklanmaz.
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

  Map<String, dynamic> toMap() => {
        'name': name,
        'caseType': caseType,
        'court': court,
        'caseNumber': caseNumber,
        'clientId': clientId,
        'opposingParty': opposingParty,
        'openDate': Timestamp.fromDate(openDate),
        'closeDate': closeDate != null ? Timestamp.fromDate(closeDate!) : null,
        'status': status.name,
        'note': note,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory CaseFile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return CaseFile(
      id: doc.id,
      name: d['name'] as String? ?? '',
      caseType: d['caseType'] as String? ?? '',
      court: d['court'] as String? ?? '',
      caseNumber: d['caseNumber'] as String? ?? '',
      clientId: d['clientId'] as String? ?? '',
      opposingParty: d['opposingParty'] as String?,
      openDate: (d['openDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      closeDate: (d['closeDate'] as Timestamp?)?.toDate(),
      status: _enumFromName(CaseStatus.values, d['status'], CaseStatus.active),
      note: d['note'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

T _enumFromName<T>(List<T> values, dynamic name, T fallback) {
  if (name is! String) return fallback;
  for (final v in values) {
    if ((v as Enum).name == name) return v;
  }
  return fallback;
}
