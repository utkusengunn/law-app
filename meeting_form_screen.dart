import 'package:flutter/material.dart';

import '../models/meeting.dart';
import '../services/meeting_service.dart';
import '../utils/date_formatters.dart';
import '../utils/enum_labels.dart';

/// Görüşme ekleme/düzenleme formu. [clientId] zorunlu, [caseId] opsiyoneldir
/// (bir dosya üzerinden açılırsa önceden doldurulur).
class MeetingFormScreen extends StatefulWidget {
  const MeetingFormScreen({
    super.key,
    required this.clientId,
    this.caseId,
    this.meeting,
  });

  final String clientId;
  final String? caseId;
  final Meeting? meeting;

  @override
  State<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends State<MeetingFormScreen> {
  final _service = MeetingService();
  final _noteCtrl = TextEditingController();

  late MeetingType _type;
  late DateTime _date;
  bool _saving = false;

  bool get _isEdit => widget.meeting != null;

  @override
  void initState() {
    super.initState();
    final m = widget.meeting;
    _type = m?.meetingType ?? MeetingType.phone;
    _date = m?.date ?? DateTime.now();
    _noteCtrl.text = m?.note ?? '';
  }

  @override
  void dispose() {
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
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final m = widget.meeting!;
        m.meetingType = _type;
        m.date = _date;
        m.note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
        await _service.update(m);
      } else {
        await _service.createAndAdd(
          clientId: widget.clientId,
          caseId: widget.caseId,
          meetingType: _type,
          date: _date,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görüşme kaydedilemedi. Lütfen tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Görüşmeyi Düzenle' : 'Yeni Görüşme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<MeetingType>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Görüşme Türü'),
            items: MeetingType.values
                .map((t) => DropdownMenuItem(
                    value: t, child: Text(EnumLabels.meetingType(t))))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
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
    );
  }
}
