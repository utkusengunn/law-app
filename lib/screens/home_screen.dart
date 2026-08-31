import 'package:flutter/material.dart';

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
import '../utils/date_formatters.dart';
import '../utils/event_style.dart';
import '../widgets/empty_state.dart';
import '../widgets/event_tile.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/section_header.dart';
import 'case_detail_screen.dart';
import 'case_form_screen.dart';
import 'client_detail_screen.dart';
import 'client_form_screen.dart';
import 'deadline_form_screen.dart';
import 'hearing_form_screen.dart';
import 'meeting_form_screen.dart';
import 'payment_form_screen.dart';
import 'payments_list_screen.dart';
import 'task_form_screen.dart';

/// Dashboard: "Bugün" ve "Yaklaşanlar" bölümleri + hızlı ekleme aksiyonları.
/// Bu ekran bir rapor değil, günlük hızlı kontrol merkezidir; sade tutulur.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _hearingService = HearingService();
  final _meetingService = MeetingService();
  final _taskService = TaskService();
  final _deadlineService = DeadlineService();
  final _paymentService = PaymentService();
  final _caseService = CaseService();
  final _clientService = ClientService();

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final today = _buildAgendaItems(days: 0);
    final upcoming = _buildAgendaItems(days: 7, excludeToday: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avukat Asistan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.payments_outlined),
            tooltip: 'Tüm Ödemeler',
            onPressed: () => _push(const PaymentsListScreen()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _buildQuickActions(),
            SectionHeader(
              title: 'Bugün',
              trailing: Text(DateFormatters.formatWeekdayDate(DateTime.now())),
            ),
            today.isEmpty
                ? const EmptyState(
                    message: 'Bugün için planlanmış bir kayıt yok.',
                    icon: Icons.wb_sunny_outlined)
                : Column(children: today),
            const SectionHeader(title: 'Yaklaşanlar (7 gün)'),
            upcoming.isEmpty
                ? const EmptyState(
                    message: 'Önümüzdeki 7 gün için planlanmış bir kayıt yok.',
                    icon: Icons.event_available_outlined)
                : Column(children: upcoming),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            QuickActionButton(
              icon: Icons.person_add_alt_1_outlined,
              label: 'Müvekkil',
              onTap: () => _push(const ClientFormScreen()),
            ),
            const SizedBox(width: 10),
            QuickActionButton(
              icon: Icons.create_new_folder_outlined,
              label: 'Dosya',
              onTap: () => _push(const CaseFormScreen()),
            ),
            const SizedBox(width: 10),
            QuickActionButton(
              icon: Icons.hourglass_empty,
              label: 'Süre',
              onTap: () => _pickCaseThen((caseId) =>
                  DeadlineFormScreen(caseId: caseId)),
            ),
            const SizedBox(width: 10),
            QuickActionButton(
              icon: Icons.gavel,
              label: 'Duruşma',
              onTap: () => _pickCaseThen((caseId) =>
                  HearingFormScreen(caseId: caseId)),
            ),
            const SizedBox(width: 10),
            QuickActionButton(
              icon: Icons.people_alt_outlined,
              label: 'Görüşme',
              onTap: () => _pickClientThen((clientId) =>
                  MeetingFormScreen(clientId: clientId)),
            ),
            const SizedBox(width: 10),
            QuickActionButton(
              icon: Icons.checklist_outlined,
              label: 'İş',
              onTap: () => _push(const TaskFormScreen()),
            ),
            const SizedBox(width: 10),
            QuickActionButton(
              icon: Icons.payments_outlined,
              label: 'Ödeme',
              onTap: () => _pickClientThen((clientId) =>
                  PaymentFormScreen(clientId: clientId)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _refresh();
  }

  /// Bir dosya seçtirip seçilen dosyayla formu açar (süre/duruşma ekleme).
  Future<void> _pickCaseThen(Widget Function(String caseId) builder) async {
    final cases = _caseService.getAll();
    if (cases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce bir dosya eklemelisiniz.')),
      );
      return;
    }
    final caseId = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: cases
            .map((c) => ListTile(
                  title: Text(c.name),
                  subtitle: Text(c.court),
                  onTap: () => Navigator.of(context).pop(c.id),
                ))
            .toList(),
      ),
    );
    if (caseId == null) return;
    await _push(builder(caseId));
  }

  /// Bir müvekkil seçtirip seçilen müvekkille formu açar (görüşme/ödeme ekleme).
  Future<void> _pickClientThen(Widget Function(String clientId) builder) async {
    final clients = _clientService.getActive();
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce bir müvekkil eklemelisiniz.')),
      );
      return;
    }
    final clientId = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: clients
            .map((c) => ListTile(
                  title: Text(c.displayName),
                  subtitle: Text(c.phone),
                  onTap: () => Navigator.of(context).pop(c.id),
                ))
            .toList(),
      ),
    );
    if (clientId == null) return;
    await _push(builder(clientId));
  }

  /// [days] gün içindeki (bugün dahil) tüm kayıt türlerini tek bir listede
  /// tarih sırasına göre toplar. [excludeToday] true ise bugünün kayıtları
  /// hariç tutulur (Yaklaşanlar bölümü için).
  List<Widget> _buildAgendaItems({required int days, bool excludeToday = false}) {
    final now = DateTime.now();
    bool inRange(DateTime date) {
      final isToday = DateFormatters.isToday(date, from: now);
      if (excludeToday && isToday) return false;
      if (days == 0) return isToday;
      return DateFormatters.isWithinNextDays(date, days, from: now);
    }

    final items = <_AgendaEntry>[];

    for (final Hearing h in _hearingService.getAll()) {
      if (h.status != HearingStatus.scheduled) continue;
      if (!inRange(h.date)) continue;
      items.add(_AgendaEntry(
        date: h.date,
        type: AppEventType.hearing,
        title: h.hearingType,
        subtitle: '${DateFormatters.formatDateTime(h.date)} · ${h.court}',
        onTap: () => _push(HearingFormScreen(caseId: h.caseId, hearing: h)),
      ));
    }

    for (final Meeting m in _meetingService.getAll()) {
      if (m.status != MeetingStatus.scheduled) continue;
      if (!inRange(m.date)) continue;
      final client = _clientService.getById(m.clientId);
      items.add(_AgendaEntry(
        date: m.date,
        type: AppEventType.meeting,
        title: client?.displayName ?? 'Görüşme',
        subtitle: DateFormatters.formatDateTime(m.date),
        onTap: () => _push(ClientDetailScreen(clientId: m.clientId)),
      ));
    }

    for (final LegalTask t in _taskService.getAll()) {
      if (t.status == TaskStatus.done) continue;
      if (t.dueDate == null || !inRange(t.dueDate!)) continue;
      items.add(_AgendaEntry(
        date: t.dueDate!,
        type: AppEventType.task,
        title: t.title,
        subtitle: DateFormatters.formatDate(t.dueDate!),
        onTap: () => _push(TaskFormScreen(task: t)),
      ));
    }

    for (final Deadline d in _deadlineService.getAll()) {
      if (d.status != DeadlineStatus.pending) continue;
      if (!inRange(d.dueDate)) continue;
      items.add(_AgendaEntry(
        date: d.dueDate,
        type: AppEventType.deadline,
        title: d.title,
        subtitle: DateFormatters.formatDate(d.dueDate),
        onTap: () => _push(DeadlineFormScreen(caseId: d.caseId, deadline: d)),
      ));
    }

    for (final Payment p in _paymentService.getAll()) {
      if (p.status != PaymentStatus.waiting && p.status != PaymentStatus.partial) {
        continue;
      }
      if (p.dueDate == null || !inRange(p.dueDate!)) continue;
      items.add(_AgendaEntry(
        date: p.dueDate!,
        type: AppEventType.payment,
        title: '${p.paymentType} · ${p.amount.toStringAsFixed(2)} ${p.currency}',
        subtitle: 'Vade: ${DateFormatters.formatDate(p.dueDate!)}',
        onTap: () => _push(ClientDetailScreen(clientId: p.clientId)),
      ));
    }

    items.sort((a, b) => a.date.compareTo(b.date));

    return items
        .map((e) => EventTile(
              icon: EventStyle.iconFor(e.type),
              color: EventStyle.colorFor(e.type),
              title: e.title,
              subtitle: e.subtitle,
              onTap: e.onTap,
            ))
        .toList();
  }
}

class _AgendaEntry {
  _AgendaEntry({
    required this.date,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final DateTime date;
  final AppEventType type;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}
