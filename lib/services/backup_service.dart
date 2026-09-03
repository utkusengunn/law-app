import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/case_file.dart';
import '../models/client.dart';
import '../models/deadline.dart';
import '../models/hearing.dart';
import '../models/legal_task.dart';
import '../models/meeting.dart';
import '../models/payment.dart';
import 'case_service.dart';
import 'client_service.dart';
import 'deadline_service.dart';
import 'hearing_service.dart';
import 'meeting_service.dart';
import 'payment_service.dart';
import 'task_service.dart';

/// Cihazda tutulan tüm dava/müvekkil/ödeme verisinin tek bir JSON dosyasına
/// dışa aktarılması. Uygulama muhasebe/senkron sistemi değil - bu sadece
/// "telefon kaybolursa/resetlenirse elimde bir kopya olsun" güvencesi.
///
/// Kapsam bilinçli olarak dar tutuldu: bu sürümde sadece DIŞA AKTARMA var.
/// Geri yükleme (içe aktarma) ayrı ve dikkatli tasarlanması gereken bir
/// işlem (üzerine yazma/birleştirme kararı gerektirir) - istenirse ayrı bir
/// iterasyonda eklenir.
class BackupService {
  String? _iso(DateTime? d) => d?.toIso8601String();

  Map<String, dynamic> _clientToJson(Client c) => {
        'id': c.id,
        'type': c.type.name,
        'firstName': c.firstName,
        'lastName': c.lastName,
        'companyTitle': c.companyTitle,
        'phone': c.phone,
        'email': c.email,
        'address': c.address,
        'note': c.note,
        'status': c.status.name,
        'createdAt': _iso(c.createdAt),
        'updatedAt': _iso(c.updatedAt),
      };

  Map<String, dynamic> _caseToJson(CaseFile c) => {
        'id': c.id,
        'name': c.name,
        'caseType': c.caseType,
        'court': c.court,
        'caseNumber': c.caseNumber,
        'clientId': c.clientId,
        'opposingParty': c.opposingParty,
        'openDate': _iso(c.openDate),
        'closeDate': _iso(c.closeDate),
        'status': c.status.name,
        'note': c.note,
        'createdAt': _iso(c.createdAt),
        'updatedAt': _iso(c.updatedAt),
      };

  Map<String, dynamic> _deadlineToJson(Deadline d) => {
        'id': d.id,
        'title': d.title,
        'caseId': d.caseId,
        'dueDate': _iso(d.dueDate),
        'description': d.description,
        'status': d.status.name,
        'reminderOffsetsDays': d.reminderOffsetsDays,
        'createdAt': _iso(d.createdAt),
        'updatedAt': _iso(d.updatedAt),
      };

  Map<String, dynamic> _hearingToJson(Hearing h) => {
        'id': h.id,
        'caseId': h.caseId,
        'court': h.court,
        'caseNumber': h.caseNumber,
        'date': _iso(h.date),
        'hearingType': h.hearingType,
        'room': h.room,
        'note': h.note,
        'status': h.status.name,
      };

  Map<String, dynamic> _meetingToJson(Meeting m) => {
        'id': m.id,
        'clientId': m.clientId,
        'caseId': m.caseId,
        'meetingType': m.meetingType.name,
        'date': _iso(m.date),
        'note': m.note,
        'status': m.status.name,
      };

  Map<String, dynamic> _taskToJson(LegalTask t) => {
        'id': t.id,
        'title': t.title,
        'description': t.description,
        'caseId': t.caseId,
        'clientId': t.clientId,
        'dueDate': _iso(t.dueDate),
        'priority': t.priority.name,
        'status': t.status.name,
        'createdAt': _iso(t.createdAt),
        'completedAt': _iso(t.completedAt),
      };

  Map<String, dynamic> _paymentToJson(Payment p) => {
        'id': p.id,
        'clientId': p.clientId,
        'caseId': p.caseId,
        'paymentType': p.paymentType,
        'amount': p.amount,
        'currency': p.currency,
        'dueDate': _iso(p.dueDate),
        'paidDate': _iso(p.paidDate),
        'status': p.status.name,
        'note': p.note,
        'createdAt': _iso(p.createdAt),
        'updatedAt': _iso(p.updatedAt),
        'collectedAmount': p.collectedAmount,
        'installments': p.installments
            .map((i) => {
                  'id': i.id,
                  'amount': i.amount,
                  'dueDate': _iso(i.dueDate),
                  'paidAmount': i.paidAmount,
                  'paidDate': _iso(i.paidDate),
                })
            .toList(),
      };

  /// Tüm verileri tek bir JSON dosyasına yazar ve dosya yolunu döner.
  Future<File> exportToFile() async {
    final data = {
      'app': 'Avukat Asistan',
      'backupVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'clients': ClientService().getAll().map(_clientToJson).toList(),
      'cases': CaseService().getAll().map(_caseToJson).toList(),
      'deadlines': DeadlineService().getAll().map(_deadlineToJson).toList(),
      'hearings': HearingService().getAll().map(_hearingToJson).toList(),
      'meetings': MeetingService().getAll().map(_meetingToJson).toList(),
      'tasks': TaskService().getAll().map(_taskToJson).toList(),
      'payments': PaymentService().getAll().map(_paymentToJson).toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/avukat-asistan-yedek-$timestamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }
}
