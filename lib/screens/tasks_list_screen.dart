import 'package:flutter/material.dart';

import '../models/legal_task.dart';
import '../models/tevkil_isi.dart';
import '../services/task_service.dart';
import '../services/tevkil_service.dart';
import '../utils/date_formatters.dart';
import '../utils/enum_labels.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/status_chip.dart';
import 'task_form_screen.dart';
import 'tevkil_form_screen.dart';

/// Kaynak filtresi: sadece kendi işlerimiz mi, sadece tevkil işleri mi,
/// yoksa ikisi bir arada mı gösterilsin (kullanıcı talebi, 2026-09-08,
/// backlog D015.2: "tevkil kayıt edildiğinde işler alanında da listelenmeli").
enum _Source { all, ownWork, tevkil }

/// Birleşik satır: ya bir [LegalTask] ya da bir [TevkilIsi] taşır - ikisi
/// aynı listede tarih sırasına göre gösterilebilsin diye. TevkilIsi BİLİNÇLİ
/// olarak ayrı bir model olarak kalmaya devam ediyor (bkz. D013); bu sadece
/// bir GÖRÜNTÜLEME birleştirmesi, veri modelleri birleştirilmedi.
class _Row {
  _Row.task(this.task) : tevkil = null;
  _Row.tevkil(this.tevkil) : task = null;

  final LegalTask? task;
  final TevkilIsi? tevkil;

  DateTime? get sortDate => task?.dueDate ?? tevkil?.tarih;
}

/// Tüm dosyalardaki işlerin VE tevkil işlerinin tek listesi - kaynak ve
/// durum filtresiyle.
class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  final _taskService = TaskService();
  final _tevkilService = TevkilService();

  TaskStatus? _statusFilter;
  _Source _source = _Source.all;
  bool _loading = true;
  bool _error = false;
  List<_Row> _rows = [];

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
      final rows = <_Row>[];

      if (_source != _Source.tevkil) {
        var tasks = _taskService.getAll();
        if (_statusFilter != null) {
          tasks = tasks.where((t) => t.status == _statusFilter).toList();
        }
        rows.addAll(tasks.map(_Row.task));
      }

      // Tevkil işleri kendi durum sistemine (TevkilDurum) sahip - İş durum
      // filtresi (Bekleyen/Devam Eden/Tamamlanan) onlara birebir uymuyor, bu
      // yüzden "Tamamlanan" filtresi seçiliyse tamamlanan tevkiller de
      // gösterilir, aksi halde (Tümü/Bekleyen/Devam Eden) sadece bekleyen
      // tevkiller gösterilir - iptal edilenler bu listede hiç görünmez
      // (Tevkil İşlerim ekranından takip edilir).
      if (_source != _Source.ownWork) {
        var tevkilItems = _tevkilService.getAll();
        tevkilItems = _statusFilter == TaskStatus.done
            ? tevkilItems.where((t) => t.durum == TevkilDurum.completed).toList()
            : tevkilItems.where((t) => t.durum == TevkilDurum.pending).toList();
        rows.addAll(tevkilItems.map(_Row.tevkil));
      }

      rows.sort((a, b) {
        final ad = a.sortDate ?? DateTime(2100);
        final bd = b.sortDate ?? DateTime(2100);
        return ad.compareTo(bd);
      });
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _openForm({LegalTask? task}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    );
    if (saved == true) _load();
  }

  Future<void> _openTevkil(TevkilIsi tevkil) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TevkilFormScreen(tevkil: tevkil)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İşler')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Yeni İş',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                _sourceChip(_Source.all, 'Tümü'),
                _sourceChip(_Source.ownWork, 'Kendi İşim'),
                _sourceChip(_Source.tevkil, 'Tevkil'),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _statusChip(null, 'Tümü'),
                _statusChip(TaskStatus.waiting, 'Bekleyen'),
                _statusChip(TaskStatus.inProgress, 'Devam Eden'),
                _statusChip(TaskStatus.done, 'Tamamlanan'),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _sourceChip(_Source source, String label) {
    final selected = _source == source;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _source = source);
          _load();
        },
      ),
    );
  }

  Widget _statusChip(TaskStatus? status, String label) {
    final selected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _statusFilter = status);
          _load();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingState();
    if (_error) return ErrorState(onRetry: _load);
    if (_rows.isEmpty) {
      return const EmptyState(message: 'Henüz kayıt bulunmuyor.');
    }
    return ListView.builder(
      itemCount: _rows.length,
      itemBuilder: (context, index) {
        final row = _rows[index];
        return row.task != null ? _taskTile(row.task!) : _tevkilTile(row.tevkil!);
      },
    );
  }

  Widget _taskTile(LegalTask t) {
    final tile = ListTile(
      leading: const Icon(Icons.checklist_outlined),
      title: Text(t.title),
      subtitle: Text(t.dueDate != null
          ? 'Son tarih: ${DateFormatters.formatDate(t.dueDate!)}'
          : 'Son tarih belirtilmedi'),
      trailing: Wrap(
        spacing: 6,
        children: [
          StatusChip(
            label: EnumLabels.taskPriority(t.priority),
            color: EnumLabels.taskPriorityColor(t.priority),
          ),
          StatusChip(
            label: EnumLabels.taskStatus(t.status),
            color: EnumLabels.taskStatusColor(t.status),
          ),
        ],
      ),
      onTap: () => _openForm(task: t),
    );
    // Tamamlanmış bir işi tekrar "tamamlandı" yapmanın anlamı yok - swipe
    // sadece henüz tamamlanmamış işlerde aktif (kullanıcı talebi, backlog
    // D015.5: detaya girmeden tek dokunuşla/yana kaydırarak durum değiştirme).
    if (t.status == TaskStatus.done) return tile;
    return Dismissible(
      key: ValueKey('task_${t.id}'),
      direction: DismissDirection.startToEnd,
      background: _completeBackground(),
      confirmDismiss: (_) async {
        await _taskService.setStatus(t, TaskStatus.done);
        _load();
        return false;
      },
      child: tile,
    );
  }

  Widget _completeBackground() {
    return Container(
      color: Colors.green,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.white),
          SizedBox(width: 8),
          Text('Tamamlandı', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// Tevkil işleri bu listede "Tevkil" rozetiyle ayırt edilir - ödemeler
  /// ekranındaki aynı desen (bkz. payments_list_screen.dart, D013).
  Widget _tevkilTile(TevkilIsi t) {
    final tile = ListTile(
      leading: const Icon(Icons.handshake_outlined),
      title: Text(t.baslik),
      subtitle: Text(
        '${EnumLabels.tevkilAltTuru(t.altTur)} · '
        '${t.tumGun ? DateFormatters.formatDate(t.tarih) : DateFormatters.formatDateTime(t.tarih)}'
        '\nTevkil eden: ${t.tevkilEdenAd}',
      ),
      isThreeLine: true,
      trailing: const Wrap(
        spacing: 6,
        children: [
          StatusChip(label: 'Tevkil', color: Colors.deepPurple),
        ],
      ),
      onTap: () => _openTevkil(t),
    );
    if (t.durum != TevkilDurum.pending) return tile;
    return Dismissible(
      key: ValueKey('tevkil_${t.id}'),
      direction: DismissDirection.startToEnd,
      background: _completeBackground(),
      confirmDismiss: (_) async {
        await _tevkilService.setDurum(t, TevkilDurum.completed);
        _load();
        return false;
      },
      child: tile,
    );
  }
}
