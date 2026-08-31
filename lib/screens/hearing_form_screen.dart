import 'package:flutter/material.dart';

import '../models/hearing.dart';
import '../services/hearing_service.dart';
import '../utils/date_formatters.dart';
import '../utils/enum_labels.dart';
import '../utils/validators.dart';

/// Duruşma ekleme/düzenleme formu. Her zaman bir dosyaya (caseId) bağlıdır.
class HearingFormScreen extends StatefulWidget {
  const HearingFormScreen({
    super.key,
    required this.caseId,
    this.defaultCourt,
    this.defaultCaseNumber,
    this.hearing,
  });

  final String caseId;
  final String? defaultCourt;
  final String? defaultCaseNumber;
  final Hearing? hearing;

  @override
  State<HearingFormScreen> createState() => _HearingFormScreenState();
}

class _HearingFormScreenState extends State<HearingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = HearingService();

  late final TextEditingController _courtCtrl;
  late final TextEditingController _caseNumberCtrl;
  late final TextEditingController _hearingTypeCtrl;
  late final TextEditingController _roomCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime _date;
  late HearingStatus _status;
  bool _saving = false;

  bool get _isEdit => widget.hearing != null;

  @override
  void initState() {
    super.initState();
    final h = widget.hearing;
    _courtCtrl = TextEditingController(text: h?.court ?? widget.defaultCourt ?? '');
    _caseNumberCtrl =
        TextEditingController(text: h?.caseNumber ?? widget.defaultCaseNumber ?? '');
    _hearingTypeCtrl = TextEditingController(text: h?.hearingType ?? '');
    _roomCtrl = TextEditingController(text: h?.room ?? '');
    _noteCtrl = TextEditingController(text: h?.note ?? '');
    _date = h?.date ?? DateTime.now();
    _status = h?.status ?? HearingStatus.scheduled;
  }

  @override
  void dispose() {
    _courtCtrl.dispose();
    _caseNumberCtrl.dispose();
    _hearingTypeCtrl.dispose();
    _roomCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time == null) return;
    setState(() {
      _date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final h = widget.hearing!;
        h.court = _courtCtrl.text.trim();
        h.caseNumber = _caseNumberCtrl.text.trim();
        h.hearingType = _hearingTypeCtrl.text.trim();
        h.date = _date;
        h.room = _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim();
        h.note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
        h.status = _status;
        await _service.update(h);
      } else {
        await _service.createAndAdd(
          caseId: widget.caseId,
          court: _courtCtrl.text.trim(),
          caseNumber: _caseNumberCtrl.text.trim(),
          date: _date,
          hearingType: _hearingTypeCtrl.text.trim(),
          room: _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duruşma kaydedilemedi. Lütfen tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Duruşmayı Düzenle' : 'Yeni Duruşma')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _courtCtrl,
              decoration: const InputDecoration(labelText: 'Mahkeme *'),
              validator: (v) => Validators.requiredField(v, fieldName: 'Mahkeme'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _caseNumberCtrl,
              decoration: const InputDecoration(labelText: 'Esas No *'),
              validator: (v) => Validators.requiredField(v, fieldName: 'Esas no'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hearingTypeCtrl,
              decoration: const InputDecoration(labelText: 'Duruşma Türü *'),
              validator: (v) =>
                  Validators.requiredField(v, fieldName: 'Duruşma türü'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tarih ve Saat'),
              subtitle: Text(DateFormatters.formatDateTime(_date)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _roomCtrl,
              decoration: const InputDecoration(labelText: 'Salon'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HearingStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Durum'),
              items: HearingStatus.values
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text(EnumLabels.hearingStatus(s))))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Not'),
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
