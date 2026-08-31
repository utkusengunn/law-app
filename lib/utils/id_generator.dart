import 'package:uuid/uuid.dart';

/// Uygulama genelinde benzersiz kimlik (id) üretimi için tek noktadan sarmalayıcı.
class IdGenerator {
  IdGenerator._();

  static const Uuid _uuid = Uuid();

  static String newId() => _uuid.v4();
}
