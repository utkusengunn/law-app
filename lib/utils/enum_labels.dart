import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/client.dart';
import '../models/deadline.dart';
import '../models/hearing.dart';
import '../models/legal_task.dart';
import '../models/meeting.dart';
import '../models/payment.dart';

/// Enum değerlerinin Türkçe etiketlerini ve durum renklerini üreten
/// yardımcı fonksiyonlar. Tüm ekranlarda tutarlı görünüm sağlar.
class EnumLabels {
  EnumLabels._();

  static String clientType(ClientType t) =>
      t == ClientType.individual ? 'Bireysel' : 'Şirket';

  static String clientStatus(ClientStatus s) =>
      s == ClientStatus.active ? 'Aktif' : 'Pasif';

  static Color clientStatusColor(ClientStatus s) =>
      s == ClientStatus.active ? Colors.green : Colors.grey;

  static String caseStatus(CaseStatus s) {
    switch (s) {
      case CaseStatus.active:
        return 'Aktif';
      case CaseStatus.pending:
        return 'Beklemede';
      case CaseStatus.closed:
        return 'Kapalı';
    }
  }

  static Color caseStatusColor(CaseStatus s) {
    switch (s) {
      case CaseStatus.active:
        return Colors.green;
      case CaseStatus.pending:
        return Colors.orange;
      case CaseStatus.closed:
        return Colors.grey;
    }
  }

  static String deadlineStatus(DeadlineStatus s) {
    switch (s) {
      case DeadlineStatus.pending:
        return 'Bekliyor';
      case DeadlineStatus.completed:
        return 'Tamamlandı';
      case DeadlineStatus.cancelled:
        return 'İptal';
    }
  }

  static Color deadlineStatusColor(DeadlineStatus s) {
    switch (s) {
      case DeadlineStatus.pending:
        return Colors.orange;
      case DeadlineStatus.completed:
        return Colors.green;
      case DeadlineStatus.cancelled:
        return Colors.grey;
    }
  }

  static String hearingStatus(HearingStatus s) {
    switch (s) {
      case HearingStatus.scheduled:
        return 'Planlandı';
      case HearingStatus.completed:
        return 'Tamamlandı';
      case HearingStatus.cancelled:
        return 'İptal';
      case HearingStatus.postponed:
        return 'Ertelendi';
    }
  }

  static Color hearingStatusColor(HearingStatus s) {
    switch (s) {
      case HearingStatus.scheduled:
        return Colors.blue;
      case HearingStatus.completed:
        return Colors.green;
      case HearingStatus.cancelled:
        return Colors.grey;
      case HearingStatus.postponed:
        return Colors.orange;
    }
  }

  static String meetingType(MeetingType t) {
    switch (t) {
      case MeetingType.phone:
        return 'Telefon';
      case MeetingType.inPerson:
        return 'Yüz Yüze';
      case MeetingType.online:
        return 'Online';
      case MeetingType.other:
        return 'Diğer';
    }
  }

  static String meetingStatus(MeetingStatus s) {
    switch (s) {
      case MeetingStatus.scheduled:
        return 'Planlandı';
      case MeetingStatus.completed:
        return 'Tamamlandı';
      case MeetingStatus.cancelled:
        return 'İptal';
    }
  }

  static Color meetingStatusColor(MeetingStatus s) {
    switch (s) {
      case MeetingStatus.scheduled:
        return Colors.blue;
      case MeetingStatus.completed:
        return Colors.green;
      case MeetingStatus.cancelled:
        return Colors.grey;
    }
  }

  static String taskPriority(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return 'Düşük';
      case TaskPriority.normal:
        return 'Normal';
      case TaskPriority.high:
        return 'Yüksek';
      case TaskPriority.critical:
        return 'Kritik';
    }
  }

  static Color taskPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return Colors.grey;
      case TaskPriority.normal:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.critical:
        return Colors.red;
    }
  }

  static String taskStatus(TaskStatus s) {
    switch (s) {
      case TaskStatus.waiting:
        return 'Bekliyor';
      case TaskStatus.inProgress:
        return 'Devam Ediyor';
      case TaskStatus.done:
        return 'Tamamlandı';
    }
  }

  static Color taskStatusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.waiting:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.done:
        return Colors.green;
    }
  }

  static String paymentStatus(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.waiting:
        return 'Ödenmedi';
      case PaymentStatus.partial:
        return 'Kısmen Ödendi';
      case PaymentStatus.paid:
        return 'Ödendi';
      case PaymentStatus.overdue:
        return 'Gecikmiş';
      case PaymentStatus.cancelled:
        return 'İptal';
    }
  }

  static Color paymentStatusColor(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.waiting:
        return Colors.orange;
      case PaymentStatus.partial:
        return Colors.amber;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.overdue:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }
}
