import 'package:hive_flutter/hive_flutter.dart';

import '../models/case_file.dart';
import '../models/client.dart';
import '../models/deadline.dart';
import '../models/hearing.dart';
import '../models/hive_registrar.dart';
import '../models/legal_task.dart';
import '../models/meeting.dart';
import '../models/payment.dart';
import 'box_names.dart';

/// Hive'ı başlatır, adaptörleri kaydeder ve tüm kutuları açar.
/// main.dart içinde runApp'ten önce çağrılmalıdır.
class LocalDbService {
  LocalDbService._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    HiveRegistrar.registerAll();

    await Future.wait([
      Hive.openBox<Client>(BoxNames.clients),
      Hive.openBox<CaseFile>(BoxNames.cases),
      Hive.openBox<Deadline>(BoxNames.deadlines),
      Hive.openBox<Hearing>(BoxNames.hearings),
      Hive.openBox<Meeting>(BoxNames.meetings),
      Hive.openBox<LegalTask>(BoxNames.tasks),
      Hive.openBox<Payment>(BoxNames.payments),
    ]);

    _initialized = true;
  }

  static Future<void> closeAll() async {
    await Hive.close();
    _initialized = false;
  }
}
