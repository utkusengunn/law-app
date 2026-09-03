import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/deadline.dart';
import '../models/hearing.dart';
import '../models/legal_task.dart';
import '../models/meeting.dart';
import '../models/payment.dart';
import '../services/case_service.dart';
import '../services/client_service.dart';
import '../services/deadline_service.dart';
import '../services/hearing_service.dart';
import '../services/meeting_service.dart';
import '../services/payment_service.dart';
import '../services/task_service.dart';
import 'event_style.dart';

/// Ana sayfa ve takvim ekranlarının ortak "zaman çizelgesi" satırı: tür +
/// tarih + ilgili kişi/dosya bilgisiyle, [AgendaCard] widget'ının ihtiyaç
/// duyduğu her şeyi taşır. Ekrana özel gösterim (zaman etiketi biçimi,
/// navigasyon) çağıran tarafta kalır.
class AgendaEntryData {
  AgendaEntryData({
    required this.date,
    required this.hasTime,
    required this.type,
    required this.onTap,
    this.personLine,
    this.detailLine,
  });

  final DateTime date;
  final bool hasTime;
  final AppEventType type;
  final String? personLine;
  final String? detailLine;
  final VoidCallback onTap;
}

/// Duruşma/Görüşme/İş/Süre/Ödeme kayıtlarını tek bir zaman çizelgesinde
/// birleştiren ortak mantık. Ana sayfa (Bugün/Yaklaşanlar) ve takvim ekranı
/// (gün listesi + hızlı filtreler) bu sınıfı paylaşır - iki ekranın aynı
/// kaydı farklı yorumlaması riskini ortadan kaldırır (md.10).
class AgendaBuilder {
  AgendaBuilder({
    required this.onOpenHearing,
    required this.onOpenMeeting,
    required this.onOpenTask,
    required this.onOpenDeadline,
    required this.onOpenPayment,
  });

  final void Function(Hearing) onOpenHearing;
  final void Function(Meeting) onOpenMeeting;
  final void Function(LegalTask) onOpenTask;
  final void Function(Deadline) onOpenDeadline;
  final void Function(Payment) onOpenPayment;

  final _hearingService = HearingService();
  final _meetingService = MeetingService();
  final _taskService = TaskService();
  final _deadlineService = DeadlineService();
  final _paymentService = PaymentService();
  final _caseService = CaseService();
  final _clientService = ClientService();

  String? _clientNameForCase(String? caseId) {
    if (caseId == null) return null;
    final caseFile = _caseService.getById(caseId);
    if (caseFile == null) return null;
    return _clientService.getById(caseFile.clientId)?.displayName;
  }

  CaseFile? _caseFor(String? caseId) =>
      caseId == null ? null : _caseService.getById(caseId);

  /// [inRange] verilen tarihin dahil edilip edilmeyeceğine karar verir -
  /// tek bir gün, bir hafta, bir ay ya da "her zaman" (takvim işaretleri
  /// için) olabilir.
  List<AgendaEntryData> collect({required bool Function(DateTime date) inRange}) {
    final items = <AgendaEntryData>[];

    for (final Hearing h in _hearingService.getAll()) {
      if (h.status != HearingStatus.scheduled) continue;
      if (!inRange(h.date)) continue;
      items.add(AgendaEntryData(
        date: h.date,
        hasTime: true,
        type: AppEventType.hearing,
        personLine: _clientNameForCase(h.caseId),
        detailLine: '${h.court} · Dosya: ${h.caseNumber}',
        onTap: () => onOpenHearing(h),
      ));
    }

    for (final Meeting m in _meetingService.getAll()) {
      if (m.status != MeetingStatus.scheduled) continue;
      if (!inRange(m.date)) continue;
      final client = _clientService.getById(m.clientId);
      final caseFile = _caseFor(m.caseId);
      items.add(AgendaEntryData(
        date: m.date,
        hasTime: true,
        type: AppEventType.meeting,
        personLine: client?.displayName ?? 'Görüşme',
        detailLine: caseFile != null
            ? 'Dosya: ${caseFile.caseNumber}'
            : (m.note != null && m.note!.isNotEmpty ? m.note : null),
        onTap: () => onOpenMeeting(m),
      ));
    }

    for (final LegalTask t in _taskService.getAll()) {
      if (t.status == TaskStatus.done) continue;
      if (t.dueDate == null || !inRange(t.dueDate!)) continue;
      final caseFile = _caseFor(t.caseId);
      items.add(AgendaEntryData(
        date: t.dueDate!,
        hasTime: false,
        type: AppEventType.task,
        personLine: t.title,
        detailLine: caseFile != null ? 'Dosya: ${caseFile.caseNumber}' : null,
        onTap: () => onOpenTask(t),
      ));
    }

    for (final Deadline d in _deadlineService.getAll()) {
      if (d.status != DeadlineStatus.pending) continue;
      if (!inRange(d.dueDate)) continue;
      final caseFile = _caseFor(d.caseId);
      items.add(AgendaEntryData(
        date: d.dueDate,
        hasTime: false,
        type: AppEventType.deadline,
        personLine: d.title,
        detailLine: caseFile != null
            ? 'Dosya: ${caseFile.caseNumber} · Son tarih'
            : 'Son tarih',
        onTap: () => onOpenDeadline(d),
      ));
    }

    for (final Payment p in _paymentService.getAll()) {
      final effective = p.effectiveStatus;
      if (effective != PaymentStatus.waiting &&
          effective != PaymentStatus.partial &&
          effective != PaymentStatus.overdue) {
        continue;
      }
      final due = p.effectiveDueDate;
      if (due == null || !inRange(due)) continue;
      final client = _clientService.getById(p.clientId);
      items.add(AgendaEntryData(
        date: due,
        hasTime: false,
        type: AppEventType.payment,
        personLine: client?.displayName ?? 'Bilinmeyen müvekkil',
        detailLine:
            'Kalan ${p.remainingAmount.toStringAsFixed(2)} ${p.currency}',
        onTap: () => onOpenPayment(p),
      ));
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }
}
