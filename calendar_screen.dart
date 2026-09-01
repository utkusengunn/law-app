import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/deadline.dart';
import '../models/hearing.dart';
import '../models/legal_task.dart';
import '../models/meeting.dart';
import '../models/payment.dart';
import '../services/client_service.dart';
import '../services/deadline_service.dart';
import '../services/hearing_service.dart';
import '../services/meeting_service.dart';
import '../services/payment_service.dart';
import '../services/task_service.dart';
import '../utils/date_formatters.dart';
import '../utils/event_style.dart';
import '../widgets/empty_state.dart';
import '../widgets/event_tile.dart';
import 'client_detail_screen.dart';
import 'deadline_form_screen.dart';
import 'hearing_form_screen.dart';
import 'task_form_screen.dart';

class _CalendarEntry {
  _CalendarEntry({
    required this.date,
    required this.type,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final DateTime date;
  final AppEventType type;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}

/// Ay görünümlü takvim: günlerde kayıt işaretleri, seçilen güne ait
/// kayıtlar tür bazlı ikon/renk ile aşağıda listelenir.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _hearingService = HearingService();
  final _meetingService = MeetingService();
  final _deadlineService = DeadlineService();
  final _taskService = TaskService();
  final _paymentService = PaymentService();
  final _clientService = ClientService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<DateTime, List<_CalendarEntry>> _eventsByDay = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  void _loadEvents() {
    final map = <DateTime, List<_CalendarEntry>>{};

    void addEntry(DateTime date, _CalendarEntry entry) {
      final key = _dayKey(date);
      map.putIfAbsent(key, () => []).add(entry);
    }

    for (final Hearing h in _hearingService.getAll()) {
      addEntry(
        h.date,
        _CalendarEntry(
          date: h.date,
          type: AppEventType.hearing,
          title: h.hearingType,
          subtitle: '${DateFormatters.formatTime(h.date)} · ${h.court}',
          onTap: () => _push(HearingFormScreen(caseId: h.caseId, hearing: h)),
        ),
      );
    }

    for (final Meeting m in _meetingService.getAll()) {
      final client = _clientService.getById(m.clientId);
      addEntry(
        m.date,
        _CalendarEntry(
          date: m.date,
          type: AppEventType.meeting,
          title: client?.displayName ?? 'Görüşme',
          subtitle: DateFormatters.formatTime(m.date),
          onTap: () => _push(ClientDetailScreen(clientId: m.clientId)),
        ),
      );
    }

    for (final Deadline d in _deadlineService.getAll()) {
      if (d.status != DeadlineStatus.pending) continue;
      addEntry(
        d.dueDate,
        _CalendarEntry(
          date: d.dueDate,
          type: AppEventType.deadline,
          title: d.title,
          subtitle: 'Son tarih',
          onTap: () => _push(DeadlineFormScreen(caseId: d.caseId, deadline: d)),
        ),
      );
    }

    for (final LegalTask t in _taskService.getAll()) {
      if (t.status == TaskStatus.done || t.dueDate == null) continue;
      addEntry(
        t.dueDate!,
        _CalendarEntry(
          date: t.dueDate!,
          type: AppEventType.task,
          title: t.title,
          subtitle: 'Son tarih',
          onTap: () => _push(TaskFormScreen(task: t)),
        ),
      );
    }

    for (final Payment p in _paymentService.getAll()) {
      if (p.dueDate == null) continue;
      if (p.status != PaymentStatus.waiting && p.status != PaymentStatus.partial) {
        continue;
      }
      addEntry(
        p.dueDate!,
        _CalendarEntry(
          date: p.dueDate!,
          type: AppEventType.payment,
          title: '${p.paymentType} · ${p.amount.toStringAsFixed(2)} ${p.currency}',
          subtitle: 'Vade',
          onTap: () => _push(ClientDetailScreen(clientId: p.clientId)),
        ),
      );
    }

    setState(() => _eventsByDay = map);
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _loadEvents();
  }

  List<_CalendarEntry> _eventsForDay(DateTime day) {
    return _eventsByDay[_dayKey(day)] ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _eventsForDay(_selectedDay)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(title: const Text('Takvim')),
      body: Column(
        children: [
          TableCalendar<_CalendarEntry>(
            locale: 'tr_TR',
            firstDay: DateTime(2015, 1, 1),
            lastDay: DateTime(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => DateFormatters.isSameDay(day, _selectedDay),
            eventLoader: _eventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Ay'},
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) {
              _focusedDay = focused;
            },
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Color(0xFF12294F),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Color(0xFFBFD0E6),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFF12294F),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedEvents.isEmpty
                ? const EmptyState(message: 'Bu gün için kayıt bulunmuyor.')
                : ListView.builder(
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final e = selectedEvents[index];
                      return EventTile(
                        icon: EventStyle.iconFor(e.type),
                        color: EventStyle.colorFor(e.type),
                        title: e.title,
                        subtitle: e.subtitle,
                        onTap: e.onTap,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
