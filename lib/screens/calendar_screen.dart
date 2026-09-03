import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../utils/agenda_builder.dart';
import '../utils/date_formatters.dart';
import '../widgets/agenda_card.dart';
import '../widgets/empty_state.dart';
import 'client_detail_screen.dart';
import 'deadline_form_screen.dart';
import 'hearing_form_screen.dart';
import 'task_form_screen.dart';

enum _QuickFilter { today, tomorrow, week, month }

/// Ay görünümlü takvim: günlerde kayıt işaretleri + seçili güne ait kayıtlar,
/// veya Bugün/Yarın/Bu Hafta/Bu Ay hızlı filtrelerinden biri seçiliyken o
/// aralıktaki tüm kayıtlar - her ikisi de tür/kişi/dosya bilgisiyle zengin
/// kartlarda ([AgendaCard], ana sayfayla aynı bileşen - md.10 tutarlılık).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final AgendaBuilder _agendaBuilder;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  _QuickFilter? _activeFilter;

  Map<DateTime, List<AgendaEntryData>> _eventsByDay = {};

  @override
  void initState() {
    super.initState();
    _agendaBuilder = AgendaBuilder(
      onOpenHearing: (h) => _push(HearingFormScreen(caseId: h.caseId, hearing: h)),
      onOpenMeeting: (m) => _push(ClientDetailScreen(clientId: m.clientId)),
      onOpenTask: (t) => _push(TaskFormScreen(task: t)),
      onOpenDeadline: (d) => _push(DeadlineFormScreen(caseId: d.caseId, deadline: d)),
      onOpenPayment: (p) => _push(ClientDetailScreen(clientId: p.clientId)),
    );
    _loadEvents();
  }

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  void _loadEvents() {
    final all = _agendaBuilder.collect(inRange: (_) => true);
    final map = <DateTime, List<AgendaEntryData>>{};
    for (final e in all) {
      map.putIfAbsent(_dayKey(e.date), () => []).add(e);
    }
    setState(() => _eventsByDay = map);
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _loadEvents();
  }

  List<AgendaEntryData> _eventsForDay(DateTime day) =>
      _eventsByDay[_dayKey(day)] ?? const [];

  /// Seçili hızlı filtreye göre tarih aralığı kontrolü.
  bool _inActiveRange(DateTime date) {
    final now = DateTime.now();
    switch (_activeFilter!) {
      case _QuickFilter.today:
        return DateFormatters.isSameDay(date, now);
      case _QuickFilter.tomorrow:
        return DateFormatters.isSameDay(date, now.add(const Duration(days: 1)));
      case _QuickFilter.week:
        final startOfWeek = DateFormatters.startOfDay(now)
            .subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final target = DateFormatters.startOfDay(date);
        return !target.isBefore(startOfWeek) && !target.isAfter(endOfWeek);
      case _QuickFilter.month:
        return date.year == now.year && date.month == now.month;
    }
  }

  void _selectFilter(_QuickFilter? filter) {
    setState(() {
      _activeFilter = _activeFilter == filter ? null : filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = _activeFilter != null
        ? (_agendaBuilder.collect(inRange: _inActiveRange))
        : (_eventsForDay(_selectedDay)..sort((a, b) => a.date.compareTo(b.date)));

    return Scaffold(
      appBar: AppBar(title: const Text('Takvim')),
      body: Column(
        children: [
          TableCalendar<AgendaEntryData>(
            locale: 'tr_TR',
            firstDay: DateTime(2015, 1, 1),
            lastDay: DateTime(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                _activeFilter == null && DateFormatters.isSameDay(day, _selectedDay),
            eventLoader: _eventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Ay'},
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
                _activeFilter = null;
              });
            },
            onPageChanged: (focused) {
              _focusedDay = focused;
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Bugün', _QuickFilter.today),
                  const SizedBox(width: 8),
                  _filterChip('Yarın', _QuickFilter.tomorrow),
                  const SizedBox(width: 8),
                  _filterChip('Bu Hafta', _QuickFilter.week),
                  const SizedBox(width: 8),
                  _filterChip('Bu Ay', _QuickFilter.month),
                ],
              ),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? EmptyState(
                    message: _activeFilter != null
                        ? 'Bu aralıkta kayıt bulunmuyor.'
                        : 'Bu gün için kayıt bulunmuyor.',
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final e = entries[index];
                      return AgendaCard(
                        type: e.type,
                        timeLabel: _timeLabelFor(e),
                        personLine: e.personLine,
                        detailLine: e.detailLine,
                        onTap: e.onTap,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _timeLabelFor(AgendaEntryData e) {
    // Gün modunda (tek gün listeleniyor) sadece saat yeterli; aralık
    // filtresi aktifken (Bu Hafta/Bu Ay) hangi gün olduğu da gösterilmeli.
    if (_activeFilter == null) {
      return e.hasTime ? DateFormatters.formatTime(e.date) : 'Tüm gün';
    }
    return e.hasTime
        ? '${DateFormatters.formatDayMonth(e.date)} · ${DateFormatters.formatTime(e.date)}'
        : DateFormatters.formatDayMonth(e.date);
  }

  Widget _filterChip(String label, _QuickFilter filter) {
    final selected = _activeFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _selectFilter(filter),
    );
  }
}
