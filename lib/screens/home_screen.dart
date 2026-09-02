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
import '../utils/date_formatters.dart';
import '../utils/event_style.dart';
import '../widgets/agenda_card.dart';
import '../widgets/empty_state.dart';
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
import 'profile_screen.dart';
import 'task_form_screen.dart';

/// Dashboard: "Bugün ne var, yakında ne olacak?" sorusuna hızlı cevap veren
/// ekran. Ekleme işlemleri (Müvekkil/Dosya/Süre/Duruşma/Görüşme/İş/Ödeme)
/// hamburger menüde toplanır; ana sayfa bir navigasyon ekranı gibi görünmez.
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
    final today = _buildAgendaCards(days: 0);
    final upcoming = _buildAgendaCards(days: 7, excludeToday: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avukat Asistan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profilim',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.payments_outlined),
            tooltip: 'Tüm Ödemeler',
            onPressed: () => _push(const PaymentsListScreen()),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            SectionHeader(
              title: 'Bugün',
              trailing: Text(DateFormatters.formatWeekdayDate(DateTime.now())),
            ),
            today.isEmpty
                ? const EmptyState(
                    message: 'Bugün için planlanmış bir kayıt yok.',
                    icon: Icons.wb_sunny_outlined)
                : Column(children: today),
            const SizedBox(height: 8),
            const SectionHeader(title: 'Yaklaşanlar (7 gün)'),
            upcoming.isEmpty
                ? const EmptyState(
                    message: 'Önümüzdeki 7 gün için planlanmış bir kayıt yok.',
                    icon: Icons.event_available_outlined)
                : Column(children: upcoming),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Ekleme işlemleri: hamburger menüde toplanır ki ana sayfa bir navigasyon
  /// ekranı gibi görünmesin, sadece "bugün/yakında ne var" sorusuna odaklansın.
  /// Profilim ve Tüm Ödemeler burada YOK - onlar sağ üstteki ikonlarda kalır.
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Row(
                children: [
                  Icon(Icons.gavel, color: Theme.of(context).colorScheme.onPrimary),
                  const SizedBox(width: 12),
                  Text(
                    'Avukat Asistan',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Müvekkil Ekleme'),
              onTap: () => _drawerAction(() => _push(const ClientFormScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('Dosya Ekleme'),
              onTap: () => _drawerAction(() => _push(const CaseFormScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.hourglass_empty),
              title: const Text('Süre'),
              onTap: () => _drawerAction(() =>
                  _pickCaseThen((caseId) => DeadlineFormScreen(caseId: caseId))),
            ),
            ListTile(
              leading: const Icon(Icons.gavel),
              title: const Text('Duruşma'),
              onTap: () => _drawerAction(() =>
                  _pickCaseThen((caseId) => HearingFormScreen(caseId: caseId))),
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: const Text('Görüşme'),
              onTap: () => _drawerAction(() =>
                  _pickClientThen((clientId) => MeetingFormScreen(clientId: clientId))),
            ),
            ListTile(
              leading: const Icon(Icons.checklist_outlined),
              title: const Text('İş'),
              onTap: () => _drawerAction(() => _push(const TaskFormScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Ödeme'),
              onTap: () => _drawerAction(() =>
                  _pickClientThen((clientId) => PaymentFormScreen(clientId: clientId))),
            ),
          ],
        ),
      ),
    );
  }

  /// Drawer'ı kapatıp asıl aksiyonu bir sonraki frame'de çalıştırır (drawer
  /// kapanma animasyonuyla yeni sayfanın push'u çakışmasın diye).
  void _drawerAction(VoidCallback action) {
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) action();
    });
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

  String? _clientNameForCase(String? caseId) {
    if (caseId == null) return null;
    final caseFile = _caseService.getById(caseId);
    if (caseFile == null) return null;
    return _clientService.getById(caseFile.clientId)?.displayName;
  }

  CaseFile? _caseFor(String? caseId) =>
      caseId == null ? null : _caseService.getById(caseId);

  /// [days] gün içindeki (bugün dahil) tüm kayıt türlerini, türü ilk bakışta
  /// belli eden [AgendaCard] listesi olarak tarih sırasına göre toplar.
  /// [excludeToday] true ise bugünün kayıtları hariç tutulur (Yaklaşanlar
  /// bölümü için).
  List<Widget> _buildAgendaCards({required int days, bool excludeToday = false}) {
    final now = DateTime.now();
    final isTodaySection = days == 0;

    bool inRange(DateTime date) {
      final isToday = DateFormatters.isToday(date, from: now);
      if (excludeToday && isToday) return false;
      if (days == 0) return isToday;
      return DateFormatters.isWithinNextDays(date, days, from: now);
    }

    String timeLabelFor(DateTime date, {required bool hasTime}) {
      if (isTodaySection) {
        return hasTime ? DateFormatters.formatTime(date) : 'Bugün';
      }
      return hasTime
          ? '${DateFormatters.formatDayMonth(date)} · ${DateFormatters.formatTime(date)}'
          : DateFormatters.formatDayMonth(date);
    }

    final items = <_AgendaEntry>[];

    for (final Hearing h in _hearingService.getAll()) {
      if (h.status != HearingStatus.scheduled) continue;
      if (!inRange(h.date)) continue;
      items.add(_AgendaEntry(
        date: h.date,
        type: AppEventType.hearing,
        timeLabel: timeLabelFor(h.date, hasTime: true),
        personLine: _clientNameForCase(h.caseId),
        detailLine: '${h.court} · Dosya: ${h.caseNumber}',
        onTap: () => _push(HearingFormScreen(caseId: h.caseId, hearing: h)),
      ));
    }

    for (final Meeting m in _meetingService.getAll()) {
      if (m.status != MeetingStatus.scheduled) continue;
      if (!inRange(m.date)) continue;
      final client = _clientService.getById(m.clientId);
      final caseFile = _caseFor(m.caseId);
      items.add(_AgendaEntry(
        date: m.date,
        type: AppEventType.meeting,
        timeLabel: timeLabelFor(m.date, hasTime: true),
        personLine: client?.displayName ?? 'Görüşme',
        detailLine: caseFile != null
            ? 'Dosya: ${caseFile.caseNumber}'
            : (m.note != null && m.note!.isNotEmpty ? m.note : null),
        onTap: () => _push(ClientDetailScreen(clientId: m.clientId)),
      ));
    }

    for (final LegalTask t in _taskService.getAll()) {
      if (t.status == TaskStatus.done) continue;
      if (t.dueDate == null || !inRange(t.dueDate!)) continue;
      final caseFile = _caseFor(t.caseId);
      items.add(_AgendaEntry(
        date: t.dueDate!,
        type: AppEventType.task,
        timeLabel: timeLabelFor(t.dueDate!, hasTime: false),
        personLine: t.title,
        detailLine: caseFile != null ? 'Dosya: ${caseFile.caseNumber}' : null,
        onTap: () => _push(TaskFormScreen(task: t)),
      ));
    }

    for (final Deadline d in _deadlineService.getAll()) {
      if (d.status != DeadlineStatus.pending) continue;
      if (!inRange(d.dueDate)) continue;
      final caseFile = _caseFor(d.caseId);
      items.add(_AgendaEntry(
        date: d.dueDate,
        type: AppEventType.deadline,
        timeLabel: timeLabelFor(d.dueDate, hasTime: false),
        personLine: d.title,
        detailLine: caseFile != null
            ? 'Dosya: ${caseFile.caseNumber} · Son tarih'
            : 'Son tarih',
        onTap: () => _push(DeadlineFormScreen(caseId: d.caseId, deadline: d)),
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
      items.add(_AgendaEntry(
        date: due,
        type: AppEventType.payment,
        timeLabel: timeLabelFor(due, hasTime: false),
        personLine: client?.displayName ?? 'Bilinmeyen müvekkil',
        detailLine:
            'Kalan ${p.remainingAmount.toStringAsFixed(2)} ${p.currency}',
        onTap: () => _push(ClientDetailScreen(clientId: p.clientId)),
      ));
    }

    items.sort((a, b) => a.date.compareTo(b.date));

    return items
        .map((e) => AgendaCard(
              type: e.type,
              timeLabel: e.timeLabel,
              personLine: e.personLine,
              detailLine: e.detailLine,
              onTap: e.onTap,
            ))
        .toList();
  }
}

class _AgendaEntry {
  _AgendaEntry({
    required this.date,
    required this.type,
    required this.timeLabel,
    required this.onTap,
    this.personLine,
    this.detailLine,
  });

  final DateTime date;
  final AppEventType type;
  final String timeLabel;
  final String? personLine;
  final String? detailLine;
  final VoidCallback onTap;
}
