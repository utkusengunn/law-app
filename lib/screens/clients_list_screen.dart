import 'package:flutter/material.dart';

import '../models/client.dart';
import '../services/client_service.dart';
import '../utils/enum_labels.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/status_chip.dart';
import 'client_detail_screen.dart';
import 'client_form_screen.dart';

/// Müvekkil listesi: arama + aktif/pasif filtre.
class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  final _service = ClientService();
  final _searchCtrl = TextEditingController();

  bool _showPassive = false;
  bool _loading = true;
  bool _error = false;
  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final result = _service.search(_searchCtrl.text, includePassive: true);
      final filtered = result
          .where((c) =>
              _showPassive || c.status == ClientStatus.active)
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      setState(() {
        _clients = filtered;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _openForm() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ClientFormScreen()),
    );
    if (saved == true) _load();
  }

  Future<void> _openDetail(Client client) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClientDetailScreen(clientId: client.id)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Müvekkiller')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _load(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Ad, telefon veya e-posta ile ara',
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Pasifleri de göster'),
                Switch(
                  value: _showPassive,
                  onChanged: (v) {
                    setState(() => _showPassive = v);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingState();
    if (_error) return ErrorState(onRetry: _load);
    if (_clients.isEmpty) {
      return const EmptyState(message: 'Henüz müvekkil eklenmemiş.');
    }
    return ListView.builder(
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final c = _clients[index];
        return ListTile(
          leading: CircleAvatar(
            child: Icon(c.type == ClientType.company
                ? Icons.apartment_outlined
                : Icons.person_outline),
          ),
          title: Text(c.displayName),
          subtitle: Text(c.phone),
          trailing: StatusChip(
            label: EnumLabels.clientStatus(c.status),
            color: EnumLabels.clientStatusColor(c.status),
          ),
          onTap: () => _openDetail(c),
        );
      },
    );
  }
}
