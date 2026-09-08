import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../services/client_service.dart';
import '../services/payment_service.dart';
import '../utils/date_formatters.dart';
import '../utils/enum_labels.dart';
import '../utils/event_style.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/status_chip.dart';
import 'payment_form_screen.dart';

/// Tüm müvekkillerdeki ödemelerin listesi, durum filtresi ile.
class PaymentsListScreen extends StatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  State<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends State<PaymentsListScreen> {
  final _service = PaymentService();
  final _clientService = ClientService();

  PaymentStatus? _filter;
  // null: tümü, true: sadece tevkil, false: sadece kendi işlerimiz.
  bool? _tevkilFilter;
  bool _loading = true;
  bool _error = false;
  List<Payment> _payments = [];

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
        result = result.where((p) => p.effectiveStatus == _filter).toList();
      }
      if (_tevkilFilter != null) {
        result = result
            .where((p) => (p.source == PaymentSource.tevkil) == _tevkilFilter)
            .toList();
      }
      result.sort((a, b) => (a.effectiveDueDate ?? a.createdAt)
          .compareTo(b.effectiveDueDate ?? b.createdAt));
      setState(() {
        _payments = result;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ödemeler')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _filterChip(null, 'Tümü'),
                _filterChip(PaymentStatus.waiting, 'Ödenmedi'),
                _filterChip(PaymentStatus.partial, 'Kısmen Ödendi'),
                _filterChip(PaymentStatus.paid, 'Ödendi'),
                _filterChip(PaymentStatus.overdue, 'Gecikmiş'),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: Row(
              children: [
                _tevkilFilterChip(null, 'Kaynak: Tümü'),
                _tevkilFilterChip(false, 'Kendi İşim'),
                _tevkilFilterChip(true, 'Tevkil'),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _filterChip(PaymentStatus? status, String label) {
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

  Widget _tevkilFilterChip(bool? value, String label) {
    final selected = _tevkilFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _tevkilFilter = value);
          _load();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingState();
    if (_error) return ErrorState(onRetry: _load);
    if (_payments.isEmpty) {
      return const EmptyState(message: 'Henüz ödeme kaydı bulunmuyor.');
    }
    return ListView.builder(
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final p = _payments[index];
        final client = p.clientId != null ? _clientService.getById(p.clientId!) : null;
        final isTevkil = p.source == PaymentSource.tevkil;
        final payerLabel = client?.displayName ??
            p.payerName ??
            (isTevkil ? 'Tevkil ödemesi' : 'Bilinmeyen müvekkil');
        final due = p.effectiveDueDate;
        final statusText = p.hasPlan
            ? '${EnumLabels.paymentStatus(p.effectiveStatus)} · Kalan ${p.remainingAmount.toStringAsFixed(2)} ${p.currency}'
            : EnumLabels.paymentStatus(p.effectiveStatus);
        return ListTile(
          leading: Icon(isTevkil ? Icons.handshake_outlined : Icons.payments_outlined),
          title: Row(
            children: [
              Expanded(
                child: Text(
                    '${p.paymentType} · ${p.amount.toStringAsFixed(2)} ${p.currency}'),
              ),
              if (isTevkil) ...[
                const SizedBox(width: 6),
                StatusChip(
                    label: 'Tevkil', color: EventStyle.colorFor(AppEventType.tevkil)),
              ],
            ],
          ),
          subtitle: Text(
              '$payerLabel'
              '${due != null ? ' · Vade: ${DateFormatters.formatDate(due)}' : ''}'),
          isThreeLine: false,
          trailing: StatusChip(
            label: statusText,
            color: EnumLabels.paymentStatusColor(p.effectiveStatus),
          ),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PaymentFormScreen(
                clientId: p.clientId,
                caseId: p.caseId,
                payment: p,
                tevkilIsiId: p.tevkilIsiId,
              ),
            ));
            _load();
          },
        );
      },
    );
  }
}
