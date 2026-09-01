import 'package:hive/hive.dart';

import '../models/client.dart';
import '../utils/id_generator.dart';
import 'box_names.dart';

/// Müvekkil kayıtları için CRUD ve arama işlemleri.
class ClientService {
  Box<Client> get _box => Hive.box<Client>(BoxNames.clients);

  List<Client> getAll() => _box.values.toList();

  List<Client> getActive() =>
      _box.values.where((c) => c.status == ClientStatus.active).toList();

  List<Client> getPassive() =>
      _box.values.where((c) => c.status == ClientStatus.passive).toList();

  Client? getById(String id) {
    try {
      return _box.values.firstWhere((c) => c.id == id);
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
    await _box.put(client.id, client);
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
    await client.save();
  }

  /// Müvekkili pasif duruma alır (soft delete). Bağlı kayıtlar korunur.
  Future<void> setStatus(Client client, ClientStatus status) async {
    client.status = status;
    client.updatedAt = DateTime.now();
    await client.save();
  }
}
