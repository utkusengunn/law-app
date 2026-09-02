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
    // Kahverengi/bej ana paletle uyumlu, tonu düşürülmüş ("aşırı renkli
    // olmayan") ama birbirinden net ayrışan vurgu renkleri.
    switch (type) {
      case AppEventType.hearing:
        return const Color(0xFFA1483A); // kiremit/terracotta
      case AppEventType.meeting:
        return const Color(0xFF4B6B3A); // zeytin yeşili
      case AppEventType.deadline:
        return const Color(0xFFB07A2E); // okr/amber
      case AppEventType.task:
        return const Color(0xFF3F5B58); // koyu çamurumsu teal
      case AppEventType.payment:
        return const Color(0xFF7B3F61); // koyu bordo/eflatun
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
