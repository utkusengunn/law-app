import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/case_file.dart';
import '../utils/id_generator.dart';

/// Dosya (dava) kayıtları için Firestore tabanlı CRUD ve arama işlemleri.
///
/// NOT (D019, 2026-09-13): `ClientService` ile birebir aynı desen -
/// `users/{uid}/cases/{caseId}`, singleton + bellek içi önbellek +
/// `snapshots()` ile canlı dinleme. Gerekçe ve sınırlamalar için
/// `client_service.dart`'taki ayrıntılı açıklamaya bakın.
class CaseService {
  factory CaseService() => instance;
  CaseService._internal();

  static final CaseService instance = CaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  List<CaseFile> _cache = [];
  bool _loaded = false;

  CollectionReference<Map<String, dynamic>> get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('CaseService: oturum açmış kullanıcı yok.');
    }
    return _db.collection('users').doc(uid).collection('cases');
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final snap = await _col.get();
    _cache = snap.docs.map(CaseFile.fromDoc).toList();
    _loaded = true;
    _listen();
  }

  Future<void> reset() async {
    await _sub?.cancel();
    _sub = null;
    _cache = [];
    _loaded = false;
  }

  void _listen() {
    _sub ??= _col.snapshots().listen(
      (snap) {
        _cache = snap.docs.map(CaseFile.fromDoc).toList();
      },
      onError: (_) {},
    );
  }

  List<CaseFile> getAll() => List<CaseFile>.from(_cache);

  List<CaseFile> getByClient(String clientId) =>
      _cache.where((c) => c.clientId == clientId).toList();

  List<CaseFile> getOpen() =>
      _cache.where((c) => c.status != CaseStatus.closed).toList();

  CaseFile? getById(String id) {
    try {
      return _cache.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CaseFile> search(String query, {bool includeClosed = true}) {
    final source = includeClosed
        ? getAll()
        : getAll().where((c) => c.status != CaseStatus.closed).toList();
    if (query.trim().isEmpty) return source;
    final q = query.trim().toLowerCase();
    return source.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.caseNumber.toLowerCase().contains(q) ||
          c.court.toLowerCase().contains(q);
    }).toList();
  }

  Future<CaseFile> add(CaseFile caseFile) async {
    await _col.doc(caseFile.id).set(caseFile.toMap());
    _cache = [..._cache, caseFile];
    return caseFile;
  }

  Future<CaseFile> createAndAdd({
    required String name,
    required String caseType,
    required String court,
    required String caseNumber,
    required String clientId,
    String? opposingParty,
    required DateTime openDate,
    String? note,
  }) async {
    final now = DateTime.now();
    final caseFile = CaseFile(
      id: IdGenerator.newId(),
      name: name,
      caseType: caseType,
      court: court,
      caseNumber: caseNumber,
      clientId: clientId,
      opposingParty: opposingParty,
      openDate: openDate,
      status: CaseStatus.active,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    return add(caseFile);
  }

  Future<void> update(CaseFile caseFile) async {
    caseFile.updatedAt = DateTime.now();
    await _col.doc(caseFile.id).set(caseFile.toMap());
    _cache = _cache.map((c) => c.id == caseFile.id ? caseFile : c).toList();
  }

  /// Dosyayı kapatır (soft delete/status change). Bağlı kayıtlar korunur.
  Future<void> setStatus(CaseFile caseFile, CaseStatus status) async {
    caseFile.status = status;
    if (status == CaseStatus.closed) {
      caseFile.closeDate = DateTime.now();
    }
    await update(caseFile);
  }
}
