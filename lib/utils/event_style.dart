import 'package:flutter/material.dart';

/// Takvimde ve dashboard'da gösterilen kayıt türleri.
enum AppEventType { hearing, meeting, deadline, task, payment }

/// Her kayıt türü için ortak ikon/renk/etiket tanımı. Böylece dashboard ve
/// takvim ekranları aynı görsel dili kullanır.
class EventStyle {
  EventStyle._();

  static IconData iconFor(AppEventType type) {
    switch (type) {
      case AppEventType.hearing:
        return Icons.gavel;
      case AppEventType.meeting:
        return Icons.people_alt_outlined;
      case AppEventType.deadline:
        return Icons.hourglass_bottom;
      case AppEventType.task:
        return Icons.checklist_outlined;
      case AppEventType.payment:
        return Icons.payments_outlined;
    }
  }

  static Color colorFor(AppEventType type) {
    switch (type) {
      case AppEventType.hearing:
        return const Color(0xFFB3261E); // koyu kırmızı
      case AppEventType.meeting:
        return const Color(0xFF0B6E4F); // yeşil
      case AppEventType.deadline:
        return const Color(0xFFB4720A); // turuncu/amber
      case AppEventType.task:
        return const Color(0xFF3F51B5); // indigo
      case AppEventType.payment:
        return const Color(0xFF6A1B9A); // mor
    }
  }

  static String labelFor(AppEventType type) {
    switch (type) {
      case AppEventType.hearing:
        return 'Duruşma';
      case AppEventType.meeting:
        return 'Görüşme';
      case AppEventType.deadline:
        return 'Süre';
      case AppEventType.task:
        return 'İş';
      case AppEventType.payment:
        return 'Ödeme';
    }
  }
}
