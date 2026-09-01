import 'package:flutter/material.dart';

import '../models/client.dart';
import '../services/client_service.dart';
import '../utils/validators.dart';

/// Müvekkil ekleme/düzenleme formu. [client] verilirse düzenleme modunda açılır.
class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, this.client});

  final Client? client;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ClientService();

  late ClientType _type;
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _companyTitleCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _noteCtrl;

  bool _saving = false;

  bool get _isEdit => widget.client != null;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _type = c?.type ?? ClientType.individual;
    _firstNameCtrl = TextEditingController(text: c?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: c?.lastName ?? '');
    _companyTitleCtrl = TextEditingController(text: c?.companyTitle ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _noteCtrl = TextEditingController(text: c?.note ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _companyTitleCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final c = widget.client!;
        c.type = _type;
        c.firstName = _firstNameCtrl.text.trim();
        c.lastName = _lastNameCtrl.text.trim();
        c.companyTitle = _companyTitleCtrl.text.trim();
        c.phone = _phoneCtrl.text.trim();
        c.email = _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim();
        c.address =
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim();
        c.note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
        await _service.update(c);
      } else {
        await _service.createAndAdd(
          type: _type,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          companyTitle: _companyTitleCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          address:
              _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kaydedilirken bir hata oluştu. Lütfen tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateNameFields() {
    if (_type == ClientType.company) {
      if (_companyTitleCtrl.text.trim().isEmpty) {
        return 'Şirket unvanı zorunludur.';
      }
    } else {
      if (_firstNameCtrl.text.trim().isEmpty ||
          _lastNameCtrl.text.trim().isEmpty) {
        return 'Ad ve soyad zorunludur.';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Müvekkili Düzenle' : 'Yeni Müvekkil'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<ClientType>(
              segments: const [
                ButtonSegment(
                  value: ClientType.individual,
                  label: Text('Bireysel'),
                  icon: Icon(Icons.person_outline),
                ),
                ButtonSegment(
                  value: ClientType.company,
                  label: Text('Şirket'),
                  icon: Icon(Icons.apartment_outlined),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            if (_type == ClientType.individual) ...[
              TextFormField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(labelText: 'Ad *'),
                validator: (_) => _validateNameFields(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Soyad *'),
                validator: (_) => _validateNameFields(),
              ),
            ] else
              TextFormField(
                controller: _companyTitleCtrl,
                decoration: const InputDecoration(labelText: 'Şirket Unvanı *'),
                validator: (_) => _validateNameFields(),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Telefon *'),
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'E-posta'),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.optionalEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Adres'),
              maxLines: 2,
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
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
