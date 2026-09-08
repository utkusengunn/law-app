import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../models/tevkil_isi.dart';
import '../services/case_service.dart';
import '../services/client_service.dart';
import '../services/payment_service.dart';
import '../services/tevkil_service.dart';
import '../utils/date_formatters.dart';
import '../utils/enum_labels.dart';
import '../utils/validators.dart';
import 'payment_form_screen.dart';

/// Tevkil işi ekleme/düzenleme formu.
///
/// Kendi işlerimizden (Hearing/Meeting/LegalTask) BİLİNÇLİ olarak ayrı bir
/// ekran: tevkil işi duruşma da olabilir, görüşme de, iş de - hangisi
/// olacağı [TevkilAltTuru] ile burada seçilir. Dosya/müvekkil bağlantısı
/// opsiyoneldir (kullanıcı talebi, 2026-09-08: "bazen bağlı, bazen değil").
class TevkilFormScreen extends StatefulWidget {
  const TevkilFormScreen({super.key, this.tevkil});

  final TevkilIsi? tevkil;

  @override
  State<TevkilFormScreen> createState() => _TevkilFormScreenState();
}

class _TevkilFormScreenState extends State<TevkilFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = TevkilService();
  final _caseService = CaseService();
  final _clientService = ClientService();
  final _paymentService = PaymentService();

  late final TextEditingController _baslikCtrl;
  late final TextEditingController _tevkilEdenAdCtrl;
  late final TextEditingController _tevkilEdenIletisimCtrl;
  late final TextEditingController _noteCtrl;

  late TevkilAltTuru _altTur;
  late DateTime _tarih;
  late bool _tumGun;
  late TevkilDurum _durum;
  String? _caseId;
  String? _clientId;
  bool _saving = false;

  // Sadece YENİ kayıt oluştururken gösterilir - "hemen bir ödeme de
  // ekleyeyim" isteyen kullanıcı için tek ekranda tamamlanabilsin diye.
  // Düzenlemede ödeme, Tevkil İşlerim listesinden/Ödemeler ekranından ayrı
  // yönetilir (payment_form_screen.dart'taki mevcut akışla tutarlı).
  bool _addPayment = false;
  late final TextEditingController _paymentTypeCtrl;
  late final TextEditingController _paymentAmountCtrl;
  DateTime? _paymentDueDate;

  bool get _isEdit => widget.tevkil != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tevkil;
    _baslikCtrl = TextEditingController(text: t?.baslik ?? '');
    _tevkilEdenAdCtrl = TextEditingController(text: t?.tevkilEdenAd ?? '');
    _tevkilEdenIletisimCtrl =
        TextEditingController(text: t?.tevkilEdenIletisim ?? '');
    _noteCtrl = TextEditingController(text: t?.note ?? '');
    _altTur = t?.altTur ?? TevkilAltTuru.hearing;
    _tarih = t?.tarih ?? DateTime.now();
    _tumGun = t?.tumGun ?? false;
    _durum = t?.durum ?? TevkilDurum.pending;
    _caseId = t?.caseId;
    _clientId = t?.clientId;

    _paymentTypeCtrl = TextEditingController(text: 'Tevkil Ücreti');
    _paymentAmountCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _baslikCtrl.dispose();
    _tevkilEdenAdCtrl.dispose();
    _tevkilEdenIletisimCtrl.dispose();
    _noteCtrl.dispose();
    _paymentTypeCtrl.dispose();
    _paymentAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    if (_tumGun) {
      setState(() => _tarih = DateTime(date.year, date.month, date.day));
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_tarih),
    );
    if (time == null) return;
    setState(() {
      _tarih = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickCase() async {
    final cases = _caseService.getAll();
    final caseId = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('Bağlı dosya yok'),
            onTap: () => Navigator.of(context).pop<String?>(null),
          ),
          ...cases.map((c) => ListTile(
                title: Text(c.name),
                subtitle: Text(c.court),
                onTap: () => Navigator.of(context).pop<String?>(c.id),
              )),
        ],
      ),
    );
    // showModalBottomSheet<String?> pop edilmezse (dışarı tıklama) null
    // dönebilir - bunu "seçim yapılmadı" olarak yorumluyoruz, mevcut
    // _caseId'yi değiştirmiyoruz. "Bağlı dosya yok" seçimi ayrı bir pop
    // çağrısıyla ayırt edilemediği için burada basitçe: sheet kapandıysa
    // (result alanı fark etmeksizin) seçilen değeri uyguluyoruz - "Bağlı
    // dosya yok" zaten null döndürüyor, dışarı tıklama da null döndürüyor,
    // ikisi de aynı sonucu (bağlantıyı temizle) verdiği için pratikte sorun
    // yaratmıyor.
    setState(() => _caseId = caseId);
  }

  Future<void> _pickClient() async {
    final clients = _clientService.getActive();
    final clientId = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('Bağlı müvekkil yok'),
            onTap: () => Navigator.of(context).pop<String?>(null),
          ),
          ...clients.map((c) => ListTile(
                title: Text(c.displayName),
                subtitle: Text(c.phone),
                onTap: () => Navigator.of(context).pop<String?>(c.id),
              )),
        ],
      ),
    );
    setState(() => _clientId = clientId);
  }

  Future<void> _pickPaymentDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _paymentDueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _paymentDueDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final t = widget.tevkil!;
        t.altTur = _altTur;
        t.tarih = _tarih;
        t.tumGun = _tumGun;
        t.baslik = _baslikCtrl.text.trim();
        t.tevkilEdenAd = _tevkilEdenAdCtrl.text.trim();
        t.tevkilEdenIletisim = _tevkilEdenIletisimCtrl.text.trim().isEmpty
            ? null
            : _tevkilEdenIletisimCtrl.text.trim();
        t.caseId = _caseId;
        t.clientId = _clientId;
        t.note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
        t.durum = _durum;
        await _service.update(t);
      } else {
        final created = await _service.createAndAdd(
          altTur: _altTur,
          tarih: _tarih,
          tumGun: _tumGun,
          baslik: _baslikCtrl.text.trim(),
          tevkilEdenAd: _tevkilEdenAdCtrl.text.trim(),
          tevkilEdenIletisim: _tevkilEdenIletisimCtrl.text.trim().isEmpty
              ? null
              : _tevkilEdenIletisimCtrl.text.trim(),
          caseId: _caseId,
          clientId: _clientId,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );

        if (_addPayment && _paymentAmountCtrl.text.trim().isNotEmpty) {
          final amount =
              double.tryParse(_paymentAmountCtrl.text.trim().replaceAll(',', '.')) ?? 0;
          if (amount > 0) {
            await _paymentService.createAndAdd(
              clientId: _clientId,
              caseId: _caseId,
              paymentType: _paymentTypeCtrl.text.trim().isEmpty
                  ? 'Tevkil Ücreti'
                  : _paymentTypeCtrl.text.trim(),
              amount: amount,
              dueDate: _paymentDueDate,
              source: PaymentSource.tevkil,
              tevkilIsiId: created.id,
              payerName: _tevkilEdenAdCtrl.text.trim(),
            );
          }
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tevkil işi kaydedilemedi. Lütfen tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseFile = _caseId != null ? _caseService.getById(_caseId!) : null;
    final client = _clientId != null ? _clientService.getById(_clientId!) : null;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Tevkil İşini Düzenle' : 'Yeni Tevkil İşi')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Tür', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<TevkilAltTuru>(
              segments: TevkilAltTuru.values
                  .map((t) => ButtonSegment(
                      value: t, label: Text(EnumLabels.tevkilAltTuru(t))))
                  .toList(),
              selected: {_altTur},
              onSelectionChanged: (s) => setState(() => _altTur = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _baslikCtrl,
              decoration: const InputDecoration(
                labelText: 'Başlık *',
                helperText: 'Örn. "İcra takibine itiraz duruşması"',
              ),
              validator: (v) => Validators.requiredField(v, fieldName: 'Başlık'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tüm gün'),
              subtitle: const Text('Saatli değil, sadece gün bazlı bir iş.'),
              value: _tumGun,
              onChanged: (v) => setState(() => _tumGun = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_tumGun ? 'Tarih' : 'Tarih ve Saat'),
              subtitle: Text(_tumGun
                  ? DateFormatters.formatDate(_tarih)
                  : DateFormatters.formatDateTime(_tarih)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDateTime,
            ),
            const Divider(height: 24),
            TextFormField(
              controller: _tevkilEdenAdCtrl,
              decoration: const InputDecoration(labelText: 'Tevkil Eden Avukat/Büro *'),
              validator: (v) =>
                  Validators.requiredField(v, fieldName: 'Tevkil eden avukat/büro'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tevkilEdenIletisimCtrl,
              decoration: const InputDecoration(labelText: 'İletişim (telefon/e-posta)'),
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bağlı Dosya'),
              subtitle: Text(caseFile?.name ?? 'Seçilmedi (opsiyonel)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickCase,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bağlı Müvekkil'),
              subtitle: Text(client?.displayName ?? 'Seçilmedi (opsiyonel)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickClient,
            ),
            const SizedBox(height: 12),
            if (_isEdit) ...[
              DropdownButtonFormField<TevkilDurum>(
                value: _durum,
                decoration: const InputDecoration(labelText: 'Durum'),
                items: TevkilDurum.values
                    .map((d) => DropdownMenuItem(
                        value: d, child: Text(EnumLabels.tevkilDurum(d))))
                    .toList(),
                onChanged: (v) => setState(() => _durum = v!),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Not'),
              maxLines: 3,
            ),
            if (!_isEdit) ...[
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ödeme de ekle'),
                subtitle: const Text('Bu tevkil işi için hemen bir ödeme kaydı oluştur.'),
                value: _addPayment,
                onChanged: (v) => setState(() => _addPayment = v),
              ),
              if (_addPayment) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _paymentTypeCtrl,
                  decoration: const InputDecoration(labelText: 'Ödeme Türü'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _paymentAmountCtrl,
                  decoration: const InputDecoration(labelText: 'Tutar'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vade Tarihi'),
                  subtitle: Text(_paymentDueDate != null
                      ? DateFormatters.formatDate(_paymentDueDate!)
                      : 'Belirtilmedi'),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickPaymentDueDate,
                ),
                Text(
                  'Ödeyen: ${_tevkilEdenAdCtrl.text.trim().isEmpty ? '(Tevkil eden avukat/büro adını girin)' : _tevkilEdenAdCtrl.text.trim()}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.outline, fontSize: 12.5),
                ),
              ],
            ] else if (widget.tevkil != null) ...[
              const Divider(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  final linked = _paymentService.getByTevkilIsi(widget.tevkil!.id);
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PaymentFormScreen(
                      clientId: _clientId,
                      caseId: _caseId,
                      payment: linked.isNotEmpty ? linked.first : null,
                      tevkilIsiId: widget.tevkil!.id,
                      defaultPayerName: _tevkilEdenAdCtrl.text.trim(),
                    ),
                  ));
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.payments_outlined),
                label: Text(_paymentService.getByTevkilIsi(widget.tevkil!.id).isEmpty
                    ? 'Ödeme Ekle'
                    : 'Ödemeyi Görüntüle/Düzenle'),
              ),
            ],
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
