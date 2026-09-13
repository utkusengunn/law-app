import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/client.dart';
import '../utils/id_generator.dart';

/// Müvekkil kayıtları için Firestore tabanlı CRUD ve arama işlemleri.
///
/// NOT (D019, 2026-09-13): Bu servis eskiden Hive (cihaz-lokal) kullanıyordu.
/// Artık her avukatın verisi kendi Firestore alt-koleksiyonunda tutuluyor:
/// `users/{uid}/clients/{clientId}` - böylece aynı avukat hem telefonundan
/// hem PC'sinden (web sürümü, D017) aynı veriyi görebiliyor. Ekip yönetimi
/// olmadığı için (D019) her avukat SADECE kendi verisini görür - bu, path'in
/// kendisiyle sağlanıyor, ayrıca bir "ownerId" alanına gerek yok.
///
/// SINGLETON: Eski Hive tasarımında her ekran kendi `ClientService()`
/// örneğini oluşturuyordu ama hepsi aynı global Hive box'ı paylaşıyordu.
/// Aynı davranışı (paylaşılan tek bir önbellek) korumak için burada da
/// `ClientService()` çağrısı hep aynı singleton'a yönlendiriliyor - ekranlar
/// tarafında HİÇBİR ŞEY DEĞİŞMEDİ, hepsi eskisi gibi `ClientService()` ile
/// oluşturup aynı metotları çağırmaya devam ediyor.
///
/// SENKRON GÖRÜNÜMLÜ API: Firestore doğası gereği asenkron, ama mevcut tüm
/// ekranlar `getAll()`/`getById()` gibi SENKRON metotlar bekliyor (eski Hive
/// davranışı). Bunu korumak için: `ensureLoaded()` uygulama girişinde
/// (AuthGate) bir kez awaited edilir, bellek içi bir önbellek doldurur;
/// ardından `snapshots()` ile canlı dinleme başlar ve önbilliği arka planda
/// günceller. Yazma işlemlerinden sonra önbillik AYRICA anında (optimistic)
/// güncellenir ki kullanıcı kendi eklediği kaydı beklemeden görsün.
///
/// BİLİNEN SINIRLAMA: Bir ekran zaten açıkken BAŞKA bir cihazdan gelen bir
/// değişiklik, o ekran yeniden açılana/yenilenene kadar otomatik
/// görünmeyebilir (ekranlar `getAll()`'ı bir kez çağırıp kendi state'inde
/// tutuyor, canlı stream'i dinlemiyor). Bu, uygulamanın zaten var olan
/// "IndexedStack sekmeler arası otomatik tazelenmiyor" sınırlamasıyla
/// (D009) aynı karakterde - veri gerçekten senkronize oluyor, sadece o anda
/// açık bir ekran anlık push almıyor.
class ClientService {
  factory ClientService() => instance;
  ClientService._internal();

  static final ClientService instance = ClientService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  List<Client> _cache = [];
  bool _loaded = false;

  CollectionReference<Map<String, dynamic>> get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('ClientService: oturum açmış kullanıcı yok.');
    }
    return _db.collection('users').doc(uid).collection('clients');
  }

  /// Uygulama girişinde (AuthGate) bir kez çağrılır: ilk veriyi bekleyip
  /// çeker, sonra canlı güncellemeleri dinlemeye başlar. Zaten yüklenmişse
  /// (örn. kullanıcı çıkış yapmadan tekrar çağrılırsa) hiçbir şey yapmaz.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final snap = await _col.get();
    _cache = snap.docs.map(Client.fromDoc).toList();
    _loaded = true;
    _listen();
  }

  /// Oturum kapatıldığında çağrılır - önbelleği ve dinleyiciyi temizler ki
  /// bir sonraki kullanıcı önceki kullanıcının verisini asla görmesin.
  Future<void> reset() async {
    await _sub?.cancel();
    _sub = null;
    _cache = [];
    _loaded = false;
  }

  void _listen() {
    _sub ??= _col.snapshots().listen(
      (snap) {
        _cache = snap.docs.map(Client.fromDoc).toList();
      },
      onError: (_) {
        // Bağlantı hatası: önbellek son bilinen halinde kalır, sessizce
        // yutuluyor - ekranlar zaten kendi hata/yeniden deneme akışını
        // yönetiyor (D014 deseni).
      },
    );
  }

  /// HER ZAMAN yeni bir liste kopyası döner. D016'da düzeltilen
  /// "Unsupported operation: cannot modify an unmodifiable list" hatasını
  /// burada TEKRARLAMAMAK için önemli - çağıran taraf dönen listeyi
  /// serbestçe sort/filter edebilmeli.
  List<Client> getAll() => List<Client>.from(_cache);

  List<Client> getActive() =>
      _cache.where((c) => c.status == ClientStatus.active).toList();

  List<Client> getPassive() =>
      _cache.where((c) => c.status == ClientStatus.passive).toList();

  Client? getById(String id) {
    try {
      return _cache.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Ada/telefona/e-postaya göre basit arama. [includePassive] false ise
  /// sadece aktif müvekkiller aranır.
  List<Client> search(String query, {bool includePassive = false}) {
    final source = includePassive ? getAll() : getActive();
    if (query.trim().isEmpty) return source;
    final q = query.trim().toLowerCase();
    return source.where((c) {
      return c.displayName.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          (c.email?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<Client> add(Client client) async {
    await _col.doc(client.id).set(client.toMap());
    // Optimistic güncelleme: snapshot dinleyicisi zaten önbelleği
    // güncelleyecek ama arada kısa bir gecikme olabilir - kullanıcı kendi
    // eklediği kaydı ANINDA görsün diye önbelleği burada da güncelliyoruz.
    _cache = [..._cache, client];
    return client;
  }

  Future<Client> createAndAdd({
    required ClientType type,
    String? firstName,
    String? lastName,
    String? companyTitle,
    required String phone,
    String? email,
    String? address,
    String? note,
  }) async {
    final now = DateTime.now();
    final client = Client(
      id: IdGenerator.newId(),
      type: type,
      firstName: firstName,
      lastName: lastName,
      companyTitle: companyTitle,
      phone: phone,
      email: email,
      address: address,
      note: note,
      status: ClientStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    return add(client);
  }

  Future<void> update(Client client) async {
    client.updatedAt = DateTime.now();
    await _col.doc(client.id).set(client.toMap());
    _cache = _cache.map((c) => c.id == client.id ? client : c).toList();
  }

  /// Müvekkili pasif duruma alır (soft delete). Bağlı kayıtlar korunur.
  Future<void> setStatus(Client client, ClientStatus status) async {
    client.status = status;
    await update(client);
  }
}
