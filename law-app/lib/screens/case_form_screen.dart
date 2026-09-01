import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../services/case_service.dart';
import '../services/client_service.dart';
import '../utils/date_formatters.dart';
import '../utils/validators.dart';

/// Dosya (dava) ekleme/düzenleme formu.
class CaseFormScreen extends StatefulWidget {
  const CaseFormScreen({super.key, this.caseFile, this.defaultClientId});

  final CaseFile? caseFile;
  final String? defaultClientId;

  @override
  State<CaseFormScreen> createState() => _CaseFormScreenState();
}

class _CaseFormScreenState extends State<CaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CaseService();
  final _clientService = ClientService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _caseTypeCtrl;
  late final TextEditingController _courtCtrl;
  late final TextEditingController _caseNumberCtrl;
  late final TextEditingController _opposingPartyCtrl;
  late final TextEditingController _noteCtrl;
  String? _clientId;
  late DateTime _openDate;
  DateTime? _closeDate;
  bool _saving = false;

  bool get _isEdit => widget.caseFile != null;

  @override
  void initState() {
    super.initState();
    final c = widget.caseFile;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _caseTypeCtrl = TextEditingController(text: c?.caseType ?? '');
    _courtCtrl = TextEditingController(text: c?.court ?? '');
    _caseNumberCtrl = TextEditingController(text: c?.caseNumber ?? '');
    _opposingPartyCtrl = TextEditingController(text: c?.opposingParty ?? '');
    _noteCtrl = TextEditingController(text: c?.note ?? '');
    _clientId = c?.clientId ?? widget.defaultClientId;
    _openDate = c?.openDate ?? DateTime.now();
    _closeDate = c?.closeDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _caseTypeCtrl.dispose();
    _courtCtrl.dispose();
    _caseNumberCtrl.dispose();
    _opposingPartyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickOpenDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _openDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _openDate = date);
  }

  Future<void> _pickCloseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _closeDate ?? _openDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _closeDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir müvekkil seçiniz.')),
      );
      return;
    }
    final dateError = Validators.dateNotBefore(_closeDate, _openDate,
        message: 'Kapanış tarihi, açılış tarihinden önce olamaz.');
    if (dateError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(dateError)));
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final c = widget.caseFile!;
        c.name = _nameCtrl.text.trim();
        c.caseType = _caseTypeCtrl.text.trim();
        c.court = _courtCtrl.text.trim();
        c.caseNumber = _caseNumberCtrl.text.trim();
        c.clientId = _clientId!;
        c.opposingParty = _opposingPartyCtrl.text.trim().isEmpty
            ? null
            : _opposingPartyCtrl.text.trim();
        c.openDate = _openDate;
        c.closeDate = _closeDate;
        c.note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
        await _service.update(c);
      } else {
        await _service.createAndAdd(
          name: _nameCtrl.text.trim(),
          caseType: _caseTypeCtrl.text.trim(),
          court: _courtCtrl.text.trim(),
          caseNumber: _caseNumberCtrl.text.trim(),
          clientId: _clientId!,
          opposingParty: _opposingPartyCtrl.text.trim().isEmpty
              ? null
              : _opposingPartyCtrl.text.trim(),
          openDate: _openDate,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosya kaydedilemedi. Lütfen tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = _clientService.getAll();
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Dosyayı Düzenle' : 'Yeni Dosya')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Dosya Adı *'),
              validator: (v) => Validators.requiredField(v, fieldName: 'Dosya adı'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _clientId,
              decoration: const InputDecoration(labelText: 'Müvekkil *'),
              items: clients
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.displayName)))
                  .toList(),
              onChanged: (v) => setState(() => _clientId = v),
              validator: (v) => v == null ? 'Müvekkil seçiniz.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _caseTypeCtrl,
              decoration: const InputDecoration(labelText: 'Dava Türü *'),
              validator: (v) => Validators.requiredField(v, fieldName: 'Dava türü'),
            ),
            const SizedBox(height: 12),
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
              controller: _opposingPartyCtrl,
              decoration: const InputDecoration(labelText: 'Karşı Taraf'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Açılış Tarihi'),
              subtitle: Text(DateFormatters.formatDate(_openDate)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickOpenDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kapanış Tarihi'),
              subtitle: Text(_closeDate != null
                  ? DateFormatters.formatDate(_closeDate!)
                  : 'Belirtilmedi'),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickCloseDate,
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
