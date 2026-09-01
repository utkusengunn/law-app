import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../services/payment_service.dart';
import '../utils/date_formatters.dart';
import '../utils/enum_labels.dart';
import '../utils/id_generator.dart';
import '../utils/validators.dart';
import '../widgets/status_chip.dart';

/// Ödeme ekleme/düzenleme formu.
///
/// Yeni bir ödeme oluştururken kullanıcı "Tek Ödeme" (opsiyonel kısmi
/// tahsilat) veya "Taksitli Plan" arasında seçim yapar (md.5). Mevcut bir
/// ödeme düzenlenirken hangi moda kayıtlıysa o moda göre; tahsilat/taksit
/// ödemesi ayrı diyaloglarla, veri bütünlüğü [PaymentService] tarafından
/// zorlanarak girilir.
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
  late final TextEditingController _upfrontCollectedCtrl;
  DateTime? _dueDate;
  bool _saving = false;

  /// Yalnızca YENİ ödeme oluştururken seçilebilir; mevcut bir ödemenin modu
  /// (planlı/plansız) [widget.payment.hasPlan] üzerinden zaten sabittir.
  bool _usePlan = false;
  final List<_DraftInstallment> _draftInstallments = [];

  bool get _isEdit => widget.payment != null;
  Payment? get _payment => widget.payment;

  @override
  void initState() {
    super.initState();
    final p = widget.payment;
    _typeCtrl = TextEditingController(text: p?.paymentType ?? '');
    _amountCtrl = TextEditingController(text: p?.amount.toString() ?? '');
    _currencyCtrl = TextEditingController(text: p?.currency ?? 'TRY');
    _noteCtrl = TextEditingController(text: p?.note ?? '');
    _upfrontCollectedCtrl = TextEditingController();
    _dueDate = p?.dueDate;
    _usePlan = p?.hasPlan ?? false;
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _amountCtrl.dispose();
    _currencyCtrl.dispose();
    _noteCtrl.dispose();
    _upfrontCollectedCtrl.dispose();
    for (final row in _draftInstallments) {
      row.controller.dispose();
    }
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

  Future<void> _addDraftInstallmentRow() async {
    setState(() {
      _draftInstallments.add(_DraftInstallment(
        controller: TextEditingController(),
        dueDate: DateTime.now(),
      ));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usePlan && !_isEdit && _draftInstallments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Taksitli plan için en az bir taksit ekleyin.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final amount = double.parse(_amountCtrl.text.trim().replaceAll(',', '.'));
      final currency =
          _currencyCtrl.text.trim().isEmpty ? 'TRY' : _currencyCtrl.text.trim();

      if (_isEdit) {
        final p = _payment!;
        p.paymentType = _typeCtrl.text.trim();
        p.currency = currency;
        p.note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
        if (!p.hasPlan) {
          // Plansız ödemelerde toplam tutar düzenlenebilir, ama zaten tahsil
          // edilenden az olamaz.
          if (amount < p.collectedAmount) {
            throw PaymentValidationError(
                'Toplam tutar, tahsil edilen tutardan (${p.collectedAmount.toStringAsFixed(2)}) az olamaz.');
          }
          p.amount = amount;
          p.dueDate = _dueDate;
        }
        await _service.update(p);
      } else {
        final upfront = _usePlan
            ? 0.0
            : (double.tryParse(
                    _upfrontCollectedCtrl.text.trim().replaceAll(',', '.')) ??
                0);
        final created = await _service.createAndAdd(
          clientId: widget.clientId,
          caseId: widget.caseId,
          paymentType: _typeCtrl.text.trim(),
          amount: amount,
          currency: currency,
          dueDate: _usePlan ? null : _dueDate,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          collectedAmount: upfront,
        );
        if (_usePlan) {
          final plan = _draftInstallments
              .map((d) => PaymentInstallment(
                    id: IdGenerator.newId(),
                    amount: double.parse(d.controller.text.trim().replaceAll(',', '.')),
                    dueDate: d.dueDate,
                  ))
              .toList();
          await _service.setInstallments(created, plan);
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } on PaymentValidationError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
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

  Future<void> _recordSimpleCollection() async {
    final p = _payment!;
    final result = await _CollectionDialog.show(
      context,
      title: 'Tahsilat Gir',
      maxAmount: p.remainingAmount,
    );
    if (result == null) return;
    try {
      await _service.recordCollection(p, amount: result.amount, date: result.date);
      if (mounted) setState(() {});
    } on PaymentValidationError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _recordInstallmentCollection(PaymentInstallment installment) async {
    final p = _payment!;
    final result = await _CollectionDialog.show(
      context,
      title: 'Taksit Tahsilatı',
      maxAmount: installment.remainingAmount,
    );
    if (result == null) return;
    try {
      await _service.recordInstallmentPayment(p, installment.id,
          amount: result.amount, date: result.date);
      if (mounted) setState(() {});
    } on PaymentValidationError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPlanEditorForNew = !_isEdit && _usePlan;
    final showPlanSummaryForEdit = _isEdit && _payment!.hasPlan;

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
                    enabled: !(_isEdit && _payment!.hasPlan),
                    decoration: InputDecoration(
                      labelText: 'Toplam Tutar *',
                      helperText: (_isEdit && _payment!.hasPlan)
                          ? 'Taksitli planda toplam tutar taksitlerden hesaplanır.'
                          : null,
                    ),
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
            const SizedBox(height: 16),
            if (!_isEdit) ...[
              const Text('Ödeme Şekli', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Tek Ödeme')),
                  ButtonSegment(value: true, label: Text('Taksitli Plan')),
                ],
                selected: {_usePlan},
                onSelectionChanged: (s) => setState(() => _usePlan = s.first),
              ),
              const SizedBox(height: 16),
            ],
            if (!_usePlan && !showPlanSummaryForEdit) ...[
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
              if (!_isEdit)
                TextFormField(
                  controller: _upfrontCollectedCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Şimdi Tahsil Edilen (opsiyonel)',
                    helperText: 'Boş bırakılırsa hiç tahsilat yapılmamış sayılır.',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v.trim().replaceAll(',', '.'));
                    if (n == null || n < 0) return 'Geçerli bir tutar giriniz.';
                    return null;
                  },
                ),
              const SizedBox(height: 12),
            ],
            if (showPlanEditorForNew) _buildDraftInstallmentsEditor(),
            if (showPlanSummaryForEdit) _buildPlanSummary(_payment!),
            if (_isEdit && !_payment!.hasPlan) _buildSimpleCollectionSummary(_payment!),
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

  Widget _buildDraftInstallmentsEditor() {
    final total = _draftInstallments.fold<double>(
        0, (s, d) => s + (double.tryParse(d.controller.text.trim().replaceAll(',', '.')) ?? 0));
    final target = double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                    child: Text('Taksit Planı', style: TextStyle(fontWeight: FontWeight.w600))),
                TextButton.icon(
                  onPressed: _addDraftInstallmentRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Taksit Ekle'),
                ),
              ],
            ),
            for (int i = 0; i < _draftInstallments.length; i++) _buildDraftRow(i),
            const Divider(),
            Text(
              'Planlanan: ${total.toStringAsFixed(2)} / Toplam: ${target.toStringAsFixed(2)}',
              style: TextStyle(
                color: total > target + 0.001
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outline,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftRow(int index) {
    final row = _draftInstallments[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: row.controller,
              decoration: const InputDecoration(labelText: 'Tutar', isDense: true),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: row.dueDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) setState(() => row.dueDate = date);
            },
            child: Text(DateFormatters.formatDate(row.dueDate)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _draftInstallments.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleCollectionSummary(Payment p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                    child: Text('Tahsilat', style: TextStyle(fontWeight: FontWeight.w600))),
                StatusChip(
                  label: EnumLabels.paymentStatus(p.effectiveStatus),
                  color: EnumLabels.paymentStatusColor(p.effectiveStatus),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _summaryRow('Toplam Tutar', p.amount, p.currency),
            _summaryRow('Tahsil Edilen', p.totalCollected, p.currency),
            _summaryRow('Kalan', p.remainingAmount, p.currency),
            if (!p.isFullyPaid) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _recordSimpleCollection,
                icon: const Icon(Icons.add_card_outlined),
                label: const Text('Tahsilat Gir'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSummary(Payment p) {
    final installments = p.installments;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ödeme Planı', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _summaryRow('Toplam Tutar', p.amount, p.currency),
            _summaryRow('Tahsil Edilen', p.totalCollected, p.currency),
            _summaryRow('Kalan', p.remainingAmount, p.currency),
            const Divider(),
            for (int i = 0; i < installments.length; i++)
              _buildInstallmentRow(i + 1, installments[i], p.currency),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentRow(int number, PaymentInstallment installment, String currency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$number. Taksit · ${installment.amount.toStringAsFixed(2)} $currency',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Vade: ${DateFormatters.formatDate(installment.dueDate)}'
                    '${installment.paidAmount > 0 ? ' · Ödenen: ${installment.paidAmount.toStringAsFixed(2)}' : ''}'),
              ],
            ),
          ),
          StatusChip(
            label: EnumLabels.paymentStatus(installment.status),
            color: EnumLabels.paymentStatusColor(installment.status),
          ),
          if (installment.paidAmount < installment.amount) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_card_outlined),
              tooltip: 'Ödeme Gir',
              onPressed: () => _recordInstallmentCollection(installment),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, String currency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('${amount.toStringAsFixed(2)} $currency',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DraftInstallment {
  _DraftInstallment({required this.controller, required this.dueDate});
  final TextEditingController controller;
  DateTime dueDate;
}

class _CollectionResult {
  _CollectionResult(this.amount, this.date);
  final double amount;
  final DateTime date;
}

/// Tutar + tarih girişi için basit, tüm tahsilat noktalarında ortak diyalog.
class _CollectionDialog {
  static Future<_CollectionResult?> show(
    BuildContext context, {
    required String title,
    required double maxAmount,
  }) {
    final amountCtrl = TextEditingController(text: maxAmount.toStringAsFixed(2));
    DateTime date = DateTime.now();
    final formKey = GlobalKey<FormState>();

    return showDialog<_CollectionResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: amountCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                      labelText: 'Tutar (kalan: ${maxAmount.toStringAsFixed(2)})'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Geçerli bir tutar giriniz.';
                    if (n > maxAmount + 0.001) return 'Tutar kalan tutarı geçemez.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ödeme Tarihi'),
                  subtitle: Text(DateFormatters.formatDate(date)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => date = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final amount =
                    double.parse(amountCtrl.text.trim().replaceAll(',', '.'));
                Navigator.of(context).pop(_CollectionResult(amount, date));
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
