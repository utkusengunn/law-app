import 'package:hive/hive.dart';

import 'deadline.dart';
import 'hearing.dart';
import 'legal_task.dart';
import 'meeting.dart';
import 'payment.dart';
import 'tevkil_isi.dart';

/// Tüm Hive TypeAdapter'larını tek noktadan kayıt eder.
///
/// NOT (D019, 2026-09-13): typeId 0 (Client) ve 1 (CaseFile) artık
/// KULLANILMIYOR - bu iki model Firestore'a taşındı, adaptörleri silindi.
/// Bilerek 0/1'i başka bir modele YENİDEN ATAMIYORUZ - eski Hive
/// kutularında (artık açılmayan) kalıntı veri varsa bile typeId çakışması
/// hiç yaşanmasın diye. typeId 2-8 aralığı hâlâ bu 6 model + PaymentInstallment
/// için ayrılmış durumda, çakışma yoktur.
class HiveRegistrar {
  HiveRegistrar._();

  static void registerAll() {
    Hive.registerAdapter(DeadlineAdapter());
    Hive.registerAdapter(HearingAdapter());
    Hive.registerAdapter(MeetingAdapter());
    Hive.registerAdapter(LegalTaskAdapter());
    Hive.registerAdapter(PaymentAdapter());
    Hive.registerAdapter(PaymentInstallmentAdapter());
    Hive.registerAdapter(TevkilIsiAdapter());
  }
}
