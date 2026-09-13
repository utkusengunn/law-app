import 'package:hive_flutter/hive_flutter.dart';

import '../models/deadline.dart';
import '../models/hearing.dart';
import '../models/hive_registrar.dart';
import '../models/legal_task.dart';
import '../models/meeting.dart';
import '../models/payment.dart';
import '../models/tevkil_isi.dart';
import 'box_names.dart';

/// Hive'ı başlatır, adaptörleri kaydeder ve tüm kutuları açar.
/// main.dart içinde runApp'ten önce çağrılmalıdır.
///
/// NOT (D019, 2026-09-13): Client ve CaseFile artık Hive'da DEĞİL,
/// Firestore'da tutuluyor (bkz. client_service.dart/case_service.dart) -
/// bu yüzden onların kutuları burada AÇILMIYOR. Geri kalan 6 model
/// (Deadline/Hearing/Meeting/LegalTask/Payment/TevkilIsi) şimdilik hâlâ
/// Hive'da - Firestore'a taşınmaları ayrı bir adımda yapılacak (bkz.
/// D018/D019'daki aşamalı plan: önce Client+Case pilotu, sonra kalanı).
class LocalDbService {
  LocalDbService._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    HiveRegistrar.registerAll();

    await Future.wait([
      Hive.openBox<Deadline>(BoxNames.deadlines),
      Hive.openBox<Hearing>(BoxNames.hearings),
      Hive.openBox<Meeting>(BoxNames.meetings),
      Hive.openBox<LegalTask>(BoxNames.tasks),
      Hive.openBox<Payment>(BoxNames.payments),
      Hive.openBox<TevkilIsi>(BoxNames.tevkilIsleri),
      Hive.openBox(BoxNames.settings),
    ]);

    _initialized = true;
  }

  static Future<void> closeAll() async {
    await Hive.close();
    _initialized = false;
  }
}
