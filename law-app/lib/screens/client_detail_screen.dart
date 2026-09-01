import 'package:flutter/material.dart';

import '../models/client.dart';
import '../services/case_service.dart';
import '../services/client_service.dart';
import '../services/meeting_service.dart';
import '../services/payment_service.dart';
import '../utils/date_formatters.dart';
import '../utils/enum_labels.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_chip.dart';
import 'case_detail_screen.dart';
import 'client_form_screen.dart';
import 'meeting_form_screen.dart';
import 'payment_form_screen.dart';

/// Müvekkil detayı: temel bilgiler + dosyalar/görüşmeler/ödemeler sekmeleri.
class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  final _clientService = ClientService();
  final _caseService = CaseService();
  final _meetingService = MeetingService();
  final _paymentService = PaymentService();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Client? get _client => _clientService.getById(widget.clientId);

  Future<void> _toggleStatus(Client client) async {
    final newStatus = client.status == ClientStatus.active
        ? ClientStatus.passive
        : ClientStatus.active;
    await _clientService.setStatus(client, newStatus);
    setState(() {});
  }

  Future<void> _editClient(Client client) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClientFormScreen(client: client)),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final client = _client;
    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Müvekkil')),
        body: const EmptyState(message: 'Müvekkil bulunamadı.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(client.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editClient(client),
          ),
          IconButton(
            icon: Icon(client.status == ClientStatus.active
                ? Icons.person_off_outlined
                : Icons.person_outline),
            tooltip: client.status == ClientStatus.active
                ? 'Pasife Al'
                : 'Aktife Al',
            onPressed: () => _toggleStatus(client),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dosyalar'),
            Tab(text: 'Görüşmeler'),
            Tab(text: 'Ödemeler'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildInfoCard(client),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCasesTab(client),
                _buildMeetingsTab(client),
                _buildPaymentsTab(client),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Client client) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(EnumLabels.clientType(client.type),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  StatusChip(
                    label: EnumLabels.clientStatus(client.status),
                    color: EnumLabels.clientStatusColor(client.status),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.phone_outlined, size: 16),
                const SizedBox(width: 6),
                Text(client.phone),
              ]),
              if (client.email != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.email_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text(client.email!),
                ]),
              ],
              if (client.address != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(client.address!)),
                ]),
              ],
              if (client.note != null && client.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(client.note!,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCasesTab(Client client) {
    final cases = _caseService.getByClient(client.id);
    if (cases.isEmpty) {
      return const EmptyState(message: 'Bu müvekkile ait dosya bulunmuyor.');
    }
    return ListView.builder(
      itemCount: cases.length,
      itemBuilder: (context, i) {
        final caseFile = cases[i];
        return ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(caseFile.name),
          subtitle: Text('${caseFile.court} · ${caseFile.caseNumber}'),
          trailing: StatusChip(
            label: EnumLabels.caseStatus(caseFile.status),
            color: EnumLabels.caseStatusColor(caseFile.status),
          ),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CaseDetailScreen(caseId: caseFile.id),
              ),
            );
            setState(() {});
          },
        );
      },
    );
  }

  Widget _buildMeetingsTab(Client client) {
    final meetings = _meetingService.getByClient(client.id)
      ..sort((a, b) => b.date.compareTo(a.date));
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MeetingFormScreen(clientId: client.id),
              ));
              setState(() {});
            },
            icon: const Icon(Icons.add),
            label: const Text('Görüşme Ekle'),
          ),
        ),
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

  Widget _buildPaymentsTab(Client client) {
    final payments = _paymentService.getByClient(client.id)
      ..sort((a, b) => (b.dueDate ?? b.createdAt)
          .compareTo(a.dueDate ?? a.createdAt));
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PaymentFormScreen(clientId: client.id),
              ));
              setState(() {});
            },
            icon: const Icon(Icons.add),
            label: const Text('Ödeme Ekle'),
          ),
        ),
        Expanded(
          child: payments.isEmpty
              ? const EmptyState(message: 'Henüz ödeme kaydı bulunmuyor.')
              : ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, i) {
                    final p = payments[i];
                    return ListTile(
                      leading: const Icon(Icons.payments_outlined),
                      title: Text('${p.paymentType} · ${p.amount.toStringAsFixed(2)} ${p.currency}'),
                      subtitle: Text(p.dueDate != null
                          ? 'Vade: ${DateFormatters.formatDate(p.dueDate!)}'
                          : 'Vade tarihi yok'),
                      trailing: StatusChip(
                        label: EnumLabels.paymentStatus(p.status),
                        color: EnumLabels.paymentStatusColor(p.status),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
