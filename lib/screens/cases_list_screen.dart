import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../services/case_service.dart';
import '../services/client_service.dart';
import '../utils/enum_labels.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/status_chip.dart';
import 'case_detail_screen.dart';
import 'case_form_screen.dart';

/// Dosya (dava) listesi: arama destekli.
class CasesListScreen extends StatefulWidget {
  const CasesListScreen({super.key});

  @override
  State<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends State<CasesListScreen> {
  final _caseService = CaseService();
  final _clientService = ClientService();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  bool _error = false;
  List<CaseFile> _cases = [];

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
      final result = _caseService.search(_searchCtrl.text)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      setState(() {
        _cases = result;
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
      MaterialPageRoute(builder: (_) => const CaseFormScreen()),
    );
    if (saved == true) _load();
  }

  Future<void> _openDetail(CaseFile caseFile) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: caseFile.id)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dosyalar')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _load(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Dosya adı, esas no veya mahkeme ile ara',
                isDense: true,
              ),
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
    if (_cases.isEmpty) {
      return const EmptyState(message: 'Henüz dosya eklenmemiş.');
    }
    return ListView.builder(
      itemCount: _cases.length,
      itemBuilder: (context, index) {
        final c = _cases[index];
        final client = _clientService.getById(c.clientId);
        return ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(c.name),
          subtitle: Text(
              '${client?.displayName ?? 'Bilinmeyen müvekkil'} · ${c.court}'),
          trailing: StatusChip(
            label: EnumLabels.caseStatus(c.status),
            color: EnumLabels.caseStatusColor(c.status),
          ),
          onTap: () => _openDetail(c),
        );
      },
    );
  }
}
