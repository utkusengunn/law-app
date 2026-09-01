import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../services/case_service.dart';
import '../services/client_service.dart';
import '../services/deadline_service.dart';
import '../services/hearing_service.dart';
import '../services/meeting_service.dart';
import '../services/payment_service.dart';
import '../services/task_service.dart';
import '../utils/date_formatters.dart';
import '../utils/enum_labels.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_chip.dart';
import 'case_form_screen.dart';
import 'deadline_form_screen.dart';
import 'hearing_form_screen.dart';
import 'meeting_form_screen.dart';
import 'payment_form_screen.dart';
import 'task_form_screen.dart';

/// Dosya (dava) detay ekranı: Genel / Duruşmalar / Süreler / İşler /
/// Görüşmeler / Ödemeler sekmeleri.
class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen>
    with SingleTickerProviderStateMixin {
  final _caseService = CaseService();
  final _clientService = ClientService();
  final _hearingService = HearingService();
  final _deadlineService = DeadlineService();
  final _taskService = TaskService();
  final _meetingService = MeetingService();
  final _paymentService = PaymentService();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  CaseFile? get _caseFile => _caseService.getById(widget.caseId);

  Future<void> _editCase(CaseFile caseFile) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CaseFormScreen(caseFile: caseFile)),
    );
    setState(() {});
  }

  Future<void> _closeCase(CaseFile caseFile) async {
    await _caseService.setStatus(caseFile, CaseStatus.closed);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final caseFile = _caseFile;
    if (caseFile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dosya')),
        body: const EmptyState(message: 'Dosya bulunamadı.'),
      );
    }
    final client = _clientService.getById(caseFile.clientId);

    return Scaffold(
      appBar: AppBar(
        title: Text(caseFile.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editCase(caseFile),
          ),
          if (caseFile.status != CaseStatus.closed)
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Dosyayı Kapat',
              onPressed: () => _closeCase(caseFile),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Genel'),
            Tab(text: 'Duruşmalar'),
            Tab(text: 'Süreler'),
            Tab(text: 'İşler'),
            Tab(text: 'Görüşmeler'),
            Tab(text: 'Ödemeler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(caseFile, client?.displayName),
          _buildHearingsTab(caseFile),
          _buildDeadlinesTab(caseFile),
          _buildTasksTab(caseFile),
          _buildMeetingsTab(caseFile),
          _buildPaymentsTab(caseFile),
        ],
      ),
    );
  }

  Widget _buildGeneralTab(CaseFile caseFile, String? clientName) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(caseFile.caseType,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            StatusChip(
              label: EnumLabels.caseStatus(caseFile.status),
              color: EnumLabels.caseStatusColor(caseFile.status),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _infoRow('Müvekkil', clientName ?? 'Bilinmiyor'),
        _infoRow('Mahkeme', caseFile.court),
        _infoRow('Esas No', caseFile.caseNumber),
        if (caseFile.opposingParty != null)
          _infoRow('Karşı Taraf', caseFile.opposingParty!),
        _infoRow('Açılış Tarihi', DateFormatters.formatDate(caseFile.openDate)),
        if (caseFile.closeDate != null)
          _infoRow('Kapanış Tarihi', DateFormatters.formatDate(caseFile.closeDate!)),
        if (caseFile.note != null && caseFile.note!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Not', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(caseFile.note!),
        ],
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _addButton(String label, VoidCallback onTap) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add),
        label: Text(label),
      ),
    );
  }

  Widget _buildHearingsTab(CaseFile caseFile) {
    final hearings = _hearingService.getByCase(caseFile.id)
      ..sort((a, b) => a.date.compareTo(b.date));
    return Column(
      children: [
        _addButton('Duruşma Ekle', () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => HearingFormScreen(
              caseId: caseFile.id,
              defaultCourt: caseFile.court,
              defaultCaseNumber: caseFile.caseNumber,
            ),
          ));
          setState(() {});
        }),
        Expanded(
          child: hearings.isEmpty
              ? const EmptyState(message: 'Henüz duruşma eklenmemiş.')
              : ListView.builder(
                  itemCount: hearings.length,
                  itemBuilder: (context, i) {
                    final h = hearings[i];
                    return ListTile(
                      leading: const Icon(Icons.gavel),
                      title: Text(h.hearingType),
                      subtitle: Text(DateFormatters.formatDateTime(h.date)),
                      trailing: StatusChip(
                        label: EnumLabels.hearingStatus(h.status),
                        color: EnumLabels.hearingStatusColor(h.status),
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => HearingFormScreen(
                            caseId: caseFile.id,
                            hearing: h,
                          ),
                        ));
                        setState(() {});
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDeadlinesTab(CaseFile caseFile) {
    final deadlines = _deadlineService.getByCase(caseFile.id)
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return Column(
      children: [
        _addButton('Süre Ekle', () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DeadlineFormScreen(caseId: caseFile.id),
          ));
          setState(() {});
        }),
        Expanded(
          child: deadlines.isEmpty
              ? const EmptyState(message: 'Henüz süre eklenmemiş.')
              : ListView.builder(
                  itemCount: deadlines.length,
                  itemBuilder: (context, i) {
                    final d = deadlines[i];
                    return ListTile(
                      leading: const Icon(Icons.hourglass_bottom),
                      title: Text(d.title),
                      subtitle: Text(DateFormatters.formatDate(d.dueDate)),
                      trailing: StatusChip(
                        label: EnumLabels.deadlineStatus(d.status),
                        color: EnumLabels.deadlineStatusColor(d.status),
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => DeadlineFormScreen(
                            caseId: caseFile.id,
                            deadline: d,
                          ),
                        ));
                        setState(() {});
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTasksTab(CaseFile caseFile) {
    final tasks = _taskService.getByCase(caseFile.id)
      ..sort((a, b) {
        final ad = a.dueDate ?? DateTime(2100);
        final bd = b.dueDate ?? DateTime(2100);
        return ad.compareTo(bd);
      });
    return Column(
      children: [
        _addButton('İş Ekle', () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TaskFormScreen(
                caseId: caseFile.id, clientId: caseFile.clientId),
          ));
          setState(() {});
        }),
        Expanded(
          child: tasks.isEmpty
              ? const EmptyState(message: 'Henüz iş eklenmemiş.')
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, i) {
                    final t = tasks[i];
                    return ListTile(
                      leading: const Icon(Icons.checklist_outlined),
                      title: Text(t.title),
                      subtitle: Text(t.dueDate != null
                          ? DateFormatters.formatDate(t.dueDate!)
                          : EnumLabels.taskStatus(t.status)),
                      trailing: StatusChip(
                        label: EnumLabels.taskPriority(t.priority),
                        color: EnumLabels.taskPriorityColor(t.priority),
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TaskFormScreen(task: t),
                        ));
                        setState(() {});
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMeetingsTab(CaseFile caseFile) {
    final meetings = _meetingService.getByCase(caseFile.id)
      ..sort((a, b) => b.date.compareTo(a.date));
    return Column(
      children: [
        _addButton('Görüşme Ekle', () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => MeetingFormScreen(
                clientId: caseFile.clientId, caseId: caseFile.id),
          ));
          setState(() {});
        }),
        Expanded(
          child: meetings.isEmpty
              ? const EmptyState(message: 'Henüz görüşme eklenmemiş.')
              : ListView.builder(
                  itemCount: meetings.length,
                  itemBuilder: (context, i) {
                    final m = meetings[i];
                    return ListTile(
                      leading: const Icon(Icons.people_alt_outlined),
                      title: Text(EnumLabels.meetingType(m.meetingType)),
                      subtitle: Text(DateFormatters.formatDateTime(m.date)),
                      trailing: StatusChip(
                        label: EnumLabels.meetingStatus(m.status),
                        color: EnumLabels.meetingStatusColor(m.status),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentsTab(CaseFile caseFile) {
    final payments = _paymentService.getByCase(caseFile.id)
      ..sort((a, b) => (b.effectiveDueDate ?? b.createdAt)
          .compareTo(a.effectiveDueDate ?? a.createdAt));
    return Column(
      children: [
        _addButton('Ödeme Ekle', () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PaymentFormScreen(
                clientId: caseFile.clientId, caseId: caseFile.id),
          ));
          setState(() {});
        }),
        Expanded(
          child: payments.isEmpty
              ? const EmptyState(message: 'Henüz ödeme kaydı bulunmuyor.')
              : ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, i) {
                    final p = payments[i];
                    final due = p.effectiveDueDate;
                    return ListTile(
                      leading: const Icon(Icons.payments_outlined),
                      title: Text(
                          '${p.paymentType} · ${p.amount.toStringAsFixed(2)} ${p.currency}'),
                      subtitle: Text(
                          '${due != null ? 'Vade: ${DateFormatters.formatDate(due)}' : 'Vade tarihi yok'}'
                          '${p.totalCollected > 0 && !p.isFullyPaid ? ' · Kalan: ${p.remainingAmount.toStringAsFixed(2)} ${p.currency}' : ''}'),
                      trailing: StatusChip(
                        label: EnumLabels.paymentStatus(p.effectiveStatus),
                        color: EnumLabels.paymentStatusColor(p.effectiveStatus),
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PaymentFormScreen(
                            clientId: caseFile.clientId,
                            caseId: caseFile.id,
                            payment: p,
                          ),
                        ));
                        setState(() {});
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
