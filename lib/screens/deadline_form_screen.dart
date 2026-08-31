import 'package:flutter/material.dart';

import '../models/deadline.dart';
import '../services/deadline_service.dart';
import '../utils/date_formatters.dart';
import '../utils/enum_labels.dart';
import '../utils/validators.dart';

/// Süre ekleme/düzenleme formu. Hatırlatma günleri (kaç gün önce) esnek bir
/// çoklu seçim çip listesi olarak sunulur.
class DeadlineFormScreen extends StatefulWidget {
  const DeadlineFormScreen({
    super.key,
    required this.caseId,
    this.deadline,
  });

  final String caseId;
  final Deadline? deadline;

  @override
  State<DeadlineFormScreen> createState() => _DeadlineFormScreenState();
}

class _DeadlineFormScreenState extends State<DeadlineFormScreen> {
  static const _availableOffsets = [15, 7, 3, 1, 0];

  final _formKey = GlobalKey<FormState>();
  final _service = DeadlineService();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late DateTime _dueDate;
  late DeadlineStatus _status;
  late Set<int> _selectedOffsets;
  bool _saving = false;

  bool get _isEdit => widget.deadline != null;

  @override
  void initState() {
    super.initState();
    final d = widget.deadline;
    _titleCtrl = TextEditingController(text: d?.title ?? '');
    _descriptionCtrl = TextEditingController(text: d?.description ?? '');
    _dueDate = d?.dueDate ?? DateTime.now();
    _status = d?.status ?? DeadlineStatus.pending;
    _selectedOffsets = (d?.reminderOffsetsDays ?? const [15, 7, 3, 1, 0]).toSet();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final offsets = _selectedOffsets.toList()..sort((a, b) => b.compareTo(a));
      if (_isEdit) {
        final d = widget.deadline!;
        d.title = _titleCtrl.text.trim();
        d.dueDate = _dueDate;
        d.description = _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim();
        d.status = _status;
        d.reminderOffsetsDays = offsets;
        await _service.update(d);
      } else {
        await _service.createAndAdd(
          title: _titleCtrl.text.trim(),
          caseId: widget.caseId,
          dueDate: _dueDate,
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          reminderOffsetsDays: offsets,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Süre kaydedilemedi. Lütfen tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Süreyi Düzenle' : 'Yeni Süre')),
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Son Tarih'),
              subtitle: Text(DateFormatters.formatDate(_dueDate)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DeadlineStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Durum'),
              items: DeadlineStatus.values
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text(EnumLabels.deadlineStatus(s))))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            const Text('Hatırlatma Günleri (kaç gün önce)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableOffsets.map((offset) {
                final selected = _selectedOffsets.contains(offset);
                return FilterChip(
                  label: Text(offset == 0 ? 'Aynı gün' : '$offset gün önce'),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedOffsets.add(offset);
                      } else {
                        _selectedOffsets.remove(offset);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(labelText: 'Açıklama'),
              maxLines: 3,
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
