import 'package:flutter/material.dart';

import '../models/legal_task.dart';
import '../services/case_service.dart';
import '../services/client_service.dart';
import '../services/task_service.dart';
import '../utils/date_formatters.dart';
import '../utils/enum_labels.dart';
import '../utils/validators.dart';

/// İş ekleme/düzenleme formu. Dosya veya müvekkil bağlantısı opsiyoneldir.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({
    super.key,
    this.caseId,
    this.clientId,
    this.task,
  });

  final String? caseId;
  final String? clientId;
  final LegalTask? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = TaskService();
  final _caseService = CaseService();
  final _clientService = ClientService();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  DateTime? _dueDate;
  late TaskPriority _priority;
  late TaskStatus _status;
  String? _caseId;
  String? _clientId;
  bool _saving = false;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descriptionCtrl = TextEditingController(text: t?.description ?? '');
    _dueDate = t?.dueDate;
    _priority = t?.priority ?? TaskPriority.normal;
    _status = t?.status ?? TaskStatus.waiting;
    _caseId = t?.caseId ?? widget.caseId;
    _clientId = t?.clientId ?? widget.clientId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final t = widget.task!;
        t.title = _titleCtrl.text.trim();
        t.description = _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim();
        t.caseId = _caseId;
        t.clientId = _clientId;
        t.dueDate = _dueDate;
        t.priority = _priority;
        t.status = _status;
        t.completedAt = _status == TaskStatus.done ? (t.completedAt ?? DateTime.now()) : null;
        await _service.update(t);
      } else {
        final created = await _service.createAndAdd(
          title: _titleCtrl.text.trim(),
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          caseId: _caseId,
          clientId: _clientId,
          dueDate: _dueDate,
          priority: _priority,
        );
        if (_status != TaskStatus.waiting) {
          await _service.setStatus(created, _status);
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İş kaydedilemedi. Lütfen tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cases = _caseService.getAll();
    final clients = _clientService.getAll();

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'İşi Düzenle' : 'Yeni İş')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Başlık *'),
              validator: (v) => Validators.requiredField(v, fieldName: 'Başlık'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(labelText: 'Açıklama'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _caseId,
              decoration: const InputDecoration(labelText: 'Bağlı Dosya'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Yok')),
                ...cases.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) => setState(() => _caseId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _clientId,
              decoration: const InputDecoration(labelText: 'Bağlı Müvekkil'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Yok')),
                ...clients.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.displayName))),
              ],
              onChanged: (v) => setState(() => _clientId = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Son Tarih'),
              subtitle: Text(_dueDate != null
                  ? DateFormatters.formatDate(_dueDate!)
                  : 'Belirtilmedi'),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDueDate,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Öncelik'),
              items: TaskPriority.values
                  .map((p) => DropdownMenuItem(
                      value: p, child: Text(EnumLabels.taskPriority(p))))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Durum'),
              items: TaskStatus.values
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text(EnumLabels.taskStatus(s))))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
