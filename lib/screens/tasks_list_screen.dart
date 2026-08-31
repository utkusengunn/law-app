import 'package:flutter/material.dart';

import '../models/legal_task.dart';
import '../services/task_service.dart';
import '../utils/date_formatters.dart';
import '../utils/enum_labels.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/status_chip.dart';
import 'task_form_screen.dart';

/// Tüm dosyalardaki işlerin listesi, durum filtresi ile.
class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  final _service = TaskService();

  TaskStatus? _filter;
  bool _loading = true;
  bool _error = false;
  List<LegalTask> _tasks = [];

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
        result = result.where((t) => t.status == _filter).toList();
      }
      result.sort((a, b) {
        final ad = a.dueDate ?? DateTime(2100);
        final bd = b.dueDate ?? DateTime(2100);
        return ad.compareTo(bd);
      });
      setState(() {
        _tasks = result;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İşler')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _filterChip(null, 'Tümü'),
                _filterChip(TaskStatus.waiting, 'Bekleyen'),
                _filterChip(TaskStatus.inProgress, 'Devam Eden'),
                _filterChip(TaskStatus.done, 'Tamamlanan'),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _filterChip(TaskStatus? status, String label) {
    final selected = _filter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _filter = status);
          _load();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingState();
    if (_error) return ErrorState(onRetry: _load);
    if (_tasks.isEmpty) {
      return const EmptyState(message: 'Henüz iş eklenmemiş.');
    }
    return ListView.builder(
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final t = _tasks[index];
        return ListTile(
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
      },
    );
  }
}
