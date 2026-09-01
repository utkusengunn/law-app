import 'package:hive/hive.dart';

import 'case_file.dart';
import 'client.dart';
import 'deadline.dart';
import 'hearing.dart';
import 'legal_task.dart';
import 'meeting.dart';
import 'payment.dart';

/// Tüm Hive TypeAdapter'larını tek noktadan kayıt eder.
/// typeId 0-6 aralığı bu 7 model için ayrılmıştır, çakışma yoktur.
class HiveRegistrar {
  HiveRegistrar._();

  static void registerAll() {
    Hive.registerAdapter(ClientAdapter());
    Hive.registerAdapter(CaseFileAdapter());
    Hive.registerAdapter(DeadlineAdapter());
    Hive.registerAdapter(HearingAdapter());
    Hive.registerAdapter(MeetingAdapter());
    Hive.registerAdapter(LegalTaskAdapter());
    Hive.registerAdapter(PaymentAdapter());
  }
}
