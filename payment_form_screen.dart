import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../services/payment_service.dart';
import '../utils/date_formatters.dart';
import '../utils/enum_labels.dart';
import '../utils/validators.dart';

/// Ödeme ekleme/düzenleme formu.
class PaymentFormScreen extends StatefulWidget {
  const PaymentFormScreen({
    super.key,
    required this.clientId,
    this.caseId,
    this.payment,
  });

  final String clientId;
  final String? caseId;
  final Payment? payment;

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PaymentService();

  late final TextEditingController _typeCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _noteCtrl;
  DateTime? _dueDate;
  late PaymentStatus _status;
  bool _saving = false;

  bool get _isEdit => widget.payment != null;

  @override
  void initState() {
    super.initState();
    final p = widget.payment;
    _typeCtrl = TextEditingController(text: p?.paymentType ?? '');
    _amountCtrl = TextEditingController(text: p?.amount.toString() ?? '');
    _currencyCtrl = TextEditingController(text: p?.currency ?? 'TRY');
    _noteCtrl = TextEditingController(text: p?.note ?? '');
    _dueDate = p?.dueDate;
    _status = p?.status ?? PaymentStatus.waiting;
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _amountCtrl.dispose();
    _currencyCtrl.dispose();
    _noteCtrl.dispose();
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
      final amount =
          double.parse(_amountCtrl.text.trim().replaceAll(',', '.'));
      if (_isEdit) {
        final p = widget.payment!;
        p.paymentType = _typeCtrl.text.trim();
        p.amount = amount;
        p.currency = _currencyCtrl.text.trim().isEmpty
            ? 'TRY'
            : _currencyCtrl.text.trim();
        p.dueDate = _dueDate;
        p.status = _status;
        p.note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
        if (_status == PaymentStatus.paid && p.paidDate == null) {
          p.paidDate = DateTime.now();
        }
        await _service.update(p);
      } else {
        await _service.createAndAdd(
          clientId: widget.clientId,
          caseId: widget.caseId,
          paymentType: _typeCtrl.text.trim(),
          amount: amount,
          currency:
              _currencyCtrl.text.trim().isEmpty ? 'TRY' : _currencyCtrl.text.trim(),
          dueDate: _dueDate,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödeme kaydedilemedi. Lütfen tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Ödemeyi Düzenle' : 'Yeni Ödeme')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _typeCtrl,
              decoration: const InputDecoration(
                  labelText: 'Ödeme Türü (ör. Vekalet Ücreti) *'),
              validator: (v) =>
                  Validators.requiredField(v, fieldName: 'Ödeme türü'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(labelText: 'Tutar *'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.nonNegativeAmount,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _currencyCtrl,
                    decoration: const InputDecoration(labelText: 'Para Birimi'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vade Tarihi'),
              subtitle: Text(_dueDate != null
                  ? DateFormatters.formatDate(_dueDate!)
                  : 'Belirtilmedi'),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDueDate,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Durum'),
              items: PaymentStatus.values
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text(EnumLabels.paymentStatus(s))))
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
