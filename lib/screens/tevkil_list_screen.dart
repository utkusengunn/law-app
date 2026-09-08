import 'package:flutter/material.dart';

import '../models/tevkil_isi.dart';
import '../services/case_service.dart';
import '../services/client_service.dart';
import '../services/tevkil_service.dart';
import '../utils/date_formatters.dart';
import '../utils/enum_labels.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/status_chip.dart';
import 'tevkil_form_screen.dart';

/// Tüm tevkil işlerinin listesi, durum filtresi ile - payments_list_screen.dart
/// ile aynı desen (D009 tutarlılığı: liste ekranları aynı loading/error/empty
/// yapısını kullanır).
class TevkilListScreen extends StatefulWidget {
  const TevkilListScreen({super.key});

  @override
  State<TevkilListScreen> createState() => _TevkilListScreenState();
}

class _TevkilListScreenState extends State<TevkilListScreen> {
  final _service = TevkilService();
  final _caseService = CaseService();
  final _clientService = ClientService();

  TevkilDurum? _filter = TevkilDurum.pending;
  bool _loading = true;
  bool _error = false;
  List<TevkilIsi> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      var result = _service.getAll();
      if (_filter != null) {
        result = result.where((t) => t.durum == _filter).toList();
      }
      result.sort((a, b) => a.tarih.compareTo(b.tarih));
      setState(() {
        _items = result;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tevkil İşlerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Yeni Tevkil İşi',
            onPressed: () async {
              await Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const TevkilFormScreen()));
              _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _filterChip(null, 'Tümü'),
                _filterChip(TevkilDurum.pending, 'Bekliyor'),
                _filterChip(TevkilDurum.completed, 'Tamamlandı'),
                _filterChip(TevkilDurum.cancelled, 'İptal'),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _filterChip(TevkilDurum? durum, String label) {
    final selected = _filter == durum;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _filter = durum);
          _load();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingState();
    if (_error) return ErrorState(onRetry: _load);
    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.handshake_outlined,
        message: 'Henüz tevkil işi kaydı bulunmuyor.',
      );
    }
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final t = _items[index];
        final caseFile = t.caseId != null ? _caseService.getById(t.caseId!) : null;
        final client = t.clientId != null ? _clientService.getById(t.clientId!) : null;
        final subtitleParts = [
          'Tevkil eden: ${t.tevkilEdenAd}',
          if (caseFile != null) 'Dosya: ${caseFile.caseNumber}',
          if (client != null) client.displayName,
        ];
        final tile = ListTile(
          leading: const Icon(Icons.handshake_outlined),
          title: Text('${EnumLabels.tevkilAltTuru(t.altTur)} · ${t.baslik}'),
          subtitle: Text(
            '${t.tumGun ? DateFormatters.formatDate(t.tarih) : DateFormatters.formatDateTime(t.tarih)}'
            '\n${subtitleParts.join(' · ')}',
          ),
          isThreeLine: true,
          trailing: StatusChip(
            label: EnumLabels.tevkilDurum(t.durum),
            color: EnumLabels.tevkilDurumColor(t.durum),
          ),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TevkilFormScreen(tevkil: t)),
            );
            _load();
          },
        );
        // Sadece bekleyen tevkillerde yana kaydırarak tek dokunuşla
        // tamamlandı işaretlenebilir (kullanıcı talebi, backlog D015.5).
        if (t.durum != TevkilDurum.pending) return tile;
        return Dismissible(
          key: ValueKey('tevkil_${t.id}'),
          direction: DismissDirection.startToEnd,
          background: Container(
            color: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Tamamlandı',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          confirmDismiss: (_) async {
            await _service.setDurum(t, TevkilDurum.completed);
            _load();
            return false;
          },
          child: tile,
        );
      },
    );
  }
}
